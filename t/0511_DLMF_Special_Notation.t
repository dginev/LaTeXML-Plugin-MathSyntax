use strict;
use warnings;
use utf8;

use LaTeXML::Util::TestMath;

# Source: http://dlmf.nist.gov/1.1
my @special_notation_tests = (
'x' => 'x:ci[type:real]',
'y' => 'y:ci[type:real]',
'z' => 'z:ci[type:real]',
'z' => 'z:ci[type:complex]',
'w' => 'w:ci[type:complex]',
'j' => 'j:ci[type:integer]',
'k' => 'k:ci[type:integer]',
'\ell' => "ℓ:ci[type:integer]",
'm' => 'm:ci[type:integer]',
'n' => 'n:ci[type:integer]',
'\langle f,g \rangle' => ':dlmf:distribution', #???
'\deg' => 'deg:poly1:degree',
'\prime' => "′:calculus1:diff",
#'x^{\prime\prime}' => 
'1' =>
  '((:calculus1:nthdiff 2:cn (:fns1:lambda {x:ci} x:ci)) x:ci)',
'x^{\prime\prime\prime}' => 
  '((:calculus1:nthdiff 3:cn (:fns1:lambda {x:ci} x:ci)) x:ci)',
'x^{\prime\prime\prime\prime}' => 
  '((:calculus1:nthdiff 4:cn (:fns1:lambda {x:ci} x:ci)) x:ci)',
);

math_tests(type=>'syntax',log=>__FILE__,tests=>\@special_notation_tests);
