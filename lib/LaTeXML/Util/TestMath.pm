# ::====================================================================\ #
# | LaTeXML::Util::TestMath                                             | #
# | Testing utilities for parsing math expressions                      | #
# |=====================================================================| #
# | NOT Part of LaTeXML:                                                | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Deyan Ginev <deyan.ginev@nist.gov>                          #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

package LaTeXML::Util::TestMath;
use strict;
use warnings;
use Data::Dumper;

use LaTeXML::Converter;
use LaTeXML::Util::Config;

use Test::More;
use LaTeXML::Util::Test;
our @ISA = qw(Exporter);
our @EXPORT = (qw(anno_string_to_array
  weaken_cmml_array cmml_to_xmath_array
  parse_TeX),
  @Test::More::EXPORT);

### Output/annotation manipulation
# Marpa::R2 grammar converting an annotation string into a Perl array
use Marpa::R2;
my $string_to_array_grammar =
  Marpa::R2::Scanless::G->new({
    action_object  => 'CMML_Semantics',
    default_action => '::first',
    source => \(<<'END_OF_RULES'),
:start ::= Expression

Expression ::=
  Application
  | Term

Application ::=
  '@' '(' Expression Arguments')' action => apply

Arguments ::= 
  Expression action => merge
  | Expression Arguments action => merge
  
Term ::= 
  Word ':' Word ':' Word action => csymbol
  || Word ':' Word action => basic_symbol
  # Special case where the lexeme is a special char @:()
  || ':' ':' Word ':' Word action => csymbol
  | '@' ':' Word ':' Word action => csymbol
  | '(' ':' Word ':' Word action => csymbol
  | ')' ':' Word ':' Word action => csymbol

Word ~ [^\s:@\(\)]+
:discard ~ whitespace
whitespace ~ [\s]+

END_OF_RULES
});

sub anno_string_to_array {
  my ($annotation_string) = @_;
  my $recce = Marpa::R2::Scanless::R->new( { grammar => $string_to_array_grammar } );
  $recce->read( \$annotation_string );
  my $value_ref = $recce->value;
  my $value = $value_ref ? ${$value_ref} : 'No Parse';
  # print STDERR Dumper($value);
  return $value; }

sub weaken_cmml_array {
  #TODO
}

### Semantics
sub CMML_Semantics::new {return {}; }

sub CMML_Semantics::apply {
  my (undef, $at, $open, $expr, $arguments, $close ) = @_;
  return ['apply',{},$expr,@$arguments]; }

sub CMML_Semantics::merge {
  my (undef, $expr, $arguments ) = @_;
  (! defined $arguments) ? [$expr] :
    (ref $arguments) ? [$expr,@$arguments] :
      [$expr,$arguments]; }

sub CMML_Semantics::csymbol {
  my (undef, $lexeme, $colon1, $cd, $colon2, $meaning) = @_;
  ['csymbol',{cd=>$cd,lexeme=>$lexeme},$meaning]; }

sub CMML_Semantics::basic_symbol {
  my (undef, $lexeme, $colon, $meaning) = @_;
  [$meaning,{},$lexeme]; }


### Input manipulation

sub parse_TeX {
  my ($tex_math,$parser) = @_;
  $parser //= 'LaTeXML::MathSyntax';
  my $opts = LaTeXML::Util::Config->new(
    input_limit=>100,
    whatsin=>'math',
    whatsout=>'math',
    post=>0,
    verbosity=>2,
    mathparse=>$parser,
    defaultresources => 0,
    format=>'dom',
    preload=>[
      'LaTeX.pool','amsmath.sty',
      'amsthm.sty',
      'amstext.sty',
      'amssymb.sty',
      'eucal.sty',
      '[dvipsnames]xcolor.sty',]);
  my $latexml = LaTeXML::Converter->get_converter($opts);
  $latexml->prepare_session($opts);
  # Digest and convert to LaTeXML's XML
  my $response = $latexml->convert($tex_math);
  my $xmath = $response->{result};
  print $xmath->toString(1);
  return $xmath;
}

1;