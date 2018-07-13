package LaTeXML::Demo::MathAST;
use XML::LibXML;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use Data::Dumper;

# I. Basic
sub new {
  my ($class) = @_;
  return bless {},  $class;
}

sub final_AST {
  my ($values) = @_;
  if (@$values>1) {
    my $apply_el = XML::LibXML::Element->new('ltx:XMApp');
    my $set_el =  XML::LibXML::Element->new('ltx:XMTok');
    $set_el->setAttribute('meaning','set');
    $set_el->setAttribute('omcd','cdlf');
    $apply_el->appendChild($set_el);
    for my $value(@$values) {
      $apply_el->appendChild($value);
    }
    return $apply_el;
  }
  else {
    return $values->[0]; } }

sub finalize { 
  #print STDERR "\nPruning: " if (exists $_[0]->{__PRUNE});
  #print STDERR "\nFinal state:\n",Dumper($_[0]->{atoms}),"\n\n";
  Marpa::R2::Context::bail('PRUNE') if (exists $_[0]->{__PRUNE});
  $_[1]; }



sub first_arg {
  my ($state, $parse) = @_;
  Leaf($parse);
}
sub first_arg_term {
  Leaf($_[1], 'term');
}

sub first_arg_number {
  Leaf($_[1],'NUMBER');
}
sub first_arg_id {
  Leaf($_[1],'ID');
}
sub first_arg_bigop {
  Leaf($_[1],'BIGOP');
}
sub first_arg_function {
  Leaf($_[1],'FUNCTION');
}

##
sub concat_apply {
 my ( $state, $t1, $c, $t2, $type) = @_;
 #print STDERR "ConcApply: ",Dumper($lhs)," <--- ",Dumper($rhs),"\n\n";
 my $app = ApplyNary(New('concatenation',undef,role=>"MULOP",omcd=>"underspecified"),$t1,$t2); 
 $app->setAttribute('category',$type); 
 $app; }
## 2. Intermediate layer, records categories on resulting XML:
 # Semantics: FA always scalar
sub concat_apply_factor {
  my ( $state, $t1, $c, $t2) = @_;
  # Only for NON-atomic pairs of function applications!
  # I.e. f(x)g(y)
  # my $r1 = ref $t1;
  # my $r2 = ref $t2;
  # if ($r1 && $r2 && ($r1 eq 'ARRAY') && ($r2 eq 'ARRAY')
  #  && ($r1->[0] eq 'ltx:XMApp') && ($r2->[0] eq 'ltx:XMApp')) {
  #   my $op1 = $t1->[2];
  #   my $bop1 = blessed($op1);
  #   if ($bop1 && ($bop1 eq 'XML::LibXML::Element')) {
  #     my $meaning1 = $op1->getAttribute('meaning');
  #     if ($meaning1 && ($meaning1 eq 'concatenation')) {
  #       Marpa::R2::Context::bail('PRUNE');
  #     }
  #   }
  #   my $op2 = $t2->[2];
  #   my $bop2 = blessed($op2);
  #   if ($bop2 && ($bop2 eq 'XML::LibXML::Element')) {
  #     my $meaning2 = $op2->getAttribute('meaning');
  #     if ($meaning2 && ($meaning2 eq 'concatenation')) {
  #       Marpa::R2::Context::bail('PRUNE');
  #     }
  #   }
  # }
  concat_apply($state, $t1, $c, $t2,'factor'); }

# Semantics: FA always scalar
sub concat_apply_left {
  my ( $state, $t1, $c, $t2) = @_;
  # If our left multiplier was a function application (unfenced), prune
  # "fa2 -> (f@(a)) x 2 " isn't grammatical
  # but f(a)2 -> (f@(a)) x 2 could be
  # if t2 is an atom - mark as scalar or fail if inconsistent
  my $r1 = ref $t1;
  if ($r1 && ($r1 eq 'ARRAY')) {
    my $op = $t1->[2];
    my $arg = $t1->[3];
    my $bop = $op && blessed($op);
    my $barg = $arg && blessed($arg);
    if ($bop && ($bop eq 'XML::LibXML::Element')) {
      my $role = $op->getAttribute('role');
      if ($role && ($role eq 'term')) { 
        if ($barg && (($barg ne 'XML::LibXML::Element') || (! $arg->getAttribute('close')))) {
          Marpa::R2::Context::bail('PRUNE');
        }}}}
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
  $app->setAttribute('category','factor'); 
  $app;
}

# Apply $op to the list of arguments
# args may be array-rep or lexemes (or nodes?)
sub Apply {
  my ($op, @args) = @_;

  my $xml = XML::LibXML::Element->new('ltx:XMApp');
  $xml->appendChild($op);
  for my $arg(@args) {
    $xml->appendChild($arg);
  }
  return $xml;
}


sub infix_apply {
  my ( $state, $t1, $c, $op, $c2, $t2, $type) = @_;
  if (($type eq 'factor') || ($type eq 'term')) {
    $state->mark_use($t1,'scalar') if ((ref $t1) ne 'ARRAY');
    $state->mark_use($t2,'scalar') if ((ref $t2) ne 'ARRAY');
  }
  $op = Leaf($op);
  my $app = Apply($op,$t1,$t2); 
  $app->setAttribute('category', $type);
  $app;}
