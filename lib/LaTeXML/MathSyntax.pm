# ::====================================================================\ #
# | LaTeXML::MathSyntax                                                 | #
# | A Marpa::R2 grammar for mathematical expressions                    | #
# |=====================================================================| #
# | NOT Part of LaTeXML:                                                | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Deyan Ginev <deyan.ginev@nist.gov>                          #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

## Mantra in Programming: Premature optimisation is the root of all evil
##         =>
## In Grammar Design: Premature disambiguation is the root of all evil

package LaTeXML::MathSyntax;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw/blessed/;

use version 0.2;
our $VERSION = qv("v0.2"); # shorthand

use Marpa::R2;
use LaTeXML::MathAST;
use LaTeXML::Global;
use LaTeXML::Common::Error;

our $parses = 0;
our $RULES = \(<<'END_OF_RULES');
:start ::= Start
# 0. Expression trees considered grammatical:
Start ::= 
  Termlike  action => finalize
  | Formula  action => finalize
  | RelativeFormula  action => finalize
  | Vector  action => finalize
  | TrailingEquals  action => finalize
  | Sequence  action => finalize
  | Operator  action => finalize
# I. Factors
# I.1. FactorArguments (terminals and fenced factors)
FactorArgument ::=
  ATOM  action => first_arg_term
  | UNKNOWN  action => first_arg_term
  | NUMBER  action => first_arg_number
  | ID  action => first_arg_id
  | VERTBAR _ Term _ VERTBAR  action => fenced
  | Prefix _ FactorArgument  action => prefix_apply_factor
  | OPEN _ CLOSE  action => fenced_empty
  | OPEN _ Entry _ CLOSE  action => fenced
  | OPEN _ Vector _ CLOSE  action => fenced # vectors are factors
  | FactorArgument _ Supop action=>postscript_apply
  | FactorArgument _ POSTSUPERSCRIPT action=>postscript_apply
  | FactorArgument _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ FactorArgument action=>prescript_apply
  | FLOATSUBSCRIPT _ FactorArgument action=>prescript_apply

#  | FactorArgument _ RELOP _ Term  action => infix_apply_term

# I.2 Factor compounds
Factor ::=
  FactorArgument
  | FunFactor
  | MulFactor

MulFactor ::=
  # I.2.1. Infix Operator - Factors
  FactorArgument _ Mulop _ FactorArgument  action => infix_apply_factor
  | MulFactor _ Mulop _ FactorArgument  action => infix_apply_factor

  # I.2.3. Infix Concatenation - Left and Right
  | FactorArgument _ FactorArgument  action => concat_apply_left 
  | MulFactor _ FactorArgument  action => concat_apply_left 
  # The asymetry in the above two rules makes '2a f(x)' ungrammatical
  # So we add a rule of lesser priority to match compounds:
  # But if we are not careful, we will allow too many parses for ' f(x)f(y)'
  # But then again we also need to consider (f \circ g) x 
  | PostFactor
  | MulFactor _ PostFactor  action => concat_apply_factor 

PostFactor ::=
  # I.2.2  Postfix operator - factors
  FactorArgument _ Postfix  action => postfix_apply_factor

# You can't multiply on the right side of a fun factor, unless you're using another FunFactor
# TODO: Is that really dead wrong? Probably!!!
FunFactor ::=
  FactorArgument _ FactorArgument  action => concat_apply_right assoc=>right
  | FactorArgument _ FunFactor action => concat_apply_right assoc=>right
  || Factor _ FunFactor  action => concat_apply_factor assoc=>right

# II. Terms 
# II.1. TermArguments
TermArgument ::=
  Prefix _ TermArgument  action => prefix_apply_term
  # Sequences/objects are terms
  | OPEN _ Sequence _ CLOSE  action => fenced
  # TODO: enable Modifiers
  # | TermArgument _ RELOP _ Term  action => infix_apply_term
  | TermArgument _ Supop action=>postscript_apply
  | TermArgument _ POSTSUPERSCRIPT action=>postscript_apply
  | TermArgument _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ TermArgument action=>prescript_apply
  | FLOATSUBSCRIPT _ TermArgument action=>prescript_apply

