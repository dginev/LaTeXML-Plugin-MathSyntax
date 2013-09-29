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
use utf8;
use Encode;

use Data::Dumper;
use List::MoreUtils qw/natatime/;
use Scalar::Util qw/blessed/;

use LaTeXML::Converter;
use LaTeXML::Util::Config;
use LaTeXML::Util::TestMath::Report;

use Test::More;
use Test::Deep qw/cmp_deeply supersetof/;
use Test::Deep::Set;
# Ugh, Test::Deep has really horrible diagnostics for sets...
{ no warnings 'redefine';
  sub Test::Deep::Set::diagnostics {'';}
  sub Test::Deep::supersetof {
    return Test::Deep::Set->new(1, "sup", @_);
  }}
binmode Test::More->builder->output, ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

use LaTeXML::Util::Test;
our @ISA = qw(Exporter);
our @EXPORT = (qw(math_tests anno_string_to_array weaken_cmml parse_TeX_math canonical_form),
  @Test::More::EXPORT);

### Test API

sub math_tests {
  my (%options) = @_;
  $ENV{MATH_PARSER} = 'LaTeXML::MathSyntax' unless defined $ENV{MATH_PARSER};
  $options{tests} = [] unless defined $options{tests};
  my $iterator = natatime 2, @{$options{tests}};
  my $report = [];
  while (my ($input,$output) = $iterator->()) {
    my $copy = $input;
    my ($array_expected,$grammar_report) = anno_string_to_array($output);
    unless ($array_expected) {
      $output=~s/\n$//g;
      my $message = "Parse to CMML: $output\n\nGrammar report: $grammar_report\n";
      push @$report, {tex=>$input,message=>$message} if $options{log};
      fail($message); next; }
    my $weakened_expected = weaken_cmml($array_expected,$options{type});
    unless ($weakened_expected) {
      my $message = "Weaken Semantics";
      push @$report, {tex=>$input,semantics=>$array_expected,message=>$message} if $options{log};
      fail($message.": $output"); next; }
    my ($xml_parse,$parse_log,$parse_status) = parse_TeX_math($input,parser=>$ENV{MATH_PARSER});
    unless ($xml_parse && ($parse_status<1)) {
      my $message = "Parsing TeX";
      push @$report, {tex=>$input,syntax=>$weakened_expected,semantics=>$array_expected,message=>$message} if $options{log};
      $parse_log = join("\n",grep {/^\t/ || /^(Warning|Error|Fatal)\:/} split(/\n/,$parse_log));
      fail($message.": $input");
      diag("$parse_log");
      next; }
    my $array_parse = xmldom_to_array($xml_parse);
    unless ($xml_parse) {
      my $message = "Convert parse to array";
      push @$report, {tex=>$input,syntax=>$weakened_expected,semantics=>$array_expected,message=>$message} if $options{log};
      fail($message.": $input"); next; }
    # Unwrap the leading math/xmath if present
    while ($array_parse && ($array_parse->[0] =~ /^ltx:X?Math$/)) {
      $array_parse = $array_parse->[2]; }
    # Obtain canonical form of the parse
    $array_parse = canonical_form($array_parse);
    # If we're given a parse forest, deal with it appropriately
    my @parse_forest = ();
    if ($array_parse && ($array_parse->[0] eq 'ltx:XMApp') && 
      (defined $array_parse->[1]->{meaning}) &&
      ($array_parse->[1]->{meaning} eq 'cdlf-set')) {
      @parse_forest = @$array_parse[3..scalar(@$array_parse)-1];
    } else {
      @parse_forest = ($array_parse); }
    # TODO: Figure out how to neatly test both syntax and semantics
    my $s = (@parse_forest > 1) ? 's' : '';
    my $success = is_syntax(\@parse_forest, $weakened_expected, "Syntax tree match (".scalar(@parse_forest)." parse$s):\n $input\n");
    if ($options{log}) {
      my $message;
      if ($success) {
        $message = 'Success.'; }
      else {
        $message = "Syntax tree match (".scalar(@parse_forest)." parse$s)"; }
      push @$report, {tex=>$input,parse=>$array_parse,
        syntax=>$weakened_expected,semantics=>$array_expected,message=>$message}
    }
  }
  math_report($options{log},$options{reference},$report) if $options{log};
  done_testing();
}

