#!/usr/bin/perl

use warnings;
use strict;

use WWW::Mechanize;
use Time::Piece;
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Data::Dumper;

#### load config
my $config=do("config.pl");

#### init 
my $mech = WWW::Mechanize->new( 'ssl_opts' => { 
	HTTPS_CA_DIR => '/usr/share/ca-certificates/',
	SSL_verify_mode => 'SSL_VERIFY_PEER',
	onerror => undef
} );

#### login
$mech->get($$config{login_url});
print "page loaded\n";

my $fields = {
	'code' => $$config{code},
	'pin' => $$config{pin}
};
$mech->submit_form(form_number => 1, fields => $fields);

if ($mech->content() =~ m/$$config{family}/ ) {
	print "Login: successful\n";
} else {
	print "Login: failed\n";
} 

#### parse books
my @book_array = $mech->content() =~ /<tr class="patFuncEntry">(.+?)<\/tr>/gs;
my $count = $#book_array;
print "Found $count books\n";

my %book_list;
for (my $i = 0; $i < $count; $i ++) {
	# get checkbox, and is its id as id for all reference to current book
	if ( $book_array[$i] =~ /<input type="checkbox" name="(\w+)" id="\w+" value="(\w+)"/ ) {
		my $id = $1;
		$book_list{$i}{checkbox} = $id;
		$book_list{$i}{value} = $2;

		# get name
		if ( $book_array[$i] =~ /<label for="$id"><a href[^>]+>([^<]+)/ ) {
			$book_list{$i}{name} = $1;
		} else {
			print "$i: name: error\n";
		}

		# get barcode
		if ( $book_array[$i] =~ /class="patFuncBarcode"> ([^<]+) / ) {
			$book_list{$i}{barcode} = $1;
		} else {
			print "$i: barcode: error\n";
		}

		# get return date
		if ( $book_array[$i] =~ /class="patFuncStatus"> *RETOUR ([^<^ ]+)/ ) {
			$book_list{$i}{date} = $1;

			# get days before renew is due
			my $due = Time::Piece->strptime($book_list{$i}{date}, "%y-%m-%d");
			my $now = localtime;
			my $diff = $due - $now;
			my $days = int($diff->days);

			$book_list{$i}{days} = $days;
		} else {
			print "$i: date: error\n";
		}

		# get number of renew already done
		if ( $book_array[$i] =~ /class="patFuncRenewCount">\w+ (\d+)/ ) {
			$book_list{$i}{renew} = $1;
		} else {
			$book_list{$i}{renew} = 0;
		}

	} else {
		print "$i: error\n";
	}
}


### output results
# for (my $i = 0; $i < $count; $i ++) {
# 	print "$book_list{$i}{checkbox}: $book_list{$i}{value} $book_list{$i}{barcode} $book_list{$i}{date} ";
# 	print "$book_list{$i}{renew} $book_list{$i}{name}\n";
# }
# print "\n";


### sent renew order if needed
my $renew = 0;
$fields = { 
	'requestRenewSome' => 'OUI',
};

my $email_str = '';
for (my $i = 0; $i < $count; $i ++) {
	if ($$config{renew_days} >= $book_list{$i}{days}){
		$renew = 1;
		$$fields{$book_list{$i}{checkbox}} = $book_list{$i}{value};
		$email_str .= $book_list{$i}{name} . "\n";

		print "$book_list{$i}{checkbox}: $book_list{$i}{value} $book_list{$i}{barcode} $book_list{$i}{date} ";
		print "$book_list{$i}{renew} $book_list{$i}{name}\n";
	}
}

if ($renew == 1) {
	$mech->submit_form(form_name => 'checkout_form', fields => $fields);

	courriel($email_str, $$config{email_from}, $$config{email_to});
}


sub courriel {
	my $str = shift;
	my $from = shift;
	my $to = shift;

	#perpare email
	my $message = Email::MIME->create(
		header_str => [
			From    => $from,
			To      => $to,
			Subject => "Biblio: books renewed",
		],
		attributes => {
			encoding => 'quoted-printable',
			charset  => 'UTF-8',
		},
		body_str => "Books just renewed:\n$str\n",
	);

	# send the message
	sendmail($message);
}