sub infix_chain { return infix_apply(@_); }
  # TODO:
  # my ( $state, $t1, $c, $op, $c2, $t2, $type) = @_;
  # $op = Leaf($op);
  # We are chaining left-to-right, so grab the rightmost leaf of $t1 and $op it to $t2
  # my $new_relation = Apply($op,$t1->[4],$t2);
  # my $app = Apply()
  # $app->[1]->{'cat'}=$type;
  # $app;}
sub infix_apply_factor { infix_apply(@_,'factor'); }
sub infix_apply_term { infix_apply(@_,'term'); }
sub infix_apply_type {  infix_apply(@_,'type'); }
# TODO: Should we do something smarter for chains?
sub infix_apply_relation { infix_apply(@_,'relation'); }
sub chain_apply_relation { infix_chain(@_,'relation'); }
sub infix_apply_formula { infix_apply(@_,'formula'); }
sub chain_apply_formula { infix_chain(@_,'formula'); }
sub infix_apply_entry { infix_apply(@_,'entry'); }
sub infix_apply_vector { 
  my ( $state, $t1, $c, $op, $c2, $t2) = @_;
  my $app = ApplyNary(New('vector',undef,meaning=>"vector",omcd=>"arith1"),$t1,$t2); 
  $app->setAttribute('category','vector'); 
  $app;}
sub infix_apply_sequence { 
  my ( $state, $t1, $c, $op, $c2, $t2) = @_;
  my $app = ApplyNary(New('sequence',undef,meaning=>"sequence",omcd=>"underspecified"),$t1,$t2); 
  $app->setAttribute('category','sequence'); 
  $app;}

sub extend_operator {
  my ( $state, $base, $c, $ext_lex) = @_;
  my $extension = Leaf($ext_lex);
  my $merged = $base->cloneNode(1);
  $merged->appendText($extension->textContent);
  $merged; }


sub fenced {
  my ($state, $open, undef, $t, undef, $close) = @_;
  $open=~/^([^:]+)\:/; $open=$1;
  $close=~/^([^:]+)\:/; $close=$1;
  [$open,Leaf($t),$close];
}
sub fenced_empty {
  # TODO: Semantically figure out list/function/set context,
  # and place the correct OpenMath symbol instead!
 my ($state, $open, $c, $close) = @_;
 $open=~/^([^:]+)\:/; $open=$1;
 $close=~/^([^:]+)\:/; $close=$1;
 [$open,New('empty',undef,role=>"ATOM",omcd=>"underspecified"),$close]; }


sub prefix_apply {
  my ( $state, $op, $c, $t,$type) = @_;
  $op = Leaf($op);
  my $app = Apply($op,$t);  # TODO: Should be ApplyNary
  $app->setAttribute('category',$type); 
  return $app;
}

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
  [Leaf($base),Leaf($script)]; }
sub prescript_apply {
  my ( $state, $script, $c, $base) = @_;
  [Leaf($base),Leaf($script)]; }



sub Leaf {
  my ($arg, $role) = @_;
  Marpa::R2::Context::bail('PRUNE') unless defined $arg;
  return $arg if ref $arg;
  my ($lex,$id) = split(/:/,$arg);

  my $xml = XML::LibXML::Element->new('ltx:XMTok');
  $xml->setAttribute('xml:id',$id);
  $xml->setAttribute('role',$role) if $role;
  $xml->appendText($lex);

  return $xml; 
}


sub mark_use {
  my ($state,$token,$value) = @_;
  return unless $token;
  my $class = blessed($token);
  my $ref = ref $token;
  if ($class && ($class eq 'XML::LibXML::Element')) {
    my $role = $token->getAttribute('role');
    my $lex = $token->textContent;
    my $current = $state->{atoms}->{$lex};
    if ($current && $value && ($current ne $value)) {
      Marpa::R2::Context::bail('PRUNE');
    } else {
      Marpa::R2::Context::bail('PRUNE') if (
        ($value eq 'function') && (
          # Don't allow numbers as functions, unless 1(x)
          (($lex =~ /^\d+$/) && ($lex ne '1'))
          # Don't allow IDs as functions either
          || ($role eq 'ID') || ($role eq 'NUMBER')
        ));
      $state->{atoms}->{$lex} = $value;
    }
  }
  elsif ($ref && ($ref eq 'ARRAY')) {
    # If array, still make sure we prune away known roles
    my $role = $token->[1] && ((ref $token->[1]) eq 'HASH') && $token->[1]->{role};
    Marpa::R2::Context::bail('PRUNE') if ($role && ($value eq 'function') && (
      ($role eq 'ID') || ($role eq 'NUMBER')
    ));
  }
  #   # If f+g is a function, then f and g are functions
  #   my $op = $token->[2];
  #   my $arg1 = $token->[3];
  #   my $arg2 = $token->[4];
  #   my $bop = blessed($op);
  #   if ($bop && ($bop eq 'XML::LibXML::Element') && $arg1 && $arg2) {
  #     my $meaning = $op->getAttribute('meaning');
  #     # TODO: Think this through, when to do we assume compositionality?
  #     if ($meaning && ($meaning =~ /^plus|minus|times|divide$/)) {
  #       $state->mark_use($arg1,$value);
  #       $state->mark_use($arg2,$value);
  #     }
  #   }
  # }
  1; }

1; 