# II.2. Term compounds
Term ::=
  Factor
  | TermArgument
  | Term _ Addop _ Factor  action => infix_apply_term
  | Term _ Addop _ TermArgument  action => infix_apply_term
  | BigTerm
  | Term _ Addop _ BigTerm  action => infix_apply_term
  | PreTerm
  | TermArgument _ Postfix  action => postfix_apply_term


# III. Types 
# III.1 Type Infix Operator - Type Constructors
Type ::=
  Factor _ Arrow _ Factor  action => infix_apply_type
  | Type _ Arrow _ Factor  action => infix_apply_type

# III. Termlike constructs
Termlike ::=
  # Types should be allowed as terminals
  Term
  | Type
  | TermSequence
  | PostTerm # Not really Term since we don't want Addop to work on the right

# IV. Formulas
Formula ::=
  # Infix Logical Operators
  FormulaArgument
  | Relative
  | PostRelative
  | Formula _ LOGICOP _ Relative  action => infix_apply_formula
  | Formula _ LOGICOP _ FormulaArgument  action => infix_apply_formula
  | FormulaArgument _ Supop action=>postscript_apply
  | FormulaArgument _ POSTSUPERSCRIPT action=>postscript_apply
  | FormulaArgument _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ FormulaArgument action=>prescript_apply
  | FLOATSUBSCRIPT _ FormulaArgument action=>prescript_apply


# V. Big Terms
BigTerm ::=
  # V.1. Big Summation
  # Think about this -> it behaves as a Factor argument on the left e.g.
  #    (1-t)\sum ...
  # but never on the right! We should enforce this to avoid confusion? 
  # use a BigTerm category?
  Bigop _ Factor  action => prefix_apply_term
  | Bigop _ TermArgument  action => prefix_apply_term
  | Bigop _ BigTerm  action => prefix_apply_term
  # V.2.1 Operations on BigTerms:
  | Factor _ BigTerm  action => concat_apply_factor
  | Factor _ Mulop _ BigTerm  action => infix_apply_factor

# VI. PreTerms
PreTerm ::=
  Addop _ FactorArgument  action => prefix_apply_term
  | Addop _ TermArgument  action => prefix_apply_term
  # VI.1. Operations on PreTerms:
  | PreTerm _ FactorArgument  action => concat_apply_factor
  | PreTerm _ Mulop _ FactorArgument  action => infix_apply_factor
  # Note: the Addop operations are inherited from the usual Addop rules,
  #       as PreTerm can be cast as Term

# VII. PostTerms
PostTerm ::=
  FactorArgument _ Addop  action => postfix_apply_factor
  | TermArgument _ Addop  action => postfix_apply_term
  # VII.1 Operations on PreTerms:
  | FactorArgument _ PostTerm  action => concat_apply_factor
  | FactorArgument _ Mulop _ PostTerm  action => infix_apply_factor
  # VII.2. Typing
  # Base types x : A
  | FactorArgument _ COLON _ Factor  action => infix_apply_term
  # Function types
  | FactorArgument _ COLON _ Type  action => infix_apply_term
  | TermArgument _ COLON _ Type  action => infix_apply_term

# VIII. Relations
# VIII.1. Infix relations
# TODO: How do we deal with term sequences, 1,2,3\in N ?
Relative ::=
  Termlike _ Relop _ Termlike  action => infix_apply_relation
  | Relative _ Relop _ Termlike  action => chain_apply_relation
  # VIII.2 Prefix relations
  | PreRelative

# IX. PreRelations
PreRelative ::= Relop _ Termlike  action => prefix_apply_relation
# X. Postfix relations
PostRelative ::=
  Relative _ Relop  action => postfix_apply_relation
  | Termlike _ Relop _ PostRelative  action => chain_apply_relation

