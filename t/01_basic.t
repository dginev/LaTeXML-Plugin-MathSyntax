use strict;
use warnings;
use Scalar::Util qw/blessed/;

use Test::More tests => 2;

my $eval_return = eval {
  use LaTeXML;
  use LaTeXML::MathParser;
  use LaTeXML::MathSyntax;
  1;
};

ok($eval_return && !$@, 'LaTeXML and MathSyntax Modules Loaded successfully.');

# Instantiate a new grammar
my $grammar = LaTeXML::MathSyntax->new();
is(blessed($grammar),'LaTeXML::MathSyntax');