PANDOC_OPTIONS = \
--filter=pandoc-citeproc \
--toc \
--normalize \
--biblio=bibliografia.bib

PANDOC_PDF_OPTIONS = \
--standalone \
--smart \
--parse-raw \
--template=templates/abntex2.tex \
-V documentclass=abntex2 \
-V papersize=a4paper \
-V fontsize=12pt \
-V classoption=twoside \
-V classoption=openright \
-V linkcolor=blue \
-V csl=templates/abnt.csl

PANDOC_HTML_OPTIONS = \
-t html5 \
--standalone \
--template=templates/template.html \
-H templates/header.html

all: html pdf
html: html/monografia.html html/relatorio-parcial.html html/proposta.html 
pdf: pdf/monografia.pdf pdf/relatorio-parcial.pdf pdf/proposta.pdf
tex: tex/monografia.tex tex/relatorio-parcial.tex tex/proposta.tex

html/%.html: %.md templates/template.html templates/header.html
	mkdir -p html
	pandoc $(PANDOC_OPTIONS) $(PANDOC_HTML_OPTIONS) $< -o $@

pdf/%.pdf: %.md templates/abntex2.tex templates/abnt.csl
	mkdir -p pdf
	pandoc $(PANDOC_OPTIONS) $(PANDOC_PDF_OPTIONS) $< -o $@

tex/%.tex: %.md templates/abntex2.tex templates/abnt.csl
	mkdir -p tex
	pandoc $(PANDOC_OPTIONS) $(PANDOC_PDF_OPTIONS) $< -o $@

%.md: bibliografia.bib

.PHONY: all html pdf tex