# XI. Metarelations
RelativeFormula ::=
  RelativeFormulaArgument
  | Formula _ Metarelop _ Formula  action => infix_apply_formula
  | RelativeFormula _ Metarelop _ Formula  action => chain_apply_formula


# Notes: Modifiers
# Modified terms should only appear in sequences, hence entries
# Hm, not really, they can appear anywhere with ease, as long as 
# the relation ops are from different domains, so that there is a unique reading

FormulaArgument ::= 
  FormulaArgument _ COLON _ Type  action => infix_apply_formula
  | OPEN _ Formula _ CLOSE  action => fenced
  # | FormulaArgument ::= FormulaArgument _ Relop _ Term  action => infix_apply_formula
  | FormulaArgument _ Supop action=>postscript_apply
  | FormulaArgument _ POSTSUPERSCRIPT action=>postscript_apply
  | FormulaArgument _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ FormulaArgument action=>prescript_apply
  | FLOATSUBSCRIPT _ FormulaArgument action=>prescript_apply


# Examples???
RelativeFormulaArgument ::= 
  OPEN _ RelativeFormula _ CLOSE  action => fenced
  | RelativeFormulaArgument _ Supop action=>postscript_apply
  | RelativeFormulaArgument _ POSTSUPERSCRIPT action=>postscript_apply
  | RelativeFormulaArgument _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ RelativeFormulaArgument action=>prescript_apply
  | FLOATSUBSCRIPT _ RelativeFormulaArgument action=>prescript_apply

# XII. Sequence structures
# XII.1. Vectors:

Entry ::= 
  Term
  | FactorArgument _ Relop _ Term  action => infix_apply_entry
  # a := (1<3) should be grammatical
  | FactorArgument _ Relop _ FormulaArgument  action => infix_apply_entry
  # Infix Modifier - Typing
  # | FactorArgument _ COLON _ Type  action => infix_apply

# So, allow them everywhere and let them explode:
# ... or not ... we need something smart here
Vector ::=
  Entry _ PUNCT _ Entry  action => infix_apply_vector
  | Vector _ PUNCT _ Entry  action => infix_apply_vector

# XII.2. General sequences:
# XII.2.1 Base case: elements
Element ::=
  Formula
  | Addop
  | Mulop
  | Relop
  | Prefix
  | Postfix
  | Metarelop
# XII.2.2 Recursive case: sequences
Sequence ::= 
  Vector _ PUNCT _ Element  action => infix_apply_sequence
  | Entry _ PUNCT _ Element  action => infix_apply_sequence
  | Element _ PUNCT _ Entry  action => infix_apply_sequence
  | Sequence _ PUNCT _ Entry  action => infix_apply_sequence
  # Yuck! Vector adjustments to avoid multiple parses 
  | Element _ PUNCT _ Element  action => infix_apply_sequence
  | Sequence _ PUNCT _ Element  action => infix_apply_sequence

# XII.3. Term sequences - TODO: what are these really? progressions?
TermSequence ::=
  Term _ PUNCT _ Term  action => infix_apply_sequence
  | TermSequence _ PUNCT _ Term  action => infix_apply_sequence

# XIII. Special cases:
# XIII.1. Trailing equals (should it really be grammatical?)
# TODO: Produces bad markup, figure out how to make <none> elements
TrailingEquals ::=
  Formula _ EQUALS  action => infix_apply_formula
  | Term _ EQUALS  action => infix_apply_relation

# XIII.2. Operators
Operator ::=
  OPERATOR
  | Mulop
  | Addop
  | Prefix
  | Postfix
  | Relop
  | Metarelop
  | Arrow
  | Supop
  | Bigop

# XIV. Lexicon adjustments
# TODO: Reconsider if atoms should be allowed as "formulas"
#       creates a lot of (spurious?) ambiguity
#FormulaArgument ::= UNKNOWN action=>first_arg_formula
#FormulaArgument ::= ATOM action=>first_arg_formula

