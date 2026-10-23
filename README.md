# GTWILL — mini-indexes for literate Go

**GTWILL** is the [GWEB](https://github.com/sjnam/gweb) counterpart of Donald
Knuth's **CTWILL**, the program that typeset Knuth's own literate programs as
books — *The Stanford GraphBase*, *MMIXware*, and, through its ancestor TWILL,
*TeX: The Program* and *METAFONT: The Program*. It weaves a `.w` file exactly as
`gweave` does, but sets the pages in facing pairs and puts a **mini-index** at the
foot of every right-hand page: the identifiers that the two pages use but do not
define, each with its meaning and the section that defines it.

```text
appendChar: func( ), §53.          mem: [ ]memoryWord, §132.          printCurrentString: func( ), §85.
curLength: func( ) int32, §52.     memEnd: pointer, §134.             printLn: func( ), §69.
flushChar: func( ), §53.           memMin = 0, §13.                   printStr: func( ), §72.
hh: twoHalves, §129.               memoryWord = struct, §129.         showBox: func( ), §218.
```

| CTWILL     | GTWILL            | purpose                                              |
|------------|-------------------|------------------------------------------------------|
| `ctwill`   | `gtwill`          | weave a web with mini-index information              |
| `refsort`  | `gtwill-refsort`  | sort the mini-index entries between two TeX passes   |
| `twinx`    | `gtwill-twinx`    | merge the indexes of several programs into one       |
| `ctwimac`  | `gtwimac.tex`     | the page builder for facing pages with mini-indexes  |
| `proofmac` | `gtproofmac.tex`  | proofmode: each section followed by its entries      |
| `twinxmac` | `gtwinxmac.tex`   | the master index                                     |

Like CTWILL, which is CWEAVE with a change file (`ctwill.ch`), `gtwill` is
`gweave` with a change file: [`gtwill.ch`](gtwill.ch) applies to
`cmd/gweave/gweave.w` of the GWEB release pinned in [`go.mod`](go.mod). The user
manual is the second section of that change file, and it reads best in the woven
listing (`make doc`).

## Build and install

```sh
make            # tangle the webs, build bin/gtwill, bin/gtwill-refsort, bin/gtwill-twinx
make test       # go vet + go test
make install    # the commands into GOBIN, gtwimac/gtproofmac/gtwinxmac into TEXMFHOME
```

Only Go is needed to build: `gtangle` comes from the pinned GWEB module
(`go tool gtangle`), and the master `gweave.w` is reached through a symbolic link
`gweb` into the module cache, which `make` creates. To typeset you need GWEB's
`gwebmac.tex` on the TeX path as well (GWEB's `install.sh` puts it there), and a
TeX engine with e-TeX: `luatex` (for Korean, with `kotexgweb`) or `pdftex`.

## Usage

```sh
gtwill foo.w [foo.ch]                        # -> foo.tex, foo.aux
luatex foo                                   # first pass: -> foo.pdf, foo.mref
gtwill-refsort < foo.mref > foo.smref
luatex foo                                   # second pass: mini-indexes alphabetized
```

CTWILL had to be run twice, "once to prime the pump and once to get decent
answers"; `gtwill` primes the pump in the silent pass that `gweave` makes over the
web anyway, so one run is enough. TeX must still run twice, with the sort in
between. Delete `foo.smref` whenever the web changes: it describes pages that no
longer exist. `gtwill -P foo.w` produces proofmode output instead, in which every
section is followed by the entries it generates; check them there before the
page breaks hide them.

A web needs no change to be woven by `gtwill`; but book production with CTWILL
always involved a change file of hints, and so does it here:

| code            | meaning                                                                |
|-----------------|------------------------------------------------------------------------|
| `@$id {PROG}12 tex@>` | give `id` the meaning `tex`, defined in section 12 of program PROG |
| `@$id "pkg" tex@>`    | ... defined in the package or header `pkg`                        |
| `@%`            | toggle: the `@$`s that follow, up to the next section, are temporary   |
| `@-id@>`        | no mini-index entry for `id` in this section                           |
| `@r`            | `\shortpage` before the next section (`@r@*` inverts left and right)   |

A TeX part beginning with `=` is set after an equals sign instead of a colon, and
`\zip` makes an entry with neither. `@%` means CTWILL's toggle here, not GWEB's
comment. `gtangle` ignores all of these.

Meanings come from `system.bux`, then from the web's own declarations, then from
`foo.bux` (looked for in the output directory, the web's directory, and the
current directory). The `.aux` file that `gtwill` writes holds the web's own
definitions as `@$` lines, ready to be pasted into the `.bux` of another web that
uses them: that is how the programs of a book refer to one another.

### The master index

```sh
gtwill-twinx gbgraph.tex gbbasic.tex ... > index.tex
luatex index
```

`gtwill-twinx` reads the index that `gtwill` (or `gweave`) puts at the end of each
`.tex` file, and the title from its `\def\title{...}`, and merges them: each entry
cites the sections of each program under its title. If a file
`gtwinx-startup.tex` can be found, `gtwinxmac.tex` reads it — the place for
`\input kotexgweb`, `\def\title{...}`, and the macros that the programs' limbos
define and their index entries use.

## How the meanings are found

CTWILL reads a definition off the partly reduced scraps of CWEAVE's C grammar.
`gweave` has no grammar, only the tokens around a defined name, so `gtwill` reads
the declaration directly: a `var`, field, or parameter means its type; a `type`
means `=` and its definition, with a `struct` or `interface` body elided; a
`const` means `=` and its value when that is a literal or a short expression
(`memTop - 11`), and its type or just `const` otherwise; a function means
`func( )` and its results, a method `(*T) func( )` and its results, a label
`label`. Parameter lists and long array lengths are elided as CTWILL elides them.
Where Go leaves a type to the compiler (`n := ...`), `gtwill` guesses from the
form of the value — a literal, a composite literal, `make`, `new`, a conversion,
a function literal — and otherwise says `var`.

An identifier nobody defined is cited as `???` so that you notice it, but only if
it is an ordinary name of the program: predeclared names, imported packages, and
names selected with a dot (`fmt.Println`, `b.Len()`) are cited only when a `@$`
gives them a meaning.

## Differences from CTWILL

* One run of `gtwill` instead of two (see above); `.mref`/`.smref` instead of
  `.ref`/`.sref`, because a web may keep a `.ref` file of its own.
* The page builder measures the mini-index instead of estimating it from the
  number of entries, and tries the left-hand page's `\vsplit` before accepting a
  section, so the right-hand page never overflows. A section longer than two
  pages continues on the next spread instead of overflowing, and there is no
  limit on the number of sections in a spread.
* The index section, the index, the list of section names, and the contents are
  set as `gweave` sets them (`gtwill` writes `\twilllast` before the last starred
  section); CTWILL sets no index and leaves that to `twinx`.
* Sections touched by the change file are not starred, as in CTWILL.

## Tuning

`gtwimac.tex` keeps `gwebmac.tex`'s page size (`\pagewidth`, `\pageheight`);
the right-hand page reaches `\miniextra` (1pc) lower. The mini-index is set in
three columns `\minicolsep` apart, at `\minibase` (9pt) leading, `\minisep` below
the text; `\leftstretch` decides how readily a left-hand page ends early at a
section boundary. `\minicolon`, `\miniequals`, `\twilllabel` (label), and
`\uninitialized` (???) may be redefined, e.g. by a localization. A
decoration drawn behind every page goes in `\twillbackground`, which comes first
in each page of a spread as it would in a `\plainoutput` of your own. As
`ctwimac.tex` does, TeX reports in its log how much room each section would leave
the spread, for fine-tuning with `@r` and `\forcebr`.

## Repository layout

```text
gtwill.ch                  changes to gweave.w that make gtwill (with its manual and tests)
cmd/gtwill/                gtwill.go, tangled from gweb/cmd/gweave/gweave.w + gtwill.ch
cmd/gtwill-refsort/        refsort.w -> refsort.go
cmd/gtwill-twinx/          twinx.w   -> twinx.go
gtwimac.tex                TeX macros for gtwill's output (CTWILL's ctwimac.tex)
gtproofmac.tex             proofmode macros (CTWILL's proofmac.tex)
gtwinxmac.tex              master-index macros (CTWILL's twinxmac.tex)
gweb -> module cache       the pinned GWEB release, made by `make`
```
