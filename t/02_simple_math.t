use strict;
use warnings;
use File::Basename;
use LaTeXML::Util::TestMath;

my @simple_math_tests = (
'1' => '1:cn',
'1 + 3' => '(+:arith1:plus 1:cn 3:cn)',
# 1 + 3 + 4 (n-ary)
'1 + 3 + 4' => '(+:arith1:plus 1:cn 3:cn 4:cn)',
'1 + 3 - 4' => '(-:arith1:minus (+:arith1:plus 1:cn 3:cn) 4:cn)',
'1 + 3 - 4 = 0' => '(=:relation1:eq (-:arith1:minus (+:arith1:plus 1:cn 3:cn) 4:cn) 0:cn)',
'a^2' => '(:arith1:power a:ci 2:cn)', 
'(a+b)^2' => '(:arith1:power (+:arith1:plus a:ci b:ci) 2:cn)', 
'(a+b)^2 = a^2 + 2ab + b^2' => <<'Semantics',
(=:relation1:eq
  (:arith1:power (+:arith1:plus a:ci b:ci) 2:cn)
  (+:arith1:plus
   (:arith1:power a:ci 2:cn)
   (:arith1:times 2:cn a:ci b:ci)
   (:arith1:power b:ci 2:cn)))
Semantics

'abc' => <<'Semantics',

(:arith1:times a:ci b:ci c:ci )
Semantics

'abcd' => <<'Semantics',

(:arith1:times a:ci b:ci c:ci d:ci )
Semantics
);

math_tests(type=>'syntax',log=>__FILE__,
    reference=>'https://github.com/dginev/LaTeXML-Plugin-MathSyntax',
    tests=>\@simple_math_tests);