Relop ::=
  RELOP
  | EQUALS
  | Relop _ Supop action=>postscript_apply
  | Relop _ POSTSUPERSCRIPT action=>postscript_apply
  | Relop _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ Relop action=>prescript_apply
  | FLOATSUBSCRIPT _ Relop action=>prescript_apply

Metarelop ::=
  EQUALS
  | METARELOP
  | VERTBAR
  | Metarelop _ Supop action=>postscript_apply
  | Metarelop _ POSTSUPERSCRIPT action=>postscript_apply
  | Metarelop _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ Metarelop action=>prescript_apply
  | FLOATSUBSCRIPT _ Metarelop action=>prescript_apply

Addop ::=
  ADDOP
  # Boolean algebra, lattices
  | LOGICOP
  # TODO: \pmod ? Where does it fit?
  | MODIFIER
  # (-) ?? TODO: what about the other ops?
  | OPEN _ Addop _ CLOSE  action => fenced
  | Addop _ Supop action=>postscript_apply
  | Addop _ POSTSUPERSCRIPT action=>postscript_apply
  | Addop _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ Addop action=>prescript_apply
  | FLOATSUBSCRIPT _ Addop action=>prescript_apply

Mulop ::=
  MULOP
  # TODO: Think about PERIOD, lex?
  | PERIOD
  | VERTBAR
  | Mulop _ Supop action=>postscript_apply
  | Mulop _ POSTSUPERSCRIPT action=>postscript_apply
  | Mulop _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ Mulop action=>prescript_apply
  | FLOATSUBSCRIPT _ Mulop action=>prescript_apply

Arrow ::=
  ARROW
  | Arrow _ Supop action=>postscript_apply
  | Arrow _ POSTSUPERSCRIPT action=>postscript_apply
  | Arrow _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ Arrow action=>prescript_apply
  | FLOATSUBSCRIPT _ Arrow action=>prescript_apply

Prefix ::=
  PREFIX
  | TRIGFUNCTION
  | OPFUNCTION
  | FUNCTION
  | MODIFIEROP #TODO: Think this through, maybe lex change
  | LIMITOP
  | OPERATOR
  | Prefix _ Supop action=>postscript_apply
  | Prefix _ POSTSUPERSCRIPT action=>postscript_apply
  | Prefix _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ Prefix action=>prescript_apply
  | FLOATSUBSCRIPT _ Prefix action=>prescript_apply

Postfix ::=
  POSTFIX
  | FACTORIAL # TODO: Look into postfix lexing
  | Postfix _ Supop action=>postscript_apply
  | Postfix _ POSTSUPERSCRIPT action=>postscript_apply
  | Postfix _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ Postfix action=>prescript_apply
  | FLOATSUBSCRIPT _ Postfix action=>prescript_apply

Bigop ::=
  BIGOP
  | SUMOP
  | INTOP
  | Bigop _ Supop action=>postscript_apply
  | Bigop _ POSTSUPERSCRIPT action=>postscript_apply
  | Bigop _ POSTSUBSCRIPT action=>postscript_apply
  | FLOATSUPERSCRIPT _ Bigop action=>prescript_apply
  | FLOATSUBSCRIPT _ Bigop action=>prescript_apply

Supop ::= 
  SUPOP
  | Supop _ SUPOP action => extend_operator

# Terminal categories need unicorn lexers for SLIF to compile successfully
# They will never be lex-able from within SLIF, but we expect LaTeXML to provide them reliably

ATOM ~ unicorn
UNKNOWN ~ unicorn
NUMBER ~ unicorn
ID ~ unicorn
VERTBAR ~ unicorn
_ ~ unicorn
OPEN ~ unicorn
CLOSE ~ unicorn
COLON ~ unicorn
PUNCT ~ unicorn
EQUALS ~ unicorn
ARROW ~ unicorn
LOGICOP ~ unicorn
SUPOP ~ unicorn
MODIFIER ~ unicorn
PERIOD ~ unicorn
TRIGFUNCTION ~ unicorn
OPFUNCTION ~ unicorn
FUNCTION ~ unicorn
MODIFIEROP ~ unicorn
LIMITOP ~ unicorn
OPERATOR ~ unicorn
FACTORIAL ~ unicorn
SUMOP ~ unicorn
INTOP ~ unicorn
POSTSUBSCRIPT ~ unicorn
POSTSUPERSCRIPT ~ unicorn
FLOATSUBSCRIPT ~ unicorn
FLOATSUPERSCRIPT ~ unicorn
RELOP ~ unicorn
MULOP ~ unicorn
ADDOP ~ unicorn
METARELOP ~ unicorn
PREFIX ~ unicorn
POSTFIX ~ unicorn
BIGOP ~ unicorn

