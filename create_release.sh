#!/bin/bash

# This shell script will package up the datasets into a zip file as well as
# documentation for a release

# make the directory for the release
mkdir stat_data

# put stuff in it
cp output/addhealth.RData stat_data
cp output/crimes.RData stat_data
cp output/earnings.RData stat_data
cp output/movies.RData stat_data
cp output/politics.RData stat_data
cp output/popularity.RData stat_data
cp output/sex.RData stat_data
cp output/titanic.RData stat_data

# use pandoc to compile the markdown codebook to HTML and PDF
pandoc -o stat_data/codebook.html codebook.md
pandoc -o stat_data/codebook.pdf codebook.md

# archive it!
zip -r stat_data.zip stat_data

# now get rid of the folder
rm -R stat_data
