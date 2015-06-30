#!/usr/bin/perl

use warnings;
use strict;

use WWW::Mechanize;
use Email::Sender::Simple qw(sendmail);
use Time::Piece;
use Data::Dumper;

#### define variables
my $code = ''; # biblio card number
my $pin = ''; # password
my $family = 'De Malliard';
my $login_url = 'https://nelligan.ville.montreal.qc.ca/patroninfo*frc/?';
my $renew_delay = 5; # number of day before due date from wich renew should try.

#### init 
my $mech = WWW::Mechanize->new( 'ssl_opts' => { 
	HTTPS_CA_DIR => '/usr/share/ca-certificates/',
	SSL_verify_mode => 'SSL_VERIFY_PEER',
	onerror => undef
} );

#### login
$mech->get($login_url);
print "page loaded\n";

my $fields = {
	'code' => $code,
	'pin' => $pin
};
$mech->submit_form(form_number => 1, fields => $fields);
$mech->click();

if ($mech->content() =~ m/$family/ ) {
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
		$book_list{$i}{'checkbox'} = $id;
		$book_list{$i}{'value'} = $2;

		# get name
		if ( $book_array[$i] =~ /<label for="$id"><a href[^>]+>([^<]+)/ ) {
			$book_list{$i}{'name'} = $1;
		} else {
			print "$i: name: error\n";
		}

		# get barcode
		if ( $book_array[$i] =~ /class="patFuncBarcode"> ([^<]+) / ) {
			$book_list{$i}{'barcode'} = $1;
		} else {
			print "$i: barcode: error\n";
		}

		# get return date
		if ( $book_array[$i] =~ /class="patFuncStatus"> *RETOUR ([^<^ ]+)/ ) {
			$book_list{$i}{'date'} = $1;

			# get days before renew is due
			my $due = Time::Piece->strptime($book_list{$i}{'date'}, "%y-%m-%d");
			my $now = localtime;
			my $diff = $due - $now;
			my $days = int($diff->days);

			$book_list{$i}{'days'} = $days;
		} else {
			print "$i: date: error\n";
		}

		# get number of renew already done
		if ( $book_array[$i] =~ /class="patFuncRenewCount">\w+ (\d+)/ ) {
			$book_list{$i}{'renew'} = $1;
		} else {
			$book_list{$i}{'renew'} = 0;
		}

	} else {
		print "$i: error\n";
	}
}


# output results
for (my $i = 0; $i < $count; $i ++) {
	print "$book_list{$i}{checkbox}: $book_list{$i}{value} $book_list{$i}{barcode} $book_list{$i}{date} ";
	print "$book_list{$i}{renew} $book_list{$i}{name}\n";
}
print "\n";

# sent renew order if needed
$fields = { 
	'requestRenewSome' => 'OUI',
};

for (my $i = 0; $i < $count; $i ++) {
	if ($renew_delay >= $book_list{$i}{'days'}){
		$$fields{$book_list{$i}{'checkbox'}} = $book_list{$i}{'value'};
	}
}

$mech->submit_form(form_name => 'checkout_form', fields => $fields);
$mech->click();

$mech->save_content( 'result.html' );


__END__
function submitCheckout(buttonname, buttonvalue)
{
     var oHiddenID;
     oHiddenID = document.getElementById("checkoutpagecmd");

     oHiddenID.name = buttonname;
     oHiddenID.value = buttonvalue;

     document.getElementById("checkout_form").submit();
     return true;
}

<input type="checkbox" name="renew11" id="renew11" value="i4445716" />

<a href="#" onclick="return submitCheckout( 'requestRenewSome', 'requestRenewSome' )">
<img src="/screens/pat_renewmark_frc.gif" alt="Renouveler les titres sélectionnés" border="0"></a>

<form name="checkout_form" method="POST" id="checkout_form" ><input type="HIDDEN" id="checkoutpagecmd" />