unicorn ~ [^\s\S]
END_OF_RULES

sub new {
  my($class,%options)=@_;
    my $grammar = Marpa::R2::Scanless::G->new(
        {   action_object  => 'LaTeXML::MathAST',
            default_action => 'first_arg',
            source         => $RULES,
        }
    );
  my $self = bless {grammar=>$grammar,%options},$class;
  $self; }

sub parse {
  my ($self,$rule,$lexref) = @_;
  my $rec = Marpa::R2::Scanless::R->new( { grammar => $self->{grammar},
                                         ranking_method => 'high_rule_only'} );
  my @unparsed = split(' ',$$lexref);
  # Insert concatenation
  @unparsed = map (($_, '_::'), @unparsed);
  pop @unparsed;
  #print STDERR "\n\n";
  my $failed = 0;
  my $rec_events = undef;
  my $unparsed_input = join(' ',@unparsed);
  $rec->read(\$unparsed_input,0,0);
  my $pos = 0;
  while (@unparsed) {
    my $next = shift @unparsed;
    my ($category,$lexeme,$id) = split(':',$next);
    # Issues: 
    # 1. More specific lexical roles for fences, =, :, others...?
    if ($category eq 'METARELOP') {
      $category = 'COLON' if ($lexeme eq 'colon');
    } elsif ($category eq 'RELOP') {
      $category = 'EQUALS' if ($lexeme eq 'equals');
    }
    #$category.='Terminal' if $category =~ /^(((META)?REL|ADD|LOGIC|MUL|SUP|BIG)OP)|ARROW|P(RE|OST)FIX$/;
    #print STDERR "$category:$lexeme:$id\n";
    my $value = $lexeme.':'.$id;
    my $length = length($next);
    $rec_events = $rec->lexeme_read($category,$pos,$length,$value);
    $pos += $length+1;
    if (! defined $rec_events) {
      print STDERR "Error:lexeme_read:events No rec_events were recorded!\n";
      $failed = 1; last;
    }
  }

  my @values = ();
  my $saved_report;
  $$lexref = undef; # Reset this , so that we are consistent with the RecDescent behaviour
  if (!$failed) {
    my $value_ref=\'init';
    local $@;
    while ((defined $value_ref) || $@) {
      $value_ref = undef;
      my $eval_return = eval { local $SIG{__DIE__}; $value_ref = $rec->value(); 1; };
      if ($@ || (!$eval_return)) {
        $saved_report.="$@\n";
        next ;
      }
      push @values, ${$value_ref} if (defined $value_ref);
    } 
  }
  if (!@values) { # Incomplete / no parse
    Warn('not_parsed','Marpa',undef,$saved_report);
    $$lexref = join(' ',grep($_ ne '_::', @unparsed)); }
  my $result = LaTeXML::MathAST::final_AST(\@values);
  if ($self->{output} && ($self->{output} eq 'array')) {
    return convert_to_array($result); }
  else {
    return $result; }
}

sub convert_to_array {
  my ($tree) = @_;
  if (blessed($tree)) {
    # XML leaf, turn to array:
    my @attributelist = $tree->attributes();
    my $attributes = {map {$_->localname() => $_->value()} @attributelist};
    ['ltx:'.$tree->localname,$attributes,$tree->textContent]; }
  elsif (ref $tree eq 'ARRAY') {
    return [map {convert_to_array($_)} @$tree]; }
  else {
    return $tree; }}

1;
