craighouse
==========

Script to scrape craigslist for housing classifieds in the sfbay area and send email alerts.

You should really use https://ifttt.com/, this script exists only because when I was looking for a place in SF ifttt stopped working for a couple of days and I needed an alternative.

You must configure this

```
$ grep -n CONFIG . -R
./craigslist.pl:22:  username => 'SENDER@EMAIL_CONFIG',
./craigslist.pl:23:  password => 'PASSWORD_CONFIG',
./craigslist.pl:24:  host => 'HOST_CONFIG',
./craigslist.pl:25:  port => PORT_CONFIG,
./craigslist.pl:26:  halo => 'HALO_CONFIG'
./craigslist.pl:90:     From    => 'FROM@EMAIL_CONFIG',
./craigslist.pl:91:     To      => 'TO@EMAIL_CONFIG',
```

and this

```
$ grep -n PATH . -R
./craigslist.pl:30:    "dbi:SQLite:dbname=/PATH/TO/WHERE/YOU/DOWNLOADED/THE/SCRIPT/sqlite.db",
./Makefile:17:	       (crontab -l ; echo "52 * * * * /PATH/TO/WHERE/YOU/DOWNLOADED/THE/SCRIPT/craigslist.pl") | crontab -
```

and have a look at the script itself and Makefile before using it.
