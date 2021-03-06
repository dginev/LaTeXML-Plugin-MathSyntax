use strict;
use warnings;
use utf8;

use LaTeXML::Util::TestMath;

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

# '(a+b)^{n} = a^{n}+\binom{n}{1}a^{{n-1}}b+
#   \binom{n}{2}a^{{n-2}}b^{2}+\dots+
#     \binom{n}{n-1}ab^{{n-1}}+b^{n}.' => <<'Semantics',

# (=:relation1:eq
#   (:arith1:power (+:arith1:plus a:ci b:ci) n:ci)
#   (+:arith1:plus
#     (:arith1:power a:ci n:ci)
#     (:arith1:times
#       (:combinat1:binomial n:ci 1:cn)
#       (:arith1:power a:ci (-:arith1:minus n:ci 1:cn))
#       b:ci )
#     (:arith1:times
#       (:combinat1:binomial n:ci 2:cn)
#       (:arith1:power a:ci (-:arith1:minus n:ci 2:cn))
#       (:arith1:power b:ci 2:ci ))
#     …:underspecified:ellipsis
#     (:arith1:times
#       (:combinat1:binomial n:ci (-:arith1:minus n:ci 1:cn))
#       a:ci
#       (:arith1:power b:ci (-:arith1:power n:ci 1:cn) ))
#     (:arith1:power b:ci n:ci)))

# Semantics

'\binom{n}{0}+\binom{n}{1}+\dots+\binom{n}{n}=2^{n}.' => <<'Semantics',

(=:relation1:eq
  (+:arith1:plus
    (:combinat1:binomial n:ci 0:cn)
    (:combinat1:binomial n:ci 1:cn)
    …:underspecified:ellipsis
    (:combinat1:binomial n:ci n:ci))
  (:arith1:power 2:cn n:ci))

Semantics

'\binom{n}{0}-\binom{n}{1}+\dots+(-1)^{n}\binom{n}{n}=0' => <<'Semantics',

(=:relation1:eq
  (+:arith1:plus
    (-:arith1:minus
      (:combinat1:binomial n:ci 0:cn)
      (:combinat1:binomial n:ci 1:cn))
    …:underspecified:ellipsis
    (:arith1:times
      (:arith1:power -1:cn n:ci)
      (:combinat1:binomial n:ci n:ci)))
  0:cn )

Semantics

'\binom{n}{0}+\binom{n}{2}+\binom{n}{4}+\dots+\binom{n}{\ell}=2^{{n-1}},' => <<'Semantics',

(=:relation1:eq
  (+:arith1:plus
    (:combinat1:binomial n:ci 0:cn)
    (:combinat1:binomial n:ci 2:cn)
    (:combinat1:binomial n:ci 4:cn)
    …:underspecified:ellipsis
    (:combinat1:binomial n:ci ℓ:ci))
  (:arith1:power 2:cn (-:arith1:minus n:ci 1:cn)))

Semantics

'\binom{n}{k}=\frac{n(n-1)\cdots(n-k+1)}{k!}%
  = \frac{(-1)^{k}\left(-n\right)_{{k}}}{k!}%
  = (-1)^{k}\binom{k-n-1}{k}.' => <<'Semantics',

(=:relation1:eq
  (:combinat1:binomial n:ci k:ci)
  (:arith1:divide
    (:arith1:times
      n:ci
      (-:arith1:minus n:ci 1:cn)
      ⋯:underspecified:ellipsis
      (+:arith1:plus (-:arith1:minus n:ci k:ci) 1:cn))
    (!:integer1:factorial k:ci))
  (:arith1:divide
    (:arith1:times
      (:arith1:power -1:cn k:ci)
      (:dlmf:pocchamer (-:arith1:unary_minus n:ci) k:ci))
    (!:integer1:factorial k:ci))
  (:arith1:times
    (:arith1:power -1:cn k:ci)
    (:combinat1:binomial (+:arith1:plus (-:arith1:minus k:ci n:ci) -1:cn) k:ci)))
Semantics

'\binom{n+1}{k}=\binom{n}{k}+\binom{n}{k-1}.' => <<'Semantics',

(=:relation1:eq
  (:combinat1:binomial (+:arith1:plus n:ci 1:cn) k:ci)
  (:arith1:plus
    (:combinat1:binomial n:ci k:ci)
    (:combinat1:binomial n:ci (-:arith1:minus k:ci 1:cn))))

Semantics

'\sum^{m}_{{k=0}}\binom{n+k}{k}=\binom{n+m+1}{m}.' => <<'Semantics',

(=:relation1:eq
  (∑:arith1:sum
    (interval1:integer_interval 0:cn m:ci)
    (fns1:lambda {k:ci} 
      (:combinat1:binomial (+:arith1:plus n:ci k:ci) k:ci)))
  (:combinat1:binomial 
    (+:arith1:plus n:ci m:ci 1:cn)
    m:ci ))

