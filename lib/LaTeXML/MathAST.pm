package LaTeXML::MathAST;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use Data::Dumper;
# Startup actions: import the constructors
{ BEGIN{ use LaTeXML::MathParser qw(:constructors); }}

sub new {
  my ($class,@args) = @_;
  if (! defined $LaTeXML::MathParser::DOCUMENT) {
  {
    # We need to redefine whenever we're not testing from within MathParser
    no warnings 'redefine';
    sub LaTeXML::MathParser::getQName {
      'ltx:'.$_[0]->localname; }
    sub LaTeXML::MathParser::NewScript {
      my ($base,$script)=@_;
      my $role;
      my ($x,$y) = $script->getAttribute('role') =~ /^(FLOAT|POST)?(SUB|SUPER)SCRIPT$/;
      my $t;
      my $app = Apply(New(undef,undef, role=>$y.'SCRIPTOP'),
          $base,Arg($script,0));
      $app; }
  }}
bless {steps=>[]}, $class; }

# I. Basic
sub final_AST {
  my ($values) = @_;
  (@$values>1) ? 
    ['ltx:XMApp',{meaning=>"cdlf-set"},New('cdlf-set',undef,omcd=>"cdlf"),@$values] :
    $values->[0]; }
sub finalize { 
  #print STDERR "\nPruning: " if (exists $_[0]->{__PRUNE});
  #print STDERR "\nFinal state:\n",Dumper($_[0]->{atoms}),"\n\n";
  Marpa::R2::Context::bail('PRUNE') if (exists $_[0]->{__PRUNE});
  $_[1]; }
sub first_arg {
  my ($state,$arg) = @_;
  MaybeLookup($arg); }

# DG: If we don't extend Marpa, we need custom routines to preserve
# grammar category information
sub first_arg_role {
  my ($role,$parse) = @_;
  return $parse if ref $parse;
  my ($lex,$id) = split(/:/,$_[1]);
  my $xml = Lookup($id);
  if (!$xml) {
    $xml = XML::LibXML::Element->new('XMTok');
    $xml->setAttribute('xml:id',$id); 
    $xml->appendText($lex); }
  else { 
    $xml = $xml->cloneNode(1); }
  $xml->setAttribute('role',$role) if $xml;
  return $xml; }
sub first_arg_number {
  my ($state,$parse) = @_;
  first_arg_role('NUMBER',$parse); }
sub first_arg_term {
  my ($state,$parse) = @_;
  first_arg_role('term',$parse); }
sub first_arg_formula {
  my ($state,$parse) = @_;
  first_arg_role('formula',$parse); }

# II. Infix
sub concat_apply {
 my ( $state, $t1, $c, $t2, $type) = @_;
 #print STDERR "ConcApply: ",Dumper($lhs)," <--- ",Dumper($rhs),"\n\n";
 my $app = ApplyNary(New('concatenation',undef,role=>"MULOP",omcd=>"underspecified"),$t1,$t2); 
 $app->[1]->{'cat'}=$type;
 $app; }
## 2. Intermediate layer, records categories on resulting XML:
 # Semantics: FA always scalar
sub concat_apply_factor {
  my ( $state, $t1, $c, $t2) = @_;
  # Only for NON-atomic structures!
  Marpa::R2::Context::bail('PRUNE') unless (((ref $t1) eq 'ARRAY') && ((ref $t2) eq 'ARRAY'));
  concat_apply($state, $t1, $c, $t2,'factor'); }

# Semantics: FA always scalar
sub concat_apply_left {
  my ( $state, $t1, $c, $t2) = @_;
  # if t2 is an atom - mark as scalar or fail if inconsistent
  $state->mark_use($t1,'scalar');
  $state->mark_use($t2,'scalar');
  concat_apply($state, $t1, $c, $t2,'factor'); }

# Semantics: FA always function
sub concat_apply_right {
  my ( $state, $t1, $c, $t2) = @_;  
  # if t1 is an atom - mark as function or fail if inconsistent
  $state->mark_use($t1,'function');
  # Just in case, do the same for $t2, which is a scalar if atom:
  $state->mark_use($t2,'scalar');
  my $app =  Apply($t1,$t2);
  $app->[1]->{'cat'}='factor';
  $app;
}

sub infix_apply {
  my ( $state, $t1, $c, $op, $c2, $t2, $type) = @_;
  $state->mark_use($t1,'scalar') unless (ref $t1 eq 'ARRAY');
  $state->mark_use($t2,'scalar') unless (ref $t1 eq 'ARRAY');
  my $app = ApplyNary(MaybeLookup($op),$t1,$t2); 
  $app->[1]->{'cat'}=$type;
  $app;}
sub infix_apply_factor { infix_apply(@_,'factor'); }
sub infix_apply_term { infix_apply(@_,'term'); }
sub infix_apply_type {  infix_apply(@_,'type'); }
# TODO: Should we do something smarter for chains?
sub infix_apply_relation { infix_apply(@_,'relation'); }
sub chain_apply_relation { infix_apply(@_,'relation'); }
sub infix_apply_formula { infix_apply(@_,'formula'); }
sub chain_apply_formula { infix_apply(@_,'formula'); }
sub infix_apply_entry { infix_apply(@_,'entry'); }
sub infix_apply_vector { 
  my ( $state, $t1, $c, $op, $c2, $t2) = @_;
  my $app = ApplyNary(New('vector',undef,meaning=>"vector",omcd=>"arith1"),$t1,$t2); 
  $app->[1]->{'cat'}='vector';
  $app;}
