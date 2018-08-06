use strict;
use warnings;

for(our $s=1; $s<=25599; $s++)
{
	our $x=sprintf("%5d", $s);
	print substr($x, 0, 3).".".substr($x, 3, 2).". |$s|\n";
}
