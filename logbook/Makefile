logbookentries := $(shell grep -v '^[[:space:]]*%%' logbook.tex | grep -v '^[[:space:]]*%' | grep '\\input{.*entries' | sed 's/^.*\\input{\(.*\.tex\).*/\1/')

all: logbook.pdf

logbook.pdf: logbook.tex $(logbookentries)
	tectonic logbook.tex
#test