SHELL   := /bin/bash
PACKAGE := $(shell perl -aF: -ne 'print, exit if s/^Package:\s+//' DESCRIPTION)
VERSION := $(shell perl -aF: -ne 'print, exit if s/^Version:\s+//' DESCRIPTION)
BUILD   := $(PACKAGE)_$(VERSION).tar.gz

.PHONY: doc build install test vignette $(BUILD)

check: $(BUILD)
	R CMD check --as-cran $<

check-cran: $(BUILD)
	R --interactive --no-save --args $< <<<'rhub::check_for_cran(commandArgs(T)[1])'
	Rscript -e "rhub::check_on_solaris()"


build:
	autoconf
	chmod 755 cleanup
	chmod 755 configure
	find src/ -type f -exec chmod 644 {} \;
	chmod 644 ChangeLog DESCRIPTION Makefile NAMESPACE README.md 
	./configure
	./cleanup
	Rscript -e "library(Rcpp); compileAttributes('.');"
	Rscript -e "devtools::load_all(); roxygen2::roxygenise('.');"
	find . -iname "*.a" -exec rm {} \;
	find . -iname "*.o" -exec rm {} \;
	find . -iname "*.so" -exec rm {} \;
	R CMD build .

install:
	autoconf
	chmod 755 cleanup
	chmod 755 configure
	find src/ -type f -exec chmod 644 {} \;
	chmod 644 ChangeLog DESCRIPTION Makefile NAMESPACE README.md 
	./configure
	./cleanup
	Rscript -e "library(Rcpp); compileAttributes('.');"
	Rscript -e "devtools::load_all(); roxygen2::roxygenise('.');"
	find . -iname "*.a" -exec rm {} \;
	find . -iname "*.o" -exec rm {} \;
	find . -iname "*.so" -exec rm {} \;
	R CMD build .
	R CMD INSTALL $(BUILD) --configure-args="--with-simd=AVX2"

vignette:
	Rscript -e "rmarkdown::render(input='vignettes/vignette.rmd', output_format='all')"
	mv vignettes/vignette.md README.md
	sed -r -i 's/\((.+)\.png/\(vignettes\/\1\.png/' README.md
	
test:
	Rscript tests/correctness_testing.R filestream
	Rscript tests/correctness_testing.R fd
	Rscript tests/regression_testing.R
	
bench:
	Rscript tests/benchmark_testing.R