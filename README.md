**Note April 2019**: This plugin has been frozen in the last 5 years and has fallen out of alignment with the latexml master. Gradual work on repairing and modernizing it has begun, but third-party use is not advised until a new release is made.

An alternative grammar for parsing mathematical expressions for LaTeXML, implemented in Marpa::R2.

The grammar is loosely motivated by [The Structure of Mathematical Expressions](https://prodg.org/DeyanGinev_MScThesis.pdf), and explores designing for ambiguous parses with follow-up semantic pruning.


  ```
  perl Makefile.PL ; make
  make test # Tests LaTeXML::MathSyntax
  make test_classic # Tests LaTeXML::MathGrammar
  ```

Aims to also provide:
 * A comprehensive test suite for parsing mathematical expressions into content MathML
 * An automated test harness for developing math grammars for LaTeXML
 * Convenient domain-specific languages for writing down tests (e.g. a write-efficient serialization for Content MathML)

### Dataset

 * Gradually formalising all of DLMF's ~10,000 equations.
 * Intending to formalize ~1,000 or more formulas from arXiv.org

### Annotations
 * Each item in the test suite consists of a ```<TeX formula, Content MathML tree>``` tuple.
 * The TeX can be any input written in a real-world mathematical document.
 * The Content MathML tree must be written in the strict CMML syntax, complying with existing content dictionaries.
 * The CMML tree must **avoid** large semantic rewrites of the input expression.

  **Example:** In the case of an ellipssis (...) the annotation should ideally preserve the ellipsis explicitly
  via a special underspecified symbol, such as ```:underspecified:ellipsis```.
  Full formalization is not only difficult, but also not always possible, for ellided content.
  The rule of thumb should always be to consider whether a math grammar should realistically be expected to perform
  the analysis necessary for the rewrite.
