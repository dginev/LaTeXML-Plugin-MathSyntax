use strict;
use warnings;
use Scalar::Util qw/blessed/;
use List::MoreUtils qw/natatime/;
use Data::Dumper;

use LaTeXML::MathSyntax;
# Instantiate a new grammar
my $grammar = LaTeXML::MathSyntax->new(output=>'array');

use Test::More tests => 3;
my @examples = (
  'NUMBER:1:1',
   ['ltx:XMTok',{id=>1,role=>'NUMBER'},1],
  
  'NUMBER:1:1 ADDOP:+:2 NUMBER:3:3',
  ['ltx:XMApp',{cat=>'term'},
    ['ltx:XMTok',{id=>2},'+'],
    ['ltx:XMTok',{id=>1,role=>'NUMBER'},1],
    ['ltx:XMTok',{id=>3,role=>'NUMBER'},3]],
  
  'NUMBER:1:1 ADDOP:+:2 NUMBER:3:3 ADDOP:+:4 NUMBER:4:5',
  ['ltx:XMApp',{'cat' => 'term'},
    ['ltx:XMTok',{id=>4},'+'],
    ['ltx:XMTok',{id=>1,role=>'NUMBER'},1],
    ['ltx:XMTok',{id=>3,role=>'NUMBER'},3],
    ['ltx:XMTok',{id=>5,role=>'NUMBER'},4]]
);

my $iterator = natatime 2, @examples;

while (my ($input,$output) = $iterator->()) {
  my $copy = $input;
  my $result = $grammar->parse('Anything',\$copy);
  is_deeply($result, $output, "Formula: $input");
}