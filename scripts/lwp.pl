use strict;
use warnings;
use LWP::Simple;
use LWP::UserAgent;
use WWW::Mechanize;
use HTTP::Tiny;
use Net::SNMP;


use Net::SNMP qw(:snmp);
 
my $OID_ifTable = '1.3.6.1.2.1.2.2';
my $OID_ifPhysAddress = '1.3.6.1.2.1.2.2.1.6';
 
my ($session, $error) = Net::SNMP->session(
   -hostname    => shift || '169.198.12.49',
   -community   => shift || 'public',
   -nonblocking => 1,
   -translate   => [-octetstring => 0],
   -version     => 'snmpv2c',
);
 
if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}
 
my %table; # Hash to store the results
 
my $result = $session->get_bulk_request(
   -varbindlist    => [ $OID_ifTable ],
   -callback       => [ \&table_callback, \%table ],
   -maxrepetitions => 10,
);
 
if (!defined $result) {
   printf "ERROR: %s\n", $session->error();
   $session->close();
   exit 1;
}
 
# Now initiate the SNMP message exchange.
 
snmp_dispatcher();
 
$session->close();
 
# Print the results, specifically formatting ifPhysAddress.
 
for my $oid (oid_lex_sort(keys %table)) {
   if (!oid_base_match($OID_ifPhysAddress, $oid)) {
      printf "%s = %s\n", $oid, $table{$oid};
   } else {
      printf "%s = %s\n", $oid, unpack 'H*', $table{$oid};
   }
}
 
exit 0;
 
sub table_callback
{
   my ($session, $table) = @_;
 
   my $list = $session->var_bind_list();
 
   if (!defined $list) {
      printf "ERROR: %s\n", $session->error();
      return;
   }
 
   # Loop through each of the OIDs in the response and assign
   # the key/value pairs to the reference that was passed with
   # the callback.  Make sure that we are still in the table
   # before assigning the key/values.
 
   my @names = $session->var_bind_names();
   my $next  = undef;
 
   while (@names) {
      $next = shift @names;
      if (!oid_base_match($OID_ifTable, $next)) {
         return; # Table is done.
      }
      $table->{$next} = $list->{$next};
   }
 
   # Table is not done, send another request, starting at the last
   # OBJECT IDENTIFIER in the response.  No need to include the
   # calback argument, the same callback that was specified for the
   # original request will be used.
 
   my $result = $session->get_bulk_request(
      -varbindlist    => [ $next ],
      -maxrepetitions => 10,
   );
 
   if (!defined $result) {
      printf "ERROR: %s.\n", $session->error();
   }
 
   return;
}

exit 0;
 
our $sites=<<SITES;
169.198.72.191
169.198.48.100
169.198.40.19
#169.198.1.12
169.198.78.29
#74.125.21.139
SITES

our $www = WWW::Mechanize->new();
$www->agent_alias('Windows Mozilla');

my $lwp = LWP::UserAgent->new;
$lwp->timeout(10);
$lwp->agent('Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36');
#$ua->agent('Checkbot/0.4 ');    # append the default to the end
#$ua->agent('Mozilla/5.0');
#$lwp->agent(""); 
$lwp->protocols_allowed(['http', 'https']);
$lwp->cookie_jar({});

our @sites=split("\n", $sites);

foreach my $site(@sites)
{
	next if substr($site, 0, 1) eq "#";
	
	#print "Tyring LWP on $site\n\n";
	
	my $request = new HTTP::Request("GET", "http://$site");
	my $response = $lwp->request($request);
	 
	my $code=$response->code;
	my $desc = HTTP::Status::status_message($code);
	my $headers=$response->headers_as_string;
	my $body =  $response->content;
	 
	print "|$site|$code|$desc|\n";
	
	my $r = getstore("http://$site", '/dev/null');
	print "|$site|$r||\n";
	
	#print "$headers\n";
	#print "$body\n";
	$response = HTTP::Tiny->new(agent=>"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36")->get("http://$site");
	print "|$site|$response->{status}|$response->{reason}|\n" if $response->{status} != 599;
	printf("|$site|%s|%s|\n", $response->{status}, $response->{content}) if $response->{status} == 599;
		
	my $www = WWW::Mechanize->new(onerror=>undef);
	$www->get("http://$site");
	#$browser->form_name('f');
	#$browser->field('q','langley public library');
	#$browser->submit();
	printf("|$site|%s|%s|\n", $www->response->code, $www->response->message);
	
	
}

exit 0;




print $lwp->get('http://www.google.ca/search?hl=en&q=langley+public+library+&meta=')->content();



#my $content = get("www.google.com");
#print "failed\n" if !$content;
#print "$content";