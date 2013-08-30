use strict;
use warnings;

use Test::More tests => 1;

my $eval_return = eval {
  use LaTeXML;
  use LaTeXML::MathParser;
  use LaTeXML::MathSyntax;
  1;
};

ok($eval_return && !$@, 'LaTeXML and MathSyntax Modules Loaded successfully.');

# Instantiate a new grammar