sub is_semantics {
  my ($parse_forest, $expected, $message) = @_;
  my $expected_skeleton = semantic_skeleton($expected);
  if (! $expected_skeleton) {
    fail ("Semantic skeleton for expected.\n$message");
    return; }
  my $candidate_skeletons = [map {semantic_skeleton($_)} @$parse_forest];
  if (grep {! defined} @$candidate_skeletons) {
    fail ("Semantic skeleton for input candidate.\n$message");
    return; }
  cmp_deeply(
    $candidate_skeletons,
    supersetof($expected_skeleton),
    $message); }

sub is_syntax {
  my ($parse_forest, $expected, $message) = @_;
  my $expected_skeleton = syntactic_skeleton($expected);
  if (! $expected_skeleton) {
    fail ("Syntactic skeleton for expected.\n$message");
    return; }
  my $candidate_skeletons = [map {syntactic_skeleton($_)} @$parse_forest];
  if (grep {! defined} @$candidate_skeletons) {
    fail ("Syntactic skeleton for input candidate.\n$message");
    return; }
  no warnings 'redefine';
  cmp_deeply(
    $candidate_skeletons,
    supersetof($expected_skeleton),
    #$message."\n".Dumper($candidate_skeletons).Dumper($expected_skeleton)) or exit; }
    $message); }

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
  '(' Expression Arguments ')' action => apply assoc => group

Arguments ::= 
  Expression action => wrap
  | BVar Expression action => wrap
  | Expression Arguments action => merge_right

BVar ::=
 '{' Term '}' action => bvar assoc => group
 | '{' Term Degree '}' action => bvar_degree assoc => group

Degree ::=
  '^' Expression action => degree

Term ::=
  RawTerm
  | RawTerm KeyValList action => attach_keyval

KeyValList ::=
 '[' KeyVals ']' action => unwrap assoc => group

KeyVals ::= 
  KeyVal action => wrap
  | KeyVal KeyVals action => merge_right

KeyVal ::=
  Word ':' Word action => keyval

RawTerm ::= 
  Word ':' Word ':' Word action => csymbol
  || Word ':' Word action => basic_symbol
  # Special case where the lexeme is a special char :()
  || ':' ':' Word ':' Word action => csymbol
  || ':' Word ':' Word action => nolex_csymbol

Word ~ [^\s\:\(\)\[\]\{\}\^]+
:discard ~ whitespace
whitespace ~ [\s]+

END_OF_RULES
});

### Sub convenience routines
sub anno_string_to_array {
  my ($annotation_string) = @_;
  my $recce = Marpa::R2::Scanless::R->new( { grammar => $string_to_array_grammar } );
  my $value_ref;
  eval {
    local $SIG{__DIE__} = undef;
    $recce->read( \$annotation_string );
    $value_ref = $recce->value(); 1; };
  my $value = $value_ref ? ${$value_ref} : undef;
  return ($value,$@); }

sub weaken_cmml {
  my ($cmml_array,$type) = @_;
  return $cmml_array if (!$type || ($type eq 'semantic'));
  # For now just downgrade to XMath immediately
  return weaken_cmml_to_xmath($cmml_array,$type); }