Semantics

#'\binom{n}{0}-\binom{n}{1}+\dots+(-1)^{m}\binom{n}{m}=(-1)^{m}\binom{n-1}{m}.' => <<'Semantics',

# (=:relation1:eq
#   (+:arith1:plus
#     (:combinat1:binomial n:ci 0:cn)
#     (-:arith1:unary_minus (:combinat1:binomial n:ci 1:cn))
#     …:underspecified:ellipsis
#     (:arith1:times
#       (:arith1:power -1:cn m:ci)
#       (:combinat1:binomial n:ci m:ci)))
#   (:arith1:times
#     (:arith1:power -1:cn m:ci)
#     (:combinat1:binomial (-:arith1:minus n:ci 1:cn) m:ci)))

# Semantics

#'a+(a+d)+(a+2d)+\dots+(a+(n-1)d)=na+\tfrac{1}{2}n(n-1)d=\tfrac{1}{2}n(a+\ell),' => <<'Semantics',

# (=:relation1:eq
#   (+:arith1:plus
#     a:ci
#     (+:arith1:plus a:ci d:ci)
#     (+:arith1:plus a:ci d:ci)
#     underspecified:ellipsis
#     (+:arith1:plus 
#       a:ci
#       (:arith1:times (-:arith1:minus n:ci 1:cn) d:ci)))
#   (+:arith1:plus
#     (:arith1:times n:ci a:ci)
#     (:arith1:times 
#       1/2:cn[type:rational]
#       n:ci
#       (-:arith1:minus n:ci 1:cn)
#       d:ci ))
#   (:arith1:times
#     1/2:cn[type:rational]
#     n:ci
#     (+:arith1:plus a:ci ℓ:ci)))

# Semantics

'a+ax+ax^{2}+\dots+ax^{{n-1}}=\frac{a(1-x^{n})}{1-x},' => <<'Semantics',

(=:relation1:eq
  (+:arith1:plus
    a:ci
    (:arith1:times a:ci x:ci)
    (:arith1:times a:ci (:arith1:power x:ci 2:cn))
    …:underspecified:ellipsis
    (:arith1:times a:ci (:arith1:power x:ci (-:arith1:minus n:ci 1:cn))))
  (:arith1:divide 
    (-:arith1:minus 1:cn (:arith1:power x:ci n:ci))
    (-:arith1:minus 1:cn x:ci)))

Semantics

'a+ax+ax^{2}+\dots+ax^{{n-1}}=\frac{a(1-x^{n})}{1-x}, x\ne 1' => <<'Semantics',

(quant1:forall {x:ci} 
  (logic1:implies (≠:relation1:neq x:ci 1:cn)
    (=:relation1:eq
      (+:arith1:plus
        a:ci
        (:arith1:times a:ci x:ci)
        (:arith1:times a:ci (:arith1:power x:ci 2:cn))
        …:underspecified:ellipsis
        (:arith1:times a:ci (:arith1:power x:ci (-:arith1:minus n:ci 1:cn))))
      (:arith1:divide 
        (-:arith1:minus 1:cn (:arith1:power x:ci n:ci))
        (-:arith1:minus 1:cn x:ci)))))

Semantics

# # TODO: How do we model here?
# #'\alpha_1, \alpha_2, \ldots, \alpha_n'

# '\frac{f(x)}{(x-\alpha_{1})(x-\alpha_{2})\cdots(x-\alpha_{n})} =%
#   \frac{A_{1}}{x-\alpha_{1}}+%
#   \frac{A_{2}}{x-\alpha_{2}}+\dots+\frac{A_{n}}{x-\alpha_{n}},' => <<'Semantics',

# (=:relation1:eq
#   (:arith1:divide (f:ci x:ci)
#     (:arith1:times
#       (-:arith1:minus x:ci alpha1:ci)
#       (-:arith1:minus x:ci alpha2:ci)
#       …:underspecified:ellipsis
#       (-:arith1:minus x:ci alphan:ci)))
#   (+:arith1:plus
#     (:arith1:divide A1:ci (-:arith1:minus x:ci alpha1:ci))
#     (:arith1:divide A2:ci (-:arith1:minus x:ci alpha2:ci))
#     …:underspecified:ellipsis
#     (:arith1:divide An:ci (-:arith1:minus x:ci alphan:ci))))

# # Semantics

# '1' => <<'Semantics',
# 1:cn
# Semantics
# '1' => <<'Semantics',
# 1:cn
# Semantics
# '1' => <<'Semantics',
# 1:cn
# Semantics
# '1' => <<'Semantics',
# 1:cn
# # Semantics

);

math_tests(type=>'syntax',log=>__FILE__,
  reference=>'http://dlmf.nist.gov/1.2',
  tests=>\@elementary_algebra_tests);
