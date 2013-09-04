use strict;
use warnings;

use LaTeXML::Util::TestMath;

# Source: http://dlmf.nist.gov/1.2
my @elementary_algebra_tests = (
'k \leq n' => '(≤:relation1:leq k:ci n:ci)',

'\binom{n}{k}=\frac{n!}{(n-k)!k!}=\binom{n}{n-k}.' => <<'Semantics',

(=:relation1:eq
  (:combinat1:binomial n:ci k:ci)
  (:divide:arith1
    (!:integer1:factorial n:ci)
    (:arith1:times
      (!:integer1:factorial (-:arith1:minus n:ci k:ci))
      (!:integer1:factorial k:ci)))
  (:combinat1:binomial n:ci (-:arith1:minus n:ci k:ci)))

Semantics

'(a+b)^{n} = a^{n}+\binom{n}{1}a^{{n-1}}b+
  \binom{n}{2}a^{{n-2}}b^{2}+\dots+
    \binom{n}{n-1}ab^{{n-1}}+b^{n}.' => <<'Semantics',

(=:relation1:eq
  (:arith1:power (+:arith1:plus a:ci b:ci) n:ci)
  (+:arith1:plus
    (:arith1:power a:ci n:ci)
    (:arith1:times
      (:combinat1:binomial n:ci 1:cn)
      (:arith1:power a:ci (-:arith1:minus n:ci 1:cn))
      b:ci )
    (:arith1:times
      (:combinat1:binomial n:ci 2:cn)
      (:arith1:power a:ci (-:arith1:minus n:ci 2:cn))
      (:arith1:power b:ci 2:ci ))
    :underspecified:ellipsis
    (:arith1:times
      (:combinat1:binomial n:ci (-:arith1:minus n:ci 1:cn))
      a:ci
      (:arith1:power b:ci (-:arith1:power n:ci 1:cn) ))
    (:arith1:power b:ci n:ci)))

Semantics

'\binom{n}{0}+\binom{n}{1}+\dots+\binom{n}{n}=2^{n}.' => <<'Semantics',

(=:relation1:eq
  (+:arith1:plus
    (:combinat1:binomial n:ci 0:cn)
    (:combinat1:binomial n:ci 1:cn)
    :underspecified:ellipsis
    (:combinat1:binomial n:ci n:ci))
  (:arith1:power 2:cn n:ci))

Semantics

'\binom{n}{0}-\binom{n}{1}+\dots+(-1)^{n}\binom{n}{n}=0.' => <<'Semantics',

(=:relation1:eq
  (+:arith1:plus
    (:combinat1:binomial n:ci 0:cn)
    (-:arith1:unary_minus (:combinat1:binomial n:ci 1:cn))
    :underspecified:ellipsis
    (:arith1:times
      (:arith1:power -1:cn n:ci)
      (:combinat1:binomial n:ci n:ci)))
  0:cn )

Semantics
);

math_tests(type=>'syntax',tests=>\@elementary_algebra_tests);
