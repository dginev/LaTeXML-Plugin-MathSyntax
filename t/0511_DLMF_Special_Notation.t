use strict;
use warnings;

use LaTeXML::Util::TestMath;

my @special_notation_tests = (
'x' => 'x:ci[type:real]',
'y' => 'y:ci[type:real]',

);

math_tests(type=>'syntax',tests=>\@special_notation_tests);
