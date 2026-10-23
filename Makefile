# GTWILL: GWEB's counterpart of Knuth's CTWILL (mini-indexes for literate Go).
#
#   make            # tangle the webs, then build bin/gtwill, bin/gtwill-refsort, bin/gtwill-twinx
#   make test       # go vet + go test
#   make install    # the commands into GOBIN, the TeX macros into TEXMFHOME
#   make doc        # the listings, woven by gweave and set by luatex, into build/
#   make selfdoc    # gtwill's own listing with mini-indexes, set twice, into build/
#   make clean
#
# gtwill is gweave with a change file, as CTWILL is CWEAVE with ctwill.ch: the
# master is cmd/gweave/gweave.w of the GWEB release that go.mod pins, reached
# through the symbolic link `gweb' into the module cache, and gtwill.ch changes
# it. The two utilities are webs of their own. gtangle comes from the same GWEB
# release (go.mod's `tool' line), so nothing but Go is needed to build.

GO      ?= go
BIN     ?= bin
GTANGLE := $(GO) tool gtangle
GWEAVE  ?= gweave
LUATEX  ?= luatex
TEXMF   ?= $(shell kpsewhich -var-value TEXMFHOME 2>/dev/null)
MACROS  := gtwimac.tex gtproofmac.tex gtwinxmac.tex
CMDS    := gtwill gtwill-refsort gtwill-twinx
TEXPATH := TEXINPUTS="$(CURDIR):$(CURDIR)/gweb:"

.PHONY: all build generate tangle test install uninstall doc selfdoc clean

all: build

# The link is remade whenever go.mod changes, that is, when GWEB is bumped.
gweb: go.mod
	$(GO) mod download github.com/sjnam/gweb
	ln -sfn "$$($(GO) list -m -f '{{.Dir}}' github.com/sjnam/gweb)" gweb

# gtangle names its output after the master, so gweave.go becomes gtwill.go. It
# runs in cmd/gtwill so that the //line directives point at the right files.
generate tangle: gweb
	cd cmd/gtwill && $(GTANGLE) -o . ../../gweb/cmd/gweave/gweave.w ../../gtwill.ch
	mv cmd/gtwill/gweave.go cmd/gtwill/gtwill.go
	mv cmd/gtwill/gweave_test.go cmd/gtwill/gtwill_test.go
	cd cmd/gtwill-refsort && $(GTANGLE) refsort.w
	cd cmd/gtwill-twinx && $(GTANGLE) twinx.w

build: generate
	@for c in $(CMDS); do echo "$(GO) build -o $(BIN)/$$c ./cmd/$$c"; \
		$(GO) build -o $(BIN)/$$c ./cmd/$$c || exit 1; done

test: generate
	$(GO) vet ./...
	$(GO) test ./...

install: generate
	$(GO) install ./cmd/...
	@test -n "$(TEXMF)" || { echo "no TEXMFHOME; copy $(MACROS) where TeX can find them"; exit 1; }
	mkdir -p "$(TEXMF)/tex/plain/gtwill"
	cp $(MACROS) "$(TEXMF)/tex/plain/gtwill/"
	@echo "installed $(MACROS) in $(TEXMF)/tex/plain/gtwill (gwebmac.tex comes with GWEB)"

uninstall:
	rm -rf "$(TEXMF)/tex/plain/gtwill"
	@for c in $(CMDS); do rm -f "$$($(GO) env GOPATH)/bin/$$c"; done

# The listings, woven the ordinary way: gtwill's with its changed sections starred.
doc: gweb
	mkdir -p build
	$(GWEAVE) -o build gweb/cmd/gweave/gweave.w gtwill.ch
	$(GWEAVE) -o build cmd/gtwill-refsort/refsort.w
	$(GWEAVE) -o build cmd/gtwill-twinx/twinx.w
	cd build && for j in gweave refsort twinx; do \
		$(TEXPATH) $(LUATEX) -interaction=nonstopmode $$j.tex >/dev/null; \
		echo "$$j.pdf: `grep -ac 'Overfull\|Underfull\|Error\|Missing\|Undefined' $$j.log` warnings"; done

# gtwill sets its own listing, as Knuth set CWEB's with CTWILL: one run of
# gtwill, a first TeX pass, gtwill-refsort, and the second pass.
selfdoc: build
	mkdir -p build/self
	$(BIN)/gtwill -o build/self gweb/cmd/gweave/gweave.w gtwill.ch
	cd build/self && rm -f gweave.smref && \
		$(TEXPATH) $(LUATEX) -interaction=nonstopmode gweave.tex >/dev/null && \
		../../$(BIN)/gtwill-refsort < gweave.mref > gweave.smref && \
		$(TEXPATH) $(LUATEX) -interaction=nonstopmode gweave.tex >/dev/null && \
		echo "build/self/gweave.pdf: `grep -ac 'Overfull\|Underfull\|Error\|Missing\|Undefined' gweave.log` warnings"

clean:
	rm -rf $(BIN) build
	rm -f cmd/gtwill/gtwill.go cmd/gtwill/gtwill_test.go cmd/gtwill/gweave.go cmd/gtwill/gweave_test.go
	rm -f cmd/gtwill-refsort/refsort.go cmd/gtwill-refsort/refsort_test.go
	rm -f cmd/gtwill-twinx/twinx.go cmd/gtwill-twinx/twinx_test.go
