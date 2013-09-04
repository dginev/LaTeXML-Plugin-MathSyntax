use strict;
use warnings;
use LaTeXML::MathSyntax;

#use Test::More tests => 1;
use Test::More skip_all => "Testbed under construction...";

### Grammar support for notations expressed inside the DLMF

# DLMF:
# (-)^n for (-1)^n
# f^n (x) = [ f (x) ] ^ n usually
# also f ( f ( ... f x ) ) 
# f^-1 (x) = [inv(f)] (x)
# (d/dx) ^ n, (-)^n is compositional
# (z \frac{d}{dx})^n  and also (\frac{d}{dz} z)^n

# Grobner bases (lookup!)
# a := ( 3 > 1)
# a \neq 2 > 1