our $xmath_name = {'apply'=>'ltx:XMApp','cn'=>'ltx:XMTok','ci'=>'ltx:XMTok','csymbol'=>'ltx:XMTok'};
our $xmath_meaning = {'eq'=>'equals','unary_minus'=>'minus'};
sub weaken_cmml_to_xmath {
  my ($array,$type) = @_;
  # For now, simple renaming would do:
  return $array unless ref $array;
  my @copy = @$array;
  my $content_head = shift @copy;
  my $head = $xmath_name->{$content_head};
  my %attributes = %{shift @copy};
  $attributes{omcd} = delete $attributes{cd} if exists $attributes{cd};
  my @body;
  if ($content_head eq 'csymbol') {
    my $lexeme = delete $attributes{lexeme};
    @body = $lexeme ? ($lexeme) : ();
    $attributes{meaning} = shift @copy; }
  elsif ($content_head eq 'cn') {
    $attributes{meaning} = shift @copy;
    @body = $attributes{meaning}; }
  elsif ($content_head eq 'bvar') {
    # Syntax-land is binder unaware
    return; }
  elsif ($content_head eq 'bind') {
    return weaken_cmml_to_xmath($copy[2],$type); }
  else { # Apply case
    if (ref $copy[0] eq 'ARRAY') {
      if ($copy[0]->[0] eq 'csymbol') {
        my $meaning = $copy[0]->[2];
        if ($meaning) {
          if ($meaning eq 'nthdiff') {
            $copy[1]->[0] = 'ci';
            $copy[1]->[1]->{meaning} = $copy[1]->[2];
            $copy[1]->[2] = encode('UTF-8', '′' x $copy[1]->[2]);
            @copy = ($copy[0],$copy[2],$copy[1]); }
          elsif (($meaning eq 'sum') || ($meaning eq 'product')) {
            my $sum = $copy[0];
            my $interval = $copy[1];
            my $summand = $copy[2];
            # Rewrite the tree to have sub and super scripts
            # Notation: Grab the bound variable if we're dealing with product or sum
            #           since we have \sum_{bvar=from}^{to}
            my $bvar = $summand->[3]->[2]; # bind/bvar
            my $from = $interval->[3];
            my $to = $interval->[4];
            my $narrative_sum = $sum;
            if ($from) {
              my $from_clause = ['apply',{},['csymbol',{cd=>'relation1',lexeme=>'='},'eq'],$bvar,$from];
              $narrative_sum = ['apply',{},['csymbol',{cd=>'interval'},'from'],$sum,$from_clause]; }
            $narrative_sum = $to ? ['apply',{},['csymbol',{cd=>'interval'},'to'],$narrative_sum,$to] : $narrative_sum;
            @copy = ($narrative_sum,$summand);
          }
        }
      }
      elsif ($copy[0]->[0] eq 'apply') {
        my $bind = $copy[0]->[4];
        if ($bind && (ref $bind eq 'ARRAY') && ($bind->[0] eq 'bind')) {
          return weaken_cmml_to_xmath($copy[0],$type);
        }}
    }
    @body = grep {defined} map {weaken_cmml_to_xmath($_,$type)} @copy; }
  
  my $meaning = $attributes{meaning};
  if ($meaning && (exists $xmath_meaning->{$meaning})) {
    $attributes{meaning} = $xmath_meaning->{$meaning}; }
  return [$head, \%attributes, @body]; }

sub xmldom_to_array {
  my ($tree) = @_;
  my $class = blessed($tree);
  if ($class && ($class ne 'XML::LibXML::Text') && ($class ne 'XML::LibXML::Comment')) {
    # XML leaf, turn to array:
    my @attributelist = grep {defined} $tree->attributes();
    my $attributes = {map {$_->localname() => $_->value()} @attributelist};
    ['ltx:'.$tree->localname,$attributes,(grep {defined} map{xmldom_to_array($_)} $tree->childNodes)]; }
  else {
    (ref $tree) ? encode('UTF-8',$tree->toString) : encode('UTF-8',$tree); }}

sub semantic_skeleton {
  my ($array_ref) = @_;
  return $array_ref unless (ref $array_ref eq 'ARRAY');
  my @copy = @$array_ref;
  my $head = shift @copy;
  my $attr = shift @copy;
  # OMCD and Meaning need to match up _ONLY_
  $attr = {omcd=>$attr->{omcd},meaning=>$attr->{meaning}};
  my @body = map {semantic_skeleton($_)} @copy;
  [$head,$attr,@body]; }

our $inv_times = encode('UTF-8',"\x{2062}");
sub syntactic_skeleton {
  my ($array_ref) = @_;
  return $array_ref unless (ref $array_ref eq 'ARRAY');
  my @copy = @$array_ref;
  my $head = shift @copy;
  my $attr = shift @copy;
  # No attributes need match up, as long as the tree corresponds
  my @body = map {syntactic_skeleton($_)} @copy;
  if ($attr->{meaning} && ($attr->{meaning} eq 'times')) {
    @body = grep {(ref $_) || ($_ ne $inv_times)} @body; }
  [$head,{},@body]; }

