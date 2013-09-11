LaTeXML::MathSyntax
===================

An alternative grammar for parsing mathematical expressions for LaTeXML, implemented in Marpa::R2


  ```
  perl Makefile.PL ; make 
  make test # Tests LaTeXML::MathSyntax
  make test_classic # Tests LaTeXML::MathGrammar
  ```



Aims to also provide:
 * A comprehensive test suite for parsing mathematical expressions into content MathML
 * An automated test harness for developing math grammars for LaTeXML
 * Convenient domain-specific languages for writing down tests (e.g. a write-efficient serialization for Content MathML)
