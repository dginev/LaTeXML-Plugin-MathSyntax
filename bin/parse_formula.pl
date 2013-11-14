use warnings;
use strict;
use LaTeXML::Util::Config;
use LaTeXML::Converter;

my $tex_math = shift;

my $opts = LaTeXML::Util::Config->new(
  mathparse => 'LaTeXML::MathSyntax',
  input_limit=>100,
  whatsin=>'math',
  whatsout=>'math',
  post=>0,
  verbosity=>1,
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
my $response = $latexml->convert("literal:$tex_math"); 

print STDERR $response->{log},"\n\n",$response->{result}->toString(1),"\n";
