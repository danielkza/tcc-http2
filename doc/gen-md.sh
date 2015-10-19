#!/bin/bash

file="$1"
shift

fname="${file%.*}"
bib="$fname.bib"
pdf="$fname.pdf"

if [ -f "$bib" ]; then
    bib_params[0]="--bibliography"
    bib_params[1]="$bib"
else
    bib_params=()
fi

pandoc --filter pandoc-citeproc --bibliography "bibliografia.bib" "${bib_params[@]}" "$file" -o "$pdf" "$@"
