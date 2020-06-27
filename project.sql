--Setting up database
--------------------------------------------------------------------------------------
-- Deduplicating user reviews on user_review_id (duplication happened during scraping,
-- html pages "overlap" by being updated in our runtime)
DELETE FROM user_review a USING (
      SELECT MIN(ctid) as ctid, user_review_id
        FROM user_review
        GROUP BY user_review_id HAVING COUNT(*) > 1
      ) b
      WHERE a.user_review_id = b.user_review_id
      AND a.ctid <> b.ctid

metacritic_tlou2=# alter table user_review add column trat smallint;
ALTER TABLE
metacritic_tlou2=# alter table user_review add column trev smallint;
ALTER TABLE

metacritic_tlou2=# update user_review
set trat=cte.trat, trev=cte.trev
from (select name, trat, trev from userbase) as cte
where user_review.name=cte.name;
UPDATE 34630

metacritic_tlou2=# \d user_review
                     Table « public.user_review »
    Colonne     |   Type   | Collationnement | NULL-able | Par défaut
----------------+----------+-----------------+-----------+------------
 index          | bigint   |                 |           |
 user_review_id | text     |                 |           |
 name_href      | text     |                 |           |
 name           | text     |                 |           |
 review_date    | text     |                 |           |
 note           | text     |                 |           |
 review         | text     |                 |           |
 ups            | text     |                 |           |
 thumbs         | text     |                 |           |
 language       | text     |                 |           |
 trat           | smallint |                 |           |
 trev           | smallint |                 |           |
Index :
--------------------------------------------------------------------------------------

--Mega dumb language detection
alter table user_review add column language text;
--not-english
update user_review set language='non-english'
where user_review_id in
(select user_review_id from user_review
where
review like '%una %' or --spanish - portuguese
review like '% pero %' or
review like '%juego%' or
review like '% todos %' or
review like '% ser %' or
review like '%historia%' or
review like '%г%' or -- russian
review like '%и%' or
review like '%л%' or
review like '%ы%' or
review like '% spel %' or -- dutch
review like '% spiel %' or -- german
review like '% mit %' or
review like '% jeu %' or -- french
review like '%比%' or-- chinese
review like '%有%' or
review like '%이%' or
review like '%ن%' -- arabic
);



-- Main statistic queries
--------------------------------------------------------------------------------------
select count(*) from user_review;

-- Main note
metacritic_tlou2=# select round(avg(cast(note as smallint)), 2) from user_review;
-- round
-- -------
-- 4.18
-- (1 ligne)


-- Number of reviews per note
with cte as (select cast(note as smallint) as note from user_review)
select note, count(note) from cte group by note order by note;
-- note | count
-- ------+-------
--    0 | 11928
--    1 |  4161
--    2 |  2146
--    3 |  1684
--    4 |  1104
--    5 |   700
--    6 |   399
--    7 |   380
--    8 |   815
--    9 |  1628
--   10 |  9702
-- (11 lignes)

-- Number of reviews per note bracket
with cte as (select cast(note as smallint) from user_review)
select case when note between 0 and 4 then 'negative' when note between 5 and 7 then 'mixed' else 'positive' end, count(note) from cte group by
case when note between 0 and 4 then 'negative' when note between 5 and 7
then 'mixed' else 'positive' end;
--    case   | count
-- ----------+-------
--  negative | 21023
--  mixed    |  1479
--  positive | 12145
-- (3 lignes)

-- Number of reviews per note and per day
with cte as (select review_date, cast(note as smallint) as note from user_review)
select review_date, note, count(note) from cte
group by review_date, note
order by review_date, note;

-- Average note and standard deviance per user-history group
with cte as (select cast(note as smallint), trat from user_review)
select case when trat between 0 and 1 then 'A- newcomers - bots' when trat between 2 and 50 then 'B- beginners (2-50 ratings)' else 'C- confirmed (50+ ratings)' end as user_aura,
round(avg(note), 2) as average_note, round(stddev(note),2) as std_dev from cte group by
case when trat between 0 and 1 then 'A- newcomers - bots' when trat between 2 and 50 then 'B- beginners (2-50 ratings)' else 'C- confirmed (50+ ratings)' end
order by user_aura;

    -- Number of reviews by note and user-history group
with cte as (select cast(note as smallint), trat from user_review)
select note, case when trat between 0 and 1 then 'A- newcomers - bots' when trat between 2 and 50 then 'B- beginners (2-50 ratings)' else 'C- confirmed (50+ ratings)' end as user_aura,
count(note) from cte group by note,
case when trat between 0 and 1 then 'A- newcomers - bots' when trat between 2 and 50 then 'B- beginners (2-50 ratings)' else 'C- confirmed (50+ ratings)' end
order by note, user_aura;

-- Number of reviews per note, date and per user-history group
--'A- newcomers - bots'
with cte as (select review_date, trat, cast(note as smallint), trat from user_review
    where trat in(0,1))
select review_date, note,
count(note) from cte
group by note, review_date
order by review_date, note;

--'B- beginners (2-50 ratings)'
with cte as (select review_date, cast(note as smallint), trat from user_review
    where trat>=2 and trat<=50)
select review_date, note,
count(note) from cte group by note, review_date
order by review_date, note;

--C- confirmed (50+ ratings)
with cte as (select review_date, cast(note as smallint), trat from user_review
    where trat>=50)
select review_date, note,
count(note) from cte group by note, review_date
order by review_date, note;

-- Vocabulary statistics per note bracket
--negative
with cte as (
    select unnest(tsvector_to_array(to_tsvector('english', review))) as word
    from user_review
    where cast(note as smallint)<5 and language is null)
select count(word), word from cte group by word order by count(word) desc limit 50;
--mixed
with cte as (
    select unnest(tsvector_to_array(to_tsvector('english', review))) as word
    from user_review
    where cast(note as smallint) between 5 and 7 and language is null)
select count(word), word from cte group by word order by count(word) desc limit 50;
--positive
with cte as (
    select unnest(tsvector_to_array(to_tsvector('english', review))) as word
    from user_review
    where cast(note as smallint)>7 and language is null)
select count(word), word from cte group by word order by count(word) desc limit 50;

-- Duplicate reviews
select count(review) as nb, cast(note as smallint), review from user_review group by review, note having count(review)>1 order by note, nb desc ;

--Number of posts discussing politics per note and date
with cte as (select user_review_id, name, cast(note as smallint), review_date,
tsvector_to_array(to_tsvector('english', review)) &&
tsvector_to_array(to_tsvector('propaganda agenda sjw ideology politic pandering message')) as anti_sjw,
to_tsvector('english', review), review from user_review)
select review_date, note, count(note) from cte where anti_sjw=true
group by review_date, note, anti_sjw;

metacritic_tlou2=# select note, tsvector_to_array(to_tsvector('english', review)) &&
tsvector_to_array(to_tsvector('sjw')), review from user_review where tsvector_to_array(to_tsvector('english', review)) &&
tsvector_to_array(to_tsvector('sjw'))=true;

-- Number of thumbed-up posts (>50 votes, >70% thumbed) per note bracket
with cte as (
    select
        case when cast(note as smallint) between 0 and 4 then 'negative'
            when cast(note as smallint) between 5 and 7 then 'mixed' else 'positive' end as note_bracket
        , cast(thumbs as smallint), cast(ups as smallint)
    from user_review)
select
    note_bracket,
    count(thumbs)
from cte
where thumbs>50 and cast(ups as decimal(7,2))/cast(thumbs as decimal(7,2))>0.7
group by note_bracket;
