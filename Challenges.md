## Challenges

This is a working document in which I record all non-trivial challenges in mapping between syntax trees and fully semantic operator trees.

The transitions between the two happen in both directions:
 
* Annotating - manually curating a TeX 
 
* Weakening - Simplifying a semantic tree down to a syntax tree.

* Semantic Analysis - grammar, and post-grammar reasoning for inferring the semantics behind a syntax tree
 
### Annotation Challenges

1. Ellipsis (```\dots```, ```\ldots```, ```\cdots```)

    Using ellisions is one common approach to abbreviating, the syntax of a sequential operation, typically used in order to convey the structure of the expression (as opposed to using a big operator such as summation or product).

    What's much less trivial is that ellisions could abbreviate complex alternations in operations that would require semantic rewriting before a reduction to an explicit big operator is possible. That also always includes inferring the range of the big operator.

    Here is a simple example: $ 1 -2 +3 -4 + \ldots $

    At the same time, Content MathML does not provide a placeholder symbol for ellipsis, as an argument can be made that ellipsis hides away semantics from the machine and it wouldn't fit the Content MathML philosophy.

    The worst problem is that if the annotator provides a fully semantic expression, e.g. using a summation with a properly bound variable, there are always several possible syntax trees - the explicit summation tree, as well as a variety of possible rewrites using ellipsis.


### Weakening Challenges

This is clearly the easier direction of processing. Our annotators create the correct Content MathML expression for the TeX formulas in our databank. These content expressions are used as the gold standard for the parsing process and are the evaluation targets of our test suite. However, a grammar that 

1. Mutli-notation symbols (see http://wiki.math-bridge.org)

  1.1 Differentials

### Semantic Analysis Challenges
