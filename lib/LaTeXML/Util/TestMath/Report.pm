# ::====================================================================\ #
# | LaTeXML::Util::TestMath::Report                                     | #
# | SVG Reports for math test runs                                      | #
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
use feature qw/switch/;
use Encode;
use Data::Dump qw(dump);
use Scalar::Util qw/blessed/;
use HTML::Entities;

use LaTeXML::Converter;
use LaTeXML::Util::Config;

use Graph::Easy;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/math_report/;

# Returns an HTML report of the testing process
our $converter = LaTeXML::Converter->get_converter(
  LaTeXML::Util::Config->new(profile=>'math',math_formats=>['pmml']));
sub math_report {
  my ($file,$reference,$entries) = @_;
  my $report = <<"HEAD";
<!DOCTYPE html>
<html>
<head>
  <title>Test Report for $file</title>
  <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=UTF-8" />
  <style type="text/css">
   table {width: 100%}
   th {text-align:left}
   tr td {
    border-bottom:1pt dashed black;
    border-right:1pt dashed black;
    valign: middle;
    vertical-align:middle;
   }
   tr th {
    border-bottom:1pt dashed black;
    border-right:1pt dashed black;
    background-color:#FFFFC9;
    valign: middle;
    vertical-align:middle;
   }
  </style>
</head>
<body>
<h1><a href='$reference'>Source Document for Dataset</a></h1>
<table>
  <tr>
    <th>Display</th>
    <th>Parsing Result</th>
    <th>Expected Syntax</th>
    <th>Expected Semantics</th>
    <th>Log Message</th>
  </tr>
HEAD
  my $counter = 0;
  my $total = 3 * scalar(@$entries);
  my $progressString;
  local $| = 1; # Or use IO::Handle; STDOUT->autoflush;
  foreach my $entry (@$entries) {  
    my ($tex,$parse,$expected_syntax,$expected_semantics,$message) = 
      map {$entry->{$_}} qw/tex parse syntax semantics message/;
    # HTML-encode the plain text messages
    # And make newlines explicit
    ($tex,$message) = map {s/\n/<br><\/br>\n/g; $_;} map {encode_entities($_)} ($tex,$message);
    $report.='<tr>';
    # 1. TeX -> Pres MathML
    my $response = $converter->convert($tex);
    my $mathml;
    $mathml = $response->{result} || $tex;
    my $math_color = '';
    $math_color = 'color:red;' if ($message !~ /success/i);
    $report .= "<td style='vertical-align:middle; font-size: 300%; $math_color'>$mathml</td>";

    # 2. Input Parse Forest -> SVG
    $progressString = log_drawing(++$counter,$total, $progressString);
    my $graphed_parse = draw_svg($parse);
    $report .= "<td>$graphed_parse</td>";
    # 3. Expected Syntax Tree -> SVG
    $progressString = log_drawing(++$counter,$total, $progressString);
    my $graphed_syntax = draw_svg($expected_syntax);
    $report .= "<td>$graphed_syntax</td>";
    # 4. Expected Semantic Tree -> SVG
    $progressString = log_drawing(++$counter,$total, $progressString);
    my $graphed_semantics = draw_svg($expected_semantics);
    $report .= "<td>$graphed_semantics</td>";
    # 5. Message report
    $report .= "<td style='vertical-align:middle;'>$message</td>";
    $report.='</tr>';
  }
  $report .= '</table></body></html>';
  $file =~ s/\.t$//;
  $file.='.html'; # Always a new file
  open my $fh ,'>', $file;
  binmode($fh,':encoding(UTF-8)');
  print $fh $report;#encode('UTF-8',$report);
  close $fh;
  log_drawing_clear($progressString);
  1;
}

sub draw_svg {
  my $array = shift;
  return "Failed." unless $array;
  #print STDERR dump($array);
  my $graph = Graph::Easy->new();
  add_nodes($graph,$array,0);
  add_edges($graph,$array);
  $graph->timeout(30);
  my $drawn = $graph->as_svg();
  $drawn =~ s/\s\d+\^(<\/\w+>)$/$1/mg;
  return $drawn; }

sub add_nodes {
  my ($graph,$array,$counter) = @_;
  $counter++;
  my $color = element_to_color($array->[0]);
  my $attr = $array->[1];
  my $label = $array->[0];
  $label =~ s/^(\w+)\:// if $label;# remove namespace
  my $value = '';
  foreach my $subtree(@$array[2..scalar(@$array)-1]) {
    next if ref $subtree;
    $value .= decode('UTF-8',$subtree);  }
  $label.=":$value" if $value;
  #$label.="\\r";
  $label .= " $counter^";
  #$label .= "\x{2062}" x $counter;
  $label.="\\r";
  if (%$attr) {
    my $atrr_count = 0;
    foreach my $key (grep {/^[^_]/} sort keys %$attr) {
      my $value = $attr->{$key};
      $value //= '';
      $label .= "$key:$value\\r";
    }
    $label =~ s/\\r$//;
  }
  $array->[0] = $graph->add_node($label);
  $array->[0]->set_attribute('color',$color);
  foreach my $subtree(@$array[2..scalar(@$array)-1]) {
    next unless ref $subtree;
    $counter = add_nodes($graph,$subtree,$counter); }
  return $counter; }

sub add_edges {
  my ($graph,$array) = @_;
  my $head = $array->[0];
  my $max_width = 2;
  my $offset = 0;
  my $first = 1;
  foreach my $subtree(@$array[2..scalar(@$array)-1]) {
    next unless ref $subtree;
    my $child = $subtree->[0];
    $child->set_attribute('origin',$head->name);
    my $e = $graph->add_edge($head,$child);
    my $child_width = add_edges($graph,$subtree);
    my $offset_string;
    $first = 0 if ($first && ($child->get_attribute('color') eq element_to_color('apply')));
    if ($first) {
      $first = 0;
      # Applied/bound elements should be treated as symbols
      $child->set_attribute('color',element_to_color('csymbol'));
      #$e->set_attribute('start','top,0');
      $e->set_attribute('start','east');
      $e->set_attribute('end','west');
      $offset_string = "$max_width,0"; 
      $max_width += $child_width; }
    else {
      $offset_string = "$offset,3";
      $e->set_attribute('start','south,1');
      $e->set_attribute('end','north,0');
      $offset += $child_width; }
    $child->set_attribute('offset',$offset_string);
  }
  $max_width = $offset if $max_width < $offset;
  return $max_width; }

sub log_drawing {
  my ($counter,$total,$progressString)=@_;
  # remove prev progress
  print STDERR "\b" x length($progressString) if defined $progressString;
  # do lots of processing, update $counter
  $progressString = " Drawing SVG Report ($counter / $total)"; # No more newline
  print STDERR $progressString; # Will print, because auto-flush is on
  # end of processing
  return $progressString; }
sub log_drawing_clear {
  my ($progressString)=@_;
  print STDERR "\b" x length($progressString) if defined $progressString; }

1;

sub element_to_color {
  given (shift) {
    when (undef) {return 'black'}
    when (/^apply|XMApp$/) {return 'orange'}
    when (/^XMTok|cn|ci$/) {return 'black'}
    when (/^bind|bvar$/) {return 'red'}
    when (/^csymbol$/) {return 'blue'}
    default {return 'black'}
  };}