sub canonical_form {
  my ($array_ref) = @_;
  return $array_ref unless (ref $array_ref eq 'ARRAY');
  my @copy = @$array_ref;
  my $head = shift @copy;
  my $attr = shift @copy;
  # No attributes need match up, as long as the tree corresponds
  my @body = map {canonical_form($_)} @copy;
  if (($head eq 'ltx:XMApp') && 
    ($body[0]->[1]->{role}) && ($body[0]->[1]->{role} eq 'SUBSCRIPTOP') && 
    ($body[1]->[0] eq 'ltx:XMApp') &&
    $body[1]->[2]->[1]->{role} && (($body[1]->[2]->[1]->{role} eq 'SUPERSCRIPTOP'))) {
    # rotate the scripts
    my $super = $body[1]; 
    my $base = $super->[3];
    my $sub = [$head,$attr,$body[0],$base,$body[2]];
    $super->[3] = $sub;
    return $super;
  }
  [$head,$attr,@body]; }


### Semantics
sub CMML_Semantics::new {return {}; }

sub CMML_Semantics::apply {
  my (undef, $open, $expr, $arguments, $close ) = @_;
  if ($expr->[0] eq 'csymbol') {
    my $qualified_name = $expr->[1]->{cd}.':'.$expr->[2];
    if ($qualified_name =~ /^(
      ((quant1|logic1)\:(forall|exists))
      | (fns1\:lambda)
      )$/x)
    { return ['bind',{},$expr,@$arguments]; }}
  return ['apply',{},$expr,@$arguments]; }

sub CMML_Semantics::merge_right {
  my (undef, $expr, $arguments ) = @_;
  (! defined $arguments) ? [$expr] :
    (ref $arguments) ? [$expr,@$arguments] :
      [$expr,$arguments]; }

sub CMML_Semantics::wrap {
  my (undef, @args ) = @_;
  [@args]; }


sub CMML_Semantics::csymbol {
  my (undef, $lexeme, $colon1, $cd, $colon2, $meaning) = @_;
  ['csymbol',{cd=>$cd,lexeme=>$lexeme},$meaning]; }

sub CMML_Semantics::nolex_csymbol {
  my (undef, $colon1, $cd, $colon2, $meaning) = @_;
  ['csymbol',{cd=>$cd},$meaning]; }

sub CMML_Semantics::basic_symbol {
  my (undef, $lexeme, $colon, $meaning) = @_;
  [$meaning,{},$lexeme]; }

sub CMML_Semantics::keyval {
  my (undef,$key,$separator,$value)=@_;
  [$key,$value]; }

sub CMML_Semantics::unwrap {
  my (undef,$open,$arg,$close)=@_;
  $arg; }

sub CMML_Semantics::degree {
  my (undef,$op,$degree_term)=@_;
  ['degree',{},$degree_term]; }

sub CMML_Semantics::bvar {
  my (undef,$open,$bvar_term,$close)=@_;
  ['bvar',{},$bvar_term]; }

sub CMML_Semantics::bvar_degree {
  my (undef,$open,$bvar_term,$degree,$close)=@_;
  ['bvar',{},$bvar_term,$degree]; }

sub CMML_Semantics::attach_keyval {
  my (undef,$term,$keyvals) = @_;
  my $attr = $term->[1];
  foreach my $keyval(@$keyvals) {
    $attr->{$keyval->[0]} = $keyval->[1];
  }
  $term; }

### Input manipulation

sub parse_TeX_math {
  my ($tex_math,%options) = @_;
  $options{parser} //= 'LaTeXML::MathSyntax';
  my $opts = LaTeXML::Util::Config->new(
    input_limit=>100,
    whatsin=>'math',
    whatsout=>'math',
    post=>0,
    verbosity=>1,
    mathparse=>$options{parser},
    defaultresources => 0,
    format=>'dom',
    inputencoding=>'UTF-8',
    preload=>[
      'LaTeX.pool',
      'article.cls',
      'amsmath.sty',
      'amsthm.sty',
      'amstext.sty',
      'amssymb.sty',
      'eucal.sty',
      '[dvipsnames]xcolor.sty']);
  my $latexml = LaTeXML::Converter->get_converter($opts);
  $latexml->prepare_session($opts);
  # Digest and convert to LaTeXML's XML
  my $response = $latexml->convert($tex_math); 
  return ($response->{result},$response->{log},$response->{status_code}); }

1;