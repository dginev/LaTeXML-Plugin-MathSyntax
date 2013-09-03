use strict;
use warnings;

use LaTeXML::Util::TestMath;

my @simple_math_tests = (
'1' => '1:cn',
'1 + 3' => '(+:arith1:plus 1:cn 3:cn)',
# 1 + 3 + 4 (n-ary)
'1 + 3 + 4' => '(+:arith1:plus 1:cn 3:cn 4:cn)',
'1 + 3 - 4' => '(-:arith1:minus (+:arith1:plus 1:cn 3:cn) 4:cn)',
'1 + 3 - 4 = 0' => '(=:relation1:eq (-:arith1:minus (+:arith1:plus 1:cn 3:cn) 4:cn) 0:cn)',
);

math_tests(type=>'syntax',tests=>\@simple_math_tests);

# Further ideas:

# x^2
# 'UNKNOWN:x:1 POSTSUPERSCRIPT:2:2',
# ['ltx:XMApp',{'cat' => 'factor'},
#   ['ltx:XMTok',{role=>'SUPERSCRIPTOP'}],
#   ['ltx:XMTok',{id=>1,role=>'UNKNOWN'},'x'],
#   ['ltx:XMTok',{id=>2,role=>'NUMBER'},'2']],
# 2xy
# x^2 + 2xy
# (x+y)
# (x+y)^2
# x^2 + 2xy + y^2 = (x+y)^2
