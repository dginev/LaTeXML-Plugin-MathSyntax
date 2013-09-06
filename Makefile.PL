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

WriteMakefile(
  NAME => 'LaTeXML::MathSyntax',
  AUTHOR => 'Deyan Ginev <d.ginev@jacobs-university.de>',
  ABSTRACT => "A new approach to parsing mathematical expressions for LaTeXML",
  VERSION_FROM => 'lib/LaTeXML/MathSyntax.pm',
  PREREQ_PM => { 
    'LaTeXML'=>0,
    'Marpa::R2'=>0,
    'SVG::Graph'=>0,
    'Test::Deep'=>0,
    'List::MoreUtils'=>0,
    'HTML::Entities'=>0
  },
);

