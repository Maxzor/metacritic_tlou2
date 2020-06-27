from bs4 import BeautifulSoup
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('postgresql://postgres:postgrespwd@localhost:5432/metacritic_tlou2')
data=[]

#Parse each html page, previously downloaded to local disk.
for i in range(1,452): #put the number of html files here
    with open('html3/'+str(i)+'.html', 'r') as file:
        page = file.read()
#   Soupify the current page (html parsing)
    soup = BeautifulSoup(page, features="lxml")

#   Gather data points from the various html elements, using mostly css selectors.
    x=soup.select("[class~=user_review]")
    for i in range(0,len(x)):
        user_review_id=x[i]['id'].replace('user_review_','')
        # print('user_review_id: ' + user_review_id)

        y=x[i]('div', attrs={'class' : 'name'})
        name_href=y[0].find('a')['href']
        name=y[0].find('a').contents[0]
        # print('name: ' + name)

        date=x[i]('div', attrs={'class' : 'date'})[0].text
        # print('date: ' + date)

        note=x[i]('div', attrs={'class' : 'metascore_w'})[0].text
        # print('note: ' + note)

        y=x[i].select("[class~=review_body]")[0]
        blurb=y.select("[class~=blurb_expanded]")
#       Some reviews are in short form...
        if len(blurb)==0:
            review=x[i].find('span').text.replace('\t','')
#       ... others walls of text.
        else:
            review=blurb[0].text.strip().replace('\t','')
        # print('review: ' + review)

        ups=x[i]('span', attrs={'class' : 'total_ups'})[0].text
        thumbs=x[i]('span', attrs={'class' : 'total_thumbs'})[0].text
        # print('ups/thumbs: ' + ups + '/' + thumbs + '\n\n')

        data.append([user_review_id, name_href, name, date, note, review, ups, thumbs])

# Make the pandas dataframe and load to postgres
df = pd.DataFrame(data, columns = ['user_review_id', 'name_href', 'name', 'review_date', 'note', 'review', 'ups', 'thumbs'])
df.to_sql('user_review', engine)
print(len(data))
print('... reviews loaded.')
