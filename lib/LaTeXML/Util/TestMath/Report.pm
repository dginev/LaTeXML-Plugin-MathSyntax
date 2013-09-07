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
use Encode;
use Data::Dump qw(dump);
use Scalar::Util qw/blessed/;
use HTML::Entities;

use LaTeXML::Converter;
use LaTeXML::Util::Config;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/math_report/;

# Returns an HTML report of the testing process
our $converter = LaTeXML::Converter->get_converter(
  LaTeXML::Util::Config->new(profile=>'math',math_formats=>['pmml']));
sub math_report {
  my ($file,$entries) = @_;
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
    border-bottom:1pt solid black;
    valign: top;
    vertical-align:text-top;
   }
   tr th {
    border-bottom:1pt solid black;
    background-color:#FFFFC9;
    border-right:solid black;
   }
  </style>
</head>
<body>
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
    $report .= "<td>$mathml</td>";

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
    $report .= "<td>$message</td>";
    $report.='</tr>';
  }
  $report .= '</table></body></html>';
  $file =~ s/\.t$//;
  $file.='.html'; # Always a new file
  open my $fh ,'>', $file;
  print $fh encode('UTF-8',$report);
  close $fh;
  log_drawing_clear($progressString);
  1;
}

sub draw_svg {
  my $array = shift;
  my $result = encode_entities(dump($array));
  $result =~ s/\n/<br>\n/g; 
  $result =~ s/\s/&nbsp;/g; 
  return $result; }

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