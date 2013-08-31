use strict;
use warnings;
use Scalar::Util qw/blessed/;
use Data::Dumper;

use LaTeXML::MathSyntax;
# Instantiate a new grammar
my $grammar = LaTeXML::MathSyntax->new();
# TODO: Design LaTeXML-independent testing that works on string inputs,
#       not attached to an XML document. Or auto-generate the XML snippet for them
my $examples = [
	'NUMBER:1:1',
	# 'NUMBER:1:1 ADDOP:+:2 NUMBER:3:3',
	# 'NUMBER:1:1 ADDOP:+:2 NUMBER:3:3 ADDOP:+:4 NUMBER:4:5'
];

use Test::More tests => 1;

foreach my $example (@$examples) {
	my $result = $grammar->parse('Anything',\$example);
	ok($result);
}