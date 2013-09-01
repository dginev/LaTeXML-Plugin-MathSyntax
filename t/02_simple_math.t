use strict;
use warnings;
use Scalar::Util qw/blessed/;
use List::MoreUtils qw/natatime/;
use Data::Dumper;

use LaTeXML::MathSyntax;
# Instantiate a new grammar
my $grammar = LaTeXML::MathSyntax->new(output=>'array');

use Test::More;
my @tests = (
   # 1
  'NUMBER:1:1',
   ['ltx:XMTok',{id=>1,role=>'NUMBER'},1],
   # 1 + 3
  'NUMBER:1:1 ADDOP:+:2 NUMBER:3:3',
  ['ltx:XMApp',{cat=>'term'},
    ['ltx:XMTok',{id=>2},'+'],
    ['ltx:XMTok',{id=>1,role=>'NUMBER'},1],
    ['ltx:XMTok',{id=>3,role=>'NUMBER'},3]],
  # 1 + 3 + 4 (n-ary)
  'NUMBER:1:1 ADDOP:+:2 NUMBER:3:3 ADDOP:+:4 NUMBER:4:5',
  ['ltx:XMApp',{'cat' => 'term'},
    ['ltx:XMTok',{id=>4},'+'],
    ['ltx:XMTok',{id=>1,role=>'NUMBER'},1],
    ['ltx:XMTok',{id=>3,role=>'NUMBER'},3],
    ['ltx:XMTok',{id=>5,role=>'NUMBER'},4]],
  # 1 + 3 - 4
  'NUMBER:1:1 ADDOP:+:2 NUMBER:3:3 ADDOP:-:4 NUMBER:4:5',
  ['ltx:XMApp',{'cat' => 'term'},
    ['ltx:XMTok',{id=>4},'-'],
    ['ltx:XMApp',{'cat' => 'term'},
      ['ltx:XMTok',{id=>2},'+'],
      ['ltx:XMTok',{id=>1,role=>'NUMBER'},1],
      ['ltx:XMTok',{id=>3,role=>'NUMBER'},3]],
    ['ltx:XMTok',{id=>5,role=>'NUMBER'},4]],
  # 1 + 3 - 4 = 0
  'NUMBER:1:1 ADDOP:+:2 NUMBER:3:3 ADDOP:-:4 NUMBER:4:5 EQUALS:=:6 NUMBER:0:7',
  ['ltx:XMApp',{'cat' => 'relation'},
    ['ltx:XMTok',{id=>6},'='],
    ['ltx:XMApp',{'cat' => 'term'},
      ['ltx:XMTok',{id=>4},'-'],
      ['ltx:XMApp',{'cat' => 'term'},
        ['ltx:XMTok',{id=>2},'+'],
        ['ltx:XMTok',{id=>1,role=>'NUMBER'},1],
        ['ltx:XMTok',{id=>3,role=>'NUMBER'},3]],
      ['ltx:XMTok',{id=>5,role=>'NUMBER'},4]],
    ['ltx:XMTok',{id=>7,role=>'NUMBER'},0]],
  # x^2
  # 'UNKNOWN:x:1 POSTSUPERSCRIPT:2:2',
  # ['ltx:XMApp',{'cat' => 'factor'},
  #   ['ltx:XMTok',{role=>'SUPERSCRIPTOP'}],
  #   ['ltx:XMTok',{id=>1,role=>'UNKNOWN'},'x'],
  #   ['ltx:XMTok',{id=>2,role=>'NUMBER'},'2']],
  # 2xy
  # x^2 + 2xy
  # (x+y)
  # (x+y)^2
  # x^2 + 2xy + y^2 = (x+y)^2
);

my $iterator = natatime 2, @tests;

while (my ($input,$output) = $iterator->()) {
  my $copy = $input;
  my $result = $grammar->parse('Anything',\$copy);
  is_deeply($result, $output, "Formula: $input");
}

done_testing();