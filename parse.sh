#!/bin/bash

for i in {1..451}# put the number of html pages that exist on metacritic here, at my time it was this.
do
	curl https://www.metacritic.com/game/playstation-4/the-last-of-us-part-ii/user-reviews\?sort-by\=date\&num_items\=100\&page\=$i > html/$i.html
	sleep 8
done