sub infix_apply_sequence { 
  my ( $state, $t1, $c, $op, $c2, $t2) = @_;
  my $app = ApplyNary(New('sequence',undef,meaning=>"sequence",omcd=>"underspecified"),$t1,$t2); 
  $app->[1]->{'cat'}='sequence';
  $app;}

sub extend_operator {
  my ( $state, $base, $c, $ext_lex) = @_;
  my $extension = MaybeLookup($ext_lex);
  my $merged = $base->cloneNode(1);
  $merged->appendText($extension->textContent);
  $merged; }

# III. Prefix

sub prefix_apply {
  my ( $state, $op, $c, $t,$type) = @_;
  $op = MaybeLookup($op);
  # TODO: specialized rewrite rule, move to an arith semantics CD
  if (($type eq 'term') && blessed($op) && ($op->getAttribute('meaning') eq 'minus')) {
    if (blessed($t) && ($t->getAttribute('role') eq 'NUMBER')) {
      my $number = $t->getAttribute('meaning');
      if ($number =~ /^\d/) {
        $t->removeChildNodes;
        $t->appendText("-$number");
        return $t; }}}

  my $app = ApplyNary($op,$t); 
  $app->[1]->{'cat'}=$type; 
  return $app;}
sub prefix_apply_factor { prefix_apply(@_,'factor'); }
sub prefix_apply_term { prefix_apply(@_,'term'); }
sub prefix_apply_relation { prefix_apply(@_,'relation'); }
sub prefix_apply_formula { prefix_apply(@_,'formula'); }

# IV. Postfix

sub postfix_apply_factor {
  my ($state, $t, $c, $postop) = @_;
  prefix_apply($state,$postop,$c,$t,'factor'); }
sub postfix_apply_term {
  my ($state, $t, $c, $postop) = @_;
  prefix_apply($state,$postop,$c,$t,'term'); }
sub postfix_apply_relation {
  my ($state, $t, $c, $postop) = @_;
  prefix_apply($state,$postop,$c,$t,'relation'); }
sub postfix_apply_formula {
  my ($state, $t, $c, $postop) = @_;
  prefix_apply($state,$postop,$c,$t,'formula'); }
# V. Scripts
sub postscript_apply {
  my ( $state, $base, $c, $script) = @_;
  NewScript(MaybeLookup($base),MaybeLookup($script)); }
sub prescript_apply {
  my ( $state, $script, $c, $base) = @_;
  NewScript(MaybeLookup($base),MaybeLookup($script)); }

# VI. Transfix:
sub set {
  my ( $state, undef, undef, $t, undef, undef, undef, $f ) = @_;
  Apply(New('Set'),$t,$f); }

sub fenced {
  my ($state, $open, undef, $t, undef, $close) = @_;
  $open=~/^([^:]+)\:/; $open=$1;
  $close=~/^([^:]+)\:/; $close=$1;
  Fence($open,MaybeLookup($t),$close); }

sub fenced_empty {
  # TODO: Semantically figure out list/function/set context,
  # and place the correct OpenMath symbol instead!
 my ($state, $open, $c, $close) = @_;
 $open=~/^([^:]+)\:/; $open=$1;
 $close=~/^([^:]+)\:/; $close=$1;
 Fence($open,New('empty',undef,role=>"ATOM",omcd=>"underspecified"),$close); }

### Helpers, ideally should reside in MathParser:

sub MaybeLookup {
  my ($arg) = @_;
  Marpa::R2::Context::bail('PRUNE') unless defined $arg;
  return $arg if ref $arg;
  my ($lex,$id) = split(/:/,$arg);
  my $xml = Lookup($id);
  if (!$xml) {
    $xml = XML::LibXML::Element->new('XMTok');
    $xml->setAttribute('xml:id',$id);
    $xml->appendText($lex); }
  else {
    $xml = $xml->cloneNode(1); }
  return $xml;
}

sub mark_use {
  my ($state,$t2,$value) = @_;
  if (blessed($t2)) {
    my $lex = $t2->textContent;
    my $current = $state->{atoms}->{$lex};
    if (defined $current) {
      Marpa::R2::Context::bail('PRUNE') if ($current ne $value);
    } else {
      # Don't allow numbers as functions, unless 1(x)
      Marpa::R2::Context::bail('PRUNE') if (($value eq 'function') && ($lex =~ /^\d+$/) && ($lex ne '1'));
      $state->{atoms}->{$lex} = $value;
    }
  } else {
    # If f+g is a function, then f and g are functions
    my $op = $t2->[2];
    my $arg1 = $t2->[3];
    my $arg2 = $t2->[4];
    if (blessed($op) && $arg1 && $arg2) {
      my $meaning = $op->getAttribute('meaning');
      # TODO: Think this through, when to do we assume compositionality?
      if ($meaning && ($meaning =~ /^plus|minus|times|divide$/)) {
        $state->mark_use($arg1,$value);
        $state->mark_use($arg2,$value);
      }
    }
  }
  1; }

1;

# TODO: Prefix operators need more thinking...
#   ... quite confusing interplay, think of -sin x and sin x/y
#   or tg n!
# TODO: Maybe add BigTerm as possible argument?