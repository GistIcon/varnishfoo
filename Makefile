WEBTARGET=pathfinder.kly.no:public_html/varnishfoo.info/
C=control/
B=build

bases = $(basename $(wildcard chapter*rst appendix*rst))
CHAPTERS= $(addsuffix .rst,${bases})
HTML=${B}/index.html $(addprefix ${B}/,$(addsuffix .html,${bases}))
CHAPTERPDF= $(addprefix ${B}/,$(addsuffix .pdf, ${bases}))
TESTS= $(addprefix ${B}/,$(addsuffix .test, ${bases}))

define ok =
"\033[32m$@\033[0m"
endef

define run-rst2pdf = 
	@FOO=$$(rst2pdf -e inkscape -b2 -s ${C}/pdf.style $(firstword $^) -o $@ 2>&1); \
		ret=$$? ; \
		echo -n "$$FOO" | egrep -v 'is too.*frame.*scaling'; \
		exit $$ret
	@echo " [rst2pdf] "$(ok)
endef

web: ${B}/varnishfoo.pdf ${CHAPTERPDF} ${HTML} ${TESTS} | ${B}/css ${B}/fonts ${B}/js
	@echo " [WEB] "$(ok)

check: ${TESTS}

dist: web
	@echo " [WEB] rsync"
	@rsync --delete -L -a ${B}/ ${WEBTARGET}
	@echo " [WEB] Purge"
	@GET -d http://kly.no/purgeall

${B}:
	@mkdir -p ${B}
	@echo " [mkdir] "$(ok)

${B}/css ${B}/fonts ${B}/js: ${B}/%: bootstrap/% | ${B}
	@cp -a $< ${B}
	@echo " [cp] "$(ok)

${B}/img: $(wildcard img/*/* img/*) img | ${B}
	@cp -a img ${B}
	@touch ${B}/img
	@echo " [cp] "$(ok)

${B}/version.rst: $(wildcard *rst Makefile .git/* control/* img/* img/*/*) | ${B}
	@echo ":Version: $$(git describe --always --tags --dirty)" > ${B}/version.rst
	@echo ":Date: $$(date --iso-8601)" >> ${B}/version.rst
	@echo " [RST] "$(ok)

${B}/web-version.rst: $(wildcard *rst Makefile .git/* control/* img/* img/*/*) | ${B}
	@echo "This content was generated from source on $$(date --iso-8601)" > ${B}/web-version.rst
	@echo >> ${B}/web-version.rst
	@echo "The git revision used was \`\`$$(git describe --always --tags --dirty)\`\`" >> ${B}/web-version.rst
	@echo >> ${B}/web-version.rst
	@echo " [RST] "$(ok)

${B}/varnishfoo.rst: Makefile $(wildcard control/*rst) | $(wildcard *rst) ${B}
	@echo ".. include:: ../control/front.rst" > $@
	@echo >> $@
	@echo ".. include:: ../control/secondpage.rst" >> $@
	@echo >> $@
	@echo ".. include:: ../control/headerfooter.rst" >> $@
	@echo >> $@
	@for a in chapter-*.rst; do \
		echo ".. include:: ../$$a" >> $@ ; \
		echo >> $@ ; \
	done
	@for a in appendix-*.rst; do \
		echo ".. include:: ../$$a" >> $@ ; \
		echo >> $@ ; \
	done
	@echo " [RST] "$(ok)

${B}/varnishfoo.pdf: ${B}/varnishfoo.rst $(wildcard *rst Makefile .git/* control/* img/* img/*/*) ${B}/version.rst | ${B}
	$(run-rst2pdf)

$(addprefix ${B}/,$(addsuffix .test,${bases})): ${B}/%.test: %.rst Makefile
	@util/test.sh $< > $@
	@echo " [TEST] "$(ok)

$(addprefix ${B}/,$(addsuffix .pdf,${bases})): ${B}/%.pdf: ${B}/%.rst ${B}/img ${B}/version.rst Makefile
	$(run-rst2pdf)

$(addprefix ${B}/,$(addsuffix .rst,${bases})): ${B}/%.rst: %.rst Makefile | ${B}
	@echo "$<" | sed 's/./=/g' > $@
	@echo "$<" >> $@
	@echo "$<" | sed 's/./=/g' >> $@
	@echo >> $@
	@echo ".. include:: ../control/secondpage.rst" >> $@
	@echo >> $@
	@echo ".. include:: ../control/headerfooter.rst" >> $@
	@echo >> $@
	@echo ".. include:: ../$<" >> $@
	@echo >> $@
	@echo " [RST] "$(ok)

$(addprefix ${B}/,$(addsuffix .html,${bases})): ${B}/%.html: %.rst Makefile ${C}/template.raw | ${B}/img ${B}
	@rst2html --initial-header-level=2 --template ${C}/template.raw $< > $@
	@echo " [rst2html] "$(ok)

${B}/index.html: README.rst ${B}/web-version.rst | ${B}
	@rst2html --initial-header-level=2 --template ${C}/template.raw $< > $@
	@echo " [rst2html] "$(ok)

clean:
	-rm -rf ${B}

.PHONY: clean web dist check

.SECONDARY: $(addprefix ${B}/,$(addsuffix .rst,${base}))
