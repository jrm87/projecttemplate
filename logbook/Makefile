logbookentries := $(shell grep '\\input{.*entries' logbook.tex | sed 's/^.*\\input{\(.*\.tex\).*/\1/')

all: logbook.pdf

logbook.pdf: logbook.tex $(logbookentries)
	tectonic logbook.tex
#test