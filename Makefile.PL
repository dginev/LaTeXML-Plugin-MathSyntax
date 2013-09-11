#======================================================================
# Makefile Maker for LaTeXML::MathSyntax
# d.ginev@jacobs-university.de
#======================================================================
use ExtUtils::MakeMaker;
use strict;
use warnings;

use FindBin;

#======================================================================
# Use "perl Makefile.PL <options>"
#======================================================================
our @EXCLUSIONS=();
our $MORE_MACROS = {};
our $MORE_MAKERULES=''; 

test_targets();

WriteMakefile(
  NAME => 'LaTeXML::MathSyntax',
  AUTHOR => 'Deyan Ginev <d.ginev@jacobs-university.de>',
  ABSTRACT => "A new approach to parsing mathematical expressions for LaTeXML",
  VERSION_FROM => 'lib/LaTeXML/MathSyntax.pm',
  PREREQ_PM => { 
    'LaTeXML'=>0,
    'Marpa::R2'=>0,
    'Test::Deep'=>0,
    'List::MoreUtils'=>0,
    'HTML::Entities'=>0,
    'Graph::Easy'=>0,
    'Graph::Easy::As_svg'=>0
  });

# Append any additional Makefile rules added by the following.
sub MY::postamble {
  shift->MY::SUPER::postamble(@_) . $MORE_MAKERULES; }

sub test_targets {
  $MORE_MAKERULES .= <<'ExtraTests';

test_classic : export MATH_PARSER=RecDescent
test_classic : test

test_marpa : export MATH_PARSER=LaTeXML::MathSyntax
test_marpa : test

# TODO
test_all : export MATH_PARSER=all
test_all : test


ExtraTests
}