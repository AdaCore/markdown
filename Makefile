#
#  Copyright (C) 2021-2022, AdaCore
#
#  SPDX-License-Identifier: Apache-2.0
#

# Build mode (dev, prod or coverage)
BUILD_MODE=dev

GPRBUILD_FLAGS = -p -j0 -XBUILD_MODE=$(BUILD_MODE)
PREFIX                 ?= /usr
GPRDIR                 ?= $(PREFIX)/share/gpr
LIBDIR                 ?= $(PREFIX)/lib
BINDIR                 ?= $(PREFIX)/bin
INSTALL_PROJECT_DIR    ?= $(DESTDIR)$(GPRDIR)
INSTALL_INCLUDE_DIR    ?= $(DESTDIR)$(PREFIX)/include/markdown
INSTALL_EXEC_DIR       ?= $(DESTDIR)$(BINDIR)
INSTALL_LIBRARY_DIR    ?= $(DESTDIR)$(LIBDIR)
INSTALL_ALI_DIR        ?= $(INSTALL_LIBRARY_DIR)/markdown

GPRINSTALL_FLAGS = --prefix=$(PREFIX) --exec-subdir=$(INSTALL_EXEC_DIR)\
 --lib-subdir=$(INSTALL_ALI_DIR) --project-subdir=$(INSTALL_PROJECT_DIR)\
 --link-lib-subdir=$(INSTALL_LIBRARY_DIR) --sources-subdir=$(INSTALL_INCLUDE_DIR)


.PHONY: spellcheck check

all:
	gprbuild $(GPRBUILD_FLAGS) gnat/markdown.gpr -cargs $(ADAFLAGS)

install:
	gprinstall $(GPRINSTALL_FLAGS) -p -P gnat/markdown.gpr

build_tests: all
	gprbuild $(GPRBUILD_FLAGS) -aP gnat -P gnat/tests/commonmark_tests.gpr

check: build_tests check_markdown

check_markdown: commonmark-spec
	cd commonmark-spec; python3 test/spec_tests.py --program ../.objs/static/tests/commonmark_tests |\
	  grep -E "^Example|^[0-9]+.passed" |\
	  tee markdown_tests_result | tail
	diff -u testsuite/commonmark/xfails.txt commonmark-spec/markdown_tests_result

commonmark-spec:
	@echo Checkout commonmark repo with:
	@echo git clone --depth=1 https://github.com/commonmark/commonmark-spec
	@false

coverage:
	find .objs/ -name *.o | xargs -s 512 gcov || true

spellcheck:
	@STATUS=0; \
	for J in `find source -name *.ad[sb]` README.md; do \
	  sed -e 's/#[^#]*#//g' -e "s/'\([A-Z]\)/ \1/g" $$J |   \
	  aspell list --lang=en --home-dir=.aspell --ignore-case > /tmp/spell.txt; \
	  if [ -s /tmp/spell.txt ] ; then \
	    echo "\n$$J:"; sort -u -f /tmp/spell.txt; STATUS=1; \
	  fi  \
	done; \
	if [ $$STATUS != 0 ] ; then \
	   echo "\n\nFIX SPELLING or append exceptions to .aspell/.aspell.en.pws !!!" ; \
	   exit 1 ; \
	fi
