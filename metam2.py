import requests
from bs4 import BeautifulSoup
import pandas as pd
from sqlalchemy import create_engine
from time import sleep
import time

engine = create_engine('postgresql://postgres:postgrespwd@localhost:5432/metacritic_tlou2')
data=[]
counter=1

#Get list of users from db
df = pd.read_sql_query('select distinct name from user_review',con=engine)
user_list=df.values.tolist()
for user in user_list:
    sleep(1/100000)
    # Thank you https://dev.to/hhsm95/using-user-agent-to-scraping-data-lli
    # Windows 10 with Google Chrome
    user_agent_desktop = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '\
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 '\
    'Safari/537.36'

    headers = { 'User-Agent': user_agent_desktop}

    url_metacritic = 'https://www.metacritic.com/user/' + user[0]
    resp = requests.get(url_metacritic, headers=headers)  # Send request
    code = resp.status_code  # HTTP response code

    while code != 200:
        print(f'Error to load metacritic: {code}')
        resp = requests.get(url_metacritic, headers=headers)  # Send request
        code = resp.status_code  # HTTP response code


    soup = BeautifulSoup(resp.text, 'lxml')  # Parsing the HTML

    total_ratings_container=soup('span', attrs={'class' : 'total_summary_ratings'})
    trat=total_ratings_container[0]('span', attrs={'class' : 'data'})[0].text
    # print(trat)
    total_reviews_container=soup('span', attrs={'class' : 'total_summary_reviews'})
    trev=total_reviews_container[0]('span', attrs={'class' : 'data'})[0].text
    # print(trev)
    print(str(counter) + ' ' + str(time.ctime()) + ' ' + user[0] + ' ' + str(trat) + ' ' + str(trev))
    data.append([user, trat, trev])
    counter +=1

# Make the pandas dataframe and load to postgres
df = pd.DataFrame(data, columns = ['username', 'rating_nb', 'review_nb'])
df.to_sql('user', engine)
print(len(data))
print('... users loaded.')
