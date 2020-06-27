# metacritic_tlou2
A web scraping and data analysis microproject

How to get my data
1. Download this repository
2. Browse metacritic_tlou2_user_reviews_20200626.csv with Excel, enjoy, you're done.
3. (2bis.) Setup a postgresql database and import the dump metacritic_tlou2_user_reviews_20200626.sql

How to get your data
1. Find a linux system, make a postgresql database named metacritic_tlou2
2. Make a new directory and inside this latter another named 'html'.
2. Open a bash session in this 'root' directory
3. Run parse.sh - it downloads all raw html about The last of us partII user reviews locally. (Did not want to mess with python and user agent at that time, mb)
3. Run the python script metam.py
4. If you want also user history : run metam2.py
5. Fiddle with the sql requests in project.sql, or do whatever you want, you're free.
