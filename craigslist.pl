#!/usr/bin/perl

# Email::Sender::Transport::SMTP::TLS bug
# https://bugs.launchpad.net/ubuntu/+source/sendemail/+bug/1072299

use strict;
use warnings;
use DBI;
use LWP::UserAgent;
use Mojo::DOM;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use Email::Simple::Creator;
use Try::Tiny;

my $URL = 'YOUR CUSTOM SEARCH URL';

# Something like this one
# my $URL = 'http://sfbay.craigslist.org/search/apa/sfc?query=&zoomToPosting=&minAsk=&maxAsk=2300&bedrooms=&housing_type=&nh=1&nh=4&nh=6&nh=8&nh=11&nh=12&nh=16&nh=10&nh=20&nh=24&nh=17&nh=18&nh=19&nh=21&nh=22&nh=23&nh=27&nh=156';

my $mail_transport = Email::Sender::Transport::SMTP::TLS->new(
  username => 'SENDER@EMAIL_CONFIG',
  password => 'PASSWORD_CONFIG',
  host => 'HOST_CONFIG',
  port => PORT_CONFIG,
  halo => 'HALO_CONFIG'
);

my $dbh = DBI->connect(          
    "dbi:SQLite:dbname=/PATH/TO/WHERE/YOU/DOWNLOADED/THE/SCRIPT/sqlite.db", 
    "",
    "",
    { RaiseError => 1 },
) or die $DBI::errstr;

my $sth_save = $dbh->prepare("INSERT INTO res values(?, ?, ?, ?, ?)");
my $sth_search = $dbh->prepare("SELECT id FROM res WHERE id = ?");

my $ua = LWP::UserAgent->new;
$ua->timeout(30);
$ua->agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.154.65 Safari/537.36");

my $response = $ua->get($URL);

if ($response->is_success) {
  my $dom = Mojo::DOM->new($response->content);
  my $serps = $dom->at('blockquote[id="toc_rows"]') or &warn;

  my $cl_results = $serps->find('p[class="row"]') or &warn;
  
  $cl_results->each(
    sub {
	my %parsed = parse_entry($_);
        unless (&already_seen($sth_search, $parsed{'id'})) {
          my $mail_status = &send_mail(
            'http://sfbay.craigslist.org/'.$parsed{'id'}.' - '.$parsed{'title'}.' - '.$parsed{'price'}.' - '.$parsed{'date'},
            $parsed{'price'}.$parsed{'hood'}.$parsed{'title'}
          );
	  &store($sth_save, %parsed) if ($mail_status);
        }
    });

} else {
  print $response->status_line, "\n";
}

$sth_save->finish();
$sth_search->finish();
$dbh->disconnect();

open (my $fh, '>>', '/tmp/craigcron.txt');
print $fh scalar(localtime)."\n";
close ($fh);

#-------------------------------------
# Support functions
#------------------------------------

sub warn() {
  &send_mail('Error in craigslist scraping.', '[craiglist] Error');
}

sub send_mail {
 my $message = shift;
 my $subject = shift;
 my $sth_mail_sent = shift;

 my $mail = Email::Simple->create(
   header => [
     From    => 'FROM@EMAIL_CONFIG',
     To      => 'TO@EMAIL_CONFIG',
     Subject => $subject,
   ],
   body => $message,
 );

 try {
   sendmail($mail, { transport => $mail_transport });
   return 1;
 } catch {
   return 0;
 };
}

sub parse_entry {
  my $entry = shift;
  my $pl = $entry->at('span[class="pl"]') or &warn;
  my $a = $pl->at('a') or &warn;

  my $id = $a->attrs('href');
  my $title = $a->text;
  my $date = $pl->at('span[class="date"]')->text;
  
  my $l2 = $entry->at('span[class="l2"]');
  my $price = '';
  my $hood = '';
  if ($l2) {
    my $price_dom = $l2->at('span[class="price"]');
    my $hood_dom = $l2->at('span[class="pnr"]');
    if ($price_dom) { $price = $price_dom->text; }
    if ($hood_dom and (my $small = $hood_dom->at('small'))) { $hood = $small->text; }
  }

  return (
    id => $id,
    title => $title,
    date => $date,
    hood => $hood,
    price => $price,
  );
}

sub already_seen {
  my ($sth, $id) = @_;
  $sth->execute($id);
  my $exists = $sth->fetchrow();
  return $exists;
}

sub store {
  my ($sth, %res) = @_;
  $sth->execute($res{'id'}, $res{'price'}, $res{'hood'}, $res{'date'}, $res{'title'});
}

