all:
	@echo 'Not all'

db-setup:
	sqlite3 sqlite.db < tables.txt

db-dump:
	echo '.d' | sqlite3 sqlite.db

db-drop:
	rm sqlite.db || true

db-from-scratch: db-drop db-setup
	@echo 'Done'

crontab-install:
	(crontab -l ; echo "52 * * * * /PATH/TO/WHERE/YOU/DOWNLOADED/THE/SCRIPT/craigslist.pl") | crontab -

crontab-remove:
	crontab -l | grep -v "craigslist.pl" | crontab -

