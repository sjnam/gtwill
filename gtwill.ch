Changes to gweave.w that turn GWEAVE into GTWILL, GWEB's counterpart of CTWILL.

GTWILL is to GWEAVE what Knuth's CTWILL is to CWEAVE: the same program, extended
so that every pair of facing pages gets a ``mini-index'' of the identifiers used
on it but defined elsewhere. Apply it the CWEB way:

    gtangle gweave.w gtwill.ch    (the program)
    gweave  gweave.w gtwill.ch    (its listing, the changed sections starred)

where gweave.w is cmd/gweave/gweave.w of the GWEB release pinned in go.mod.

@x limbo
\def\title{GWEAVE (Version 0.10.5)}
\def\topofcontents{\null\vfill
  \centerline{\titlefont The {\ttitlefont GWEAVE} processor}
  \vskip 15pt
  \centerline{(Version 0.10.5)}
  \vfill}
@y
\def\title{GTWILL (Version 0.10.5)}
\def\topofcontents{\null\vfill
  \centerline{\titlefont The {\ttitlefont GTWILL} processor}
  \vskip 15pt
  \centerline{(Version 0.10.5)}
  \vfill}
@z

@x section 1
@** Processor gweave.
This is the command-line front end of \.{gweave}; the weave engine it drives is
defined in the second half of this web. The input may be named with or without
its \.{.w} extension (\.{gweave wc} reads \.{wc.w}, as in \.{CWEB}). The woven document
is written to the input's base name with a \.{.tex} extension; process it with a
\TEX/ engine that can find \.{gwebmac.tex} to produce a {\sc PDF}.
@y
@** Processor gtwill.
This is \.{gtwill}, the \.{GWEB} counterpart of Knuth's \.{CTWILL}. It is
\.{gweave} with a change file, \.{gtwill.ch}, just as \.{CTWILL} is
\.{CWEAVE} with \.{ctwill.ch}; the listing you are reading is \.{gweave.w} with
that change file applied, and the sections it altered or added carry a star.
\.{CTWILL} descends in turn from \.{TWILL}, the private \.{WEB} program with
which Knuth produced Volumes B and~D of {\sl Computers \char`\&\ Typesetting\/}
in 1985, and its whole purpose is the ``mini-indexes'' of those books: at the
foot of every right-hand page, a list of the identifiers that the two facing
pages use but do not define, each with a word about what it is and where it was
defined. Knuth tells the story in ``Mini-indexes for literate programs,''
reprinted in {\sl Digital Typography\/} (1999), 225--245.

The version number parallels that of the \.{gweave} it is built from. The
input may be named with or without its \.{.w} extension, and the woven document
is written to the input's base name with a \.{.tex} extension, exactly as with
\.{gweave}; process it with a \TEX/ engine that can find \.{gtwimac.tex} (which
loads \.{gwebmac.tex}) to produce a {\sc PDF}.
@z

@x the manual goes before the entry point
@ The entry point parses the flags and arguments and dispatches to |run|. With
\.{-version} it just prints the version; otherwise it prints a one-line banner
to the standard error, in the style of \.{CWEB}, before processing.
@<The command's entry point@>=
func main() {
	outDir := flag.String("o", "", "output directory (default: input file's directory)")
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Usage = usage
	flag.Parse()
	if *showVersion {
		fmt.Printf("gweave (GWEB) %s\n", common.Version)
		return
	}
	if flag.NArg() < 1 || flag.NArg() > 2 {
		usage()
		os.Exit(2)
	}
	fmt.Fprintf(os.Stderr, "This is GWEAVE, Version %s\n", common.Version)
	if err := run(flag.Arg(0), flag.Arg(1), *outDir); err != nil {
		fmt.Fprintln(os.Stderr, "gweave:", err)
		os.Exit(1)
	}
}

@ Usage.
@<Print a usage message@>=
func usage() {
	fmt.Fprintln(os.Stderr, "usage: gweave [-o dir] file[.w] [change[.ch]]")
	flag.PrintDefaults()
}
@y
@ Here is a sort of user manual for \.{gtwill}, which follows Knuth's manual for
\.{CTWILL} closely, because the two programs work the same way; I have kept his
words where they still fit. \.{gtwill} is exactly like \.{gweave} except that it
produces much better documentation, for which you must work harder. Input comes
from a source file \.{foo.w} and from an optional (but now almost mandatory)
change file \.{foo.ch}; output goes to \.{foo.tex}. Unlike \.{gweave}, there is an
additional output file, \.{foo.aux}, which records all nonexternal definitions
in a form that other webs can read.

You must run the output twice through \TEX/. After `\.{luatex} \.{foo}' you will
have output that looks like final pages except that the entries of the
mini-indexes won't be alphabetized. \TEX/ will say `This is the first pass', and
it will produce a weird file called \.{foo.mref}. Say
$$\.{gtwill-refsort < foo.mref > foo.smref}$$
and then another `\.{luatex} \.{foo}' will produce alphabetized output. (\.{CTWILL}
calls these files \.{.ref} and \.{.sref}; \.{gtwill} adds an \.{m}, because a
web is apt to keep a \.{.ref} file of its own.) Should you change the web
afterwards, delete \.{foo.smref} and start over; it describes pages that no
longer exist.

The mini-indexes list identifiers that are used but not defined on each
two-page spread. At the end of each section, \.{gtwill} gives \TEX/ a list of
identifiers used in that section and information about where they are defined.
The macros in \.{gtwimac.tex} figure out which identifiers should go in each
mini-index, based on how the pages break. (Yes, those macros are pretty hairy.)

@ The information that \.{gtwill} concocts from \.{foo.w} is not always correct.
Sometimes you'll use an identifier that you don't want indexed; for example, your
exposition might talk about |f(x)| when you don't mean to refer to program
variables |f| or |x|. Sometimes you'll use an identifier that's defined in
another web, unknown to \.{gtwill}. Sometimes you'll define a single identifier
in several different places, and \.{gtwill} won't know which definition to
choose. But all is not lost. \.{gtwill} guesses right most of the time, and you
can give it the necessary hints in other places via your change file.

\.{gtwill} uses a very simple method to generate mini-index info. Every
identifier has a current ``meaning,'' consisting of its abstract type and the
number of the section in which it was most recently defined. For example, if
your \GO/ program says `|var s []byte|' in section~3, the meaning of~|s| gets
changed to `|[]byte|, \S3' while \.{gtwill} is processing that section. If you
refer to~|s| in section~10, and if |s|~hasn't been redefined in the meantime, and
if section~10 doesn't wind up on the same two-page spread as section~3, the
mini-index generated by section~10 will say ``|s|: |[]byte|, \S3.''

\CEE/ spells a declaration's type for all to see; \GO/ often leaves it to the
compiler, as in |n := len(s)|, and \.{gtwill} is no compiler. It reads the type
off the declaration when the declaration states one, and otherwise makes an
educated guess from the initial value---a literal, a composite literal, a call
of |make| or |new|, a conversion, a function literal---falling back to a plain
\&{var} when it has no idea. A function's meaning is its signature with the
parameters elided, |func|$(\,)$ followed by the results; a type's is `$=$'
followed by its definition, with the body of a |struct| or |interface| elided;
a constant's is `$=$' followed by its value, when that value is a literal
or a short expression.

@ The current meaning of every identifier is initially `\.{\\uninitialized}'.
Then \.{gtwill} reads the file \.{system.bux}, if there is one; then the
definitions that the web itself makes, as \.{CTWILL} would read them from the
\.{.aux} file of its previous run; then \.{foo.bux}. If all identifiers have a
unique definition, they will have a unique and appropriate meaning in the
mini-indexes. \.{CTWILL} had to be run twice, ``once to prime the pump and once
to get decent answers.'' Since \.{gweave} already makes a silent pass over the
whole web before the pass that writes the output, \.{gtwill} primes the pump in
that first pass, and a single run gives the decent answers.

But some identifiers, like parameters to functions, may be defined several
times. Others may not be defined at all, because they are defined elsewhere,
in another web or in another \GO/ package. To solve this problem, \.{gtwill}
provides mechanisms by which the current meaning of an identifier can be
temporarily or permanently changed. For example, the operation
$$\.{@@\$s \{FOO\}3 \\KW\{int\}@@>}$$
changes the current meaning of |s| to the \TEX/ output of `\.{\\KW\{int\}}' in
section~3 of program {\sc FOO}. All entries in the \.{.aux} file are expressed in
the form of this \.{@@\$} operator; therefore you can use a text editor to paste
such entries into a \.{.ch} file, whenever you want to tell \.{gtwill} about
definitions that are out of order or from other programs. The general convention
is to put the definitions of library functions into \.{system.bux}, and to put
the definitions found in the specifically foo-ish packages that \.{foo.w} imports
into \.{foo.bux}. Like the \.{.aux} files, \.{.bux} files should contain only
\.{@@\$} specifications; this rule corresponds to the fact that `bux' is the
plural of `\$'. The \.{.bux} files may also contain \.{@@i} includes. They are
looked for in the output directory, in the web's own directory, and in the
current directory, in that order.

@ A companion operation \.{@@\%} signifies that all \.{@@\$} specifications from
the present point to the beginning of the next section will define {\it
temporary\/} meanings instead of permanent ones. Temporary meanings are placed
into the mini-index of the current section; the permanent (current) meaning of
the identifier will not be changed, nor will it appear in the mini-index of the
section. If several temporary meanings are assigned to the same identifier in a
section, all will appear in the mini-index. Each \.{@@\%} toggles the
temporary/permanent convention; thus, after an even number of \.{@@\%}
operations in a section, meanings specified by \.{@@\$} are permanent. (In
\.{gweave} and \.{gtangle}, \.{@@\%} begins a comment that runs to the end of the
line; \.{gtwill} gives it \.{CTWILL}'s meaning instead.)

The operation \.{@@-} followed by an identifier followed by \.{@@>} specifies
that the identifier should not generate a mini-index entry in the current
section (unless, of course, a temporary meaning is assigned). If \.{@@-foo@@>}
appears in a section where a new permanent meaning is later defined by the
semantics of \GO/, the current meaning of |foo| will not be redefined; moreover,
this current meaning, which may have been changed by \.{@@\$foo ...@@>}, will
also be written to the \.{.aux} file. Therefore you can control what \.{gtwill}
outputs; you can keep it from repeatedly contaminating the \.{.aux} file with
things you don't like.

@ The meaning specified by \.{@@\$...@@>} generally has four components: an
identifier (followed by space), a program name (enclosed in braces), a section
number (followed by space), and a \TEX/ part. If the \TEX/ part starts with
`\.=', the mini-index entry will contain an equals sign instead of a colon; for
example,
$$\.{@@\$bufSize \{PROG\}10 =\\NU\{200\}@@>}$$
generates either `$\\{bufSize}=200$, \S10' or `$\\{bufSize}=200$, {\sc PROG}\S10',
depending on whether `{\sc PROG}' is or isn't the title of the current program.
If the \TEX/ part is `\.{\\zip}', the mini-index entry will contain neither colon
nor equals, just a comma. The program name and section number can also be
replaced by a string. For example,
$$\.{@@\$Println "fmt" \\zip@@>}$$
will generate a mini-index entry like `\\{Println}, \.{fmt}.'. The title of the
current program is what its limbo gives to \.{\\def\\title}; failing that, it is
the base name of the output file.

\.{gtwill} keeps quiet about what it cannot know. An identifier whose current
meaning is still \.{\\uninitialized} goes into a mini-index---as `???', so that
you notice it---only if it is an ordinary name of the program: not a predeclared
type or function like |int| or |len|, not the name of an imported package, and
not a name selected with a dot, like the |Println| of |fmt.Println| or the
|Len| of |b.Len()|, which belong to some other package. Give such a name a
meaning with \.{@@\$} and it will be cited like any other.

@ A special ``proofmode'' is provided so that you can check \.{gtwill}'s
conclusions about cross-references. Run \.{gtwill} with the flag \.{-P}, and
\TEX/ will produce a specially formatted document ({\it without\/} mini-indexes)
in which you can check that your specifications are correct. You should always
do this before generating mini-indexes, because mini-indexes can mask errors if
page breaks are favorable but the errors might reveal themselves later after your
program has changed. The proofmode output is much easier to check than the
mini-indexes themselves.

The control code \.{@@r} or \.{@@R} causes \.{gtwill} to emit the \TEX/ macro
`\.{\\shortpage}' just before starting the next section of the program. This
causes the section to appear at the top of a right-hand page, if it would
ordinarily have appeared near the bottom of a left-hand page and split across
the pages. (The \.{\\shortpage} macro is fragile and should be used only in cases
where it will not mess up the output; insert it only when fine-tuning a set of
pages.) If the next section is a starred section, the behavior is slightly
different (but still fragile): The starred section will either be postponed to a
left-hand page, if it normally would begin on a right-hand page, or vice versa.
In other words, \.{@@r@@*} inverts the left/right logic.

\.{gtangle} does not recognize the operations \.{@@\$}, \.{@@-}, and \.{@@r},
which are unique to \.{gtwill}; it skips them. But that is no problem, since you
use them only in change files set up for book publishing, which are quite
different from the change files you set up for tangling. And since such a change
file is in the nature of things a big one, \.{gtwill} does not star the sections
it touches, nor list them before the index, as \.{gweave} does.

The last section of a web, if it is starred, is the \.{@@* Index.} section,
under which \.{gweave} sets the index. \.{gtwill} writes \.{\\twilllast} before
it, and \.{gtwimac.tex} then ships the last spread and goes back to
\.{gwebmac}'s ordinary pages for the rest: the index section, the index, the
list of section names, and the table of contents. (\.{CTWILL} sets no index at
all; Knuth gathered the indexes of a book's programs into one with \.{twinx},
and \.{gtwill-twinx} does the same for \.{gtwill}'s.)

(End of user manual. We now resume the program for \.{gweave}, with occasional
outbursts of new code.)

@ The entry point parses the flags and arguments and dispatches to |run|. With
\.{-version} it just prints the version; otherwise it prints a one-line banner
to the standard error, in the style of \.{CWEB}, before processing. The flag
\.{-P} asks for proofmode.
@<The command's entry point@>=
func main() {
	outDir := flag.String("o", "", "output directory (default: input file's directory)")
	proof := flag.Bool("P", false, "proofmode: \\input gtproofmac instead of gtwimac")
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Usage = usage
	flag.Parse()
	if *showVersion {
		fmt.Printf("gtwill (GWEB) %s\n", common.Version)
		return
	}
	if flag.NArg() < 1 || flag.NArg() > 2 {
		usage()
		os.Exit(2)
	}
	fmt.Fprintf(os.Stderr, "This is GTWILL, Version %s\n", common.Version)
	if err := run(flag.Arg(0), flag.Arg(1), *outDir, *proof); err != nil {
		fmt.Fprintln(os.Stderr, "gtwill:", err)
		os.Exit(1)
	}
}

@ Usage.
@<Print a usage message@>=
func usage() {
	fmt.Fprintln(os.Stderr, "usage: gtwill [-P] [-o dir] file[.w] [change[.ch]]")
	flag.PrintDefaults()
}
@z

@x run
@ |run| supplies the default \.{.w} (and \.{.ch}) extension, parses the web
(applying a change file if given), prints any warnings and a short progress
report, and writes the woven \TEX/.
@<Weave the web and write the \TEX/@>=
func run(input, changeFile, outDir string) error {
	input = common.DefaultExt(input, ".w")
	changeFile = common.DefaultExt(changeFile, ".ch")
	w, err := common.ParseWithChange(input, changeFile)
	if err != nil {
		return err
	}
	for _, warn := range w.Warnings {
		fmt.Fprintln(os.Stderr, "gweave: warning:", warn)
	}
	reportProgress(w)
	if outDir == "" {
		outDir = filepath.Dir(input)
	}
	base := filepath.Base(input)
	base = strings.TrimSuffix(base, filepath.Ext(base))
	outPath := filepath.Join(outDir, base+".tex")

	f, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer f.Close()

	if err := New(w).Weave(f); err != nil {
		return err
	}
	fmt.Printf("gweave: wrote %s\n", outPath)
	return nil
}
@y
@ |run| supplies the default \.{.w} (and \.{.ch}) extension, parses the web
(applying a change file if given), prints any warnings and a short progress
report, and writes the woven \TEX/ and the \.{.aux} file. Before weaving it tells
the mini-index machinery whether we are in proofmode, the job's name (the
default title, and the stem of \.{foo.bux}), and where to look for the
\.{.bux} files.
@<Weave the web and write the \TEX/@>=
func run(input, changeFile, outDir string, proof bool) error {
	input = common.DefaultExt(input, ".w")
	changeFile = common.DefaultExt(changeFile, ".ch")
	w, err := common.ParseWithChange(input, changeFile)
	if err != nil {
		return err
	}
	for _, warn := range w.Warnings {
		fmt.Fprintln(os.Stderr, "gtwill: warning:", warn)
	}
	reportProgress(w)
	@<Forget which sections the change file touched@>
	if outDir == "" {
		outDir = filepath.Dir(input)
	}
	base := filepath.Base(input)
	base = strings.TrimSuffix(base, filepath.Ext(base))
	outPath := filepath.Join(outDir, base+".tex")

	f, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer f.Close()

	wv := New(w)
	wv.tw.proof = proof
	wv.tw.job = base
	wv.tw.dirs = []string{outDir, filepath.Dir(input), "."}
	if err := wv.Weave(f); err != nil {
		return err
	}
	fmt.Printf("gtwill: wrote %s\n", outPath)
	@<Write the \.{.aux} file@>
	return nil
}

@ \.{CTWILL} does not mark the sections that a change file has touched: its
change file is the one that sets the book up, and it touches nearly everything.
We follow suit by forgetting the marks that the parser has made, before anyone
looks at them.
@<Forget which sections the change file touched@>=
for _, s := range w.Sections {
	s.Changed = false
}

@ Every new meaning that the program's own declarations gave to an identifier
goes into \.{foo.aux}, one \.{@@\$} operation per line, as \.{CTWILL} writes them.
An at-sign inside the operation is doubled, as everywhere in a web.
@<Write the \.{.aux} file@>=
var aux strings.Builder
for _, ln := range wv.tw.aux {
	aux.WriteString("@@$" + strings.ReplaceAll(ln, "@@", "@@@@") + "@@>\n")
}
auxPath := filepath.Join(outDir, base+".aux")
if err := os.WriteFile(auxPath, []byte(aux.String()), 0o644); err != nil {
	return err
}
@z

@x the weave engine's skeleton
@<Track structural indentation@>
@y
@<Track structural indentation@>
@<The mini-index machinery@>
@z

@x the weaver's state
	xr *xref // identifier and section cross-references (built lazily)
}
@y
	xr *xref // identifier and section cross-references (built lazily)

	tw *twill // the mini-index machinery
}
@z

@x New
	@<Number the refinements and file outputs@>
@y
	@<Prepare the mini-index state@>
	@<Number the refinements and file outputs@>
@z

@x Weave
func (wv *Weaver) Weave(out io.Writer) error {
	wv.xr = newXref()
	@<Flag the index section if the change file touched anything@>
	scan := bufio.NewWriter(io.Discard)
	for _, sec := range wv.w.Sections {
		wv.writeSection(scan, sec)
	}

	bw := bufio.NewWriter(out)
	bw.WriteString("\\input gwebmac\n")
@y
func (wv *Weaver) Weave(out io.Writer) error {
	wv.xr = newXref()
	@<Flag the index section if the change file touched anything@>
	wv.tw.beginPass(1, nil)
	scan := bufio.NewWriter(io.Discard)
	for _, sec := range wv.w.Sections {
		wv.writeSection(scan, sec)
	}

	wv.tw.beginPass(2, wv.tw.aux)
	bw := bufio.NewWriter(out)
	if wv.tw.proof {
		bw.WriteString("\\input gtproofmac\n")
	} else {
		bw.WriteString("\\input gtwimac\n")
	}
@z

@x writeSection
func (wv *Weaver) writeSection(bw *bufio.Writer, sec *common.Section) {
	@<Write the section headline and commentary@>
	if sec.HasCode {
		@<Write the section's code part@>
	}
	bw.WriteString("\n\\fi\n") // close the on-conditional the section headline opens
}
@y
func (wv *Weaver) writeSection(bw *bufio.Writer, sec *common.Section) {
	@<Begin the section's mini-index bookkeeping@>
	@<Write the section headline and commentary@>
	if sec.HasCode {
		@<Write the section's code part@>
	}
	@<Write the section's mini-index entries@>
}
@z

@x the headline
if sec.Changed {
	mac += "s"
}
@y
if sec.Changed {
	mac += "s"
}
if rightStart { // an \.{@@r} in the previous section
	if sec.Starred {
		mac = "NN" // invert the left/right logic
	} else {
		bw.WriteString("\n\\shortpage")
	}
}
if sec.Starred && sec.Number == len(wv.w.Sections) {
	bw.WriteString("\n\\twilllast") // the index section gets ordinary pages
}
@z

@x the code part is also lexed whole, for the mini-indexes
	for _, a := range common.ScanCode(code) {
		@<Render one code atom@>
	}
	flushLine()
	return out.String()
}
@y
	@<Lex the whole code part, for the mini-indexes@>
	for ai, a := range atoms {
		base := offs[ai] // where the atom's tokens begin in |whole|
		@<Render one code atom@>
	}
	flushLine()
	return out.String()
}

@ A control code splits a code part into atoms, and |renderCode| lexes the
atoms one by one; but a declaration must be seen whole, across them, if
\.{gtwill} is to read a meaning off it: in \.{type @@!pointer = halfword} the
\.{@@!} leaves |type| in one atom and the name in the next. So the mini-index
machinery is handed the tokens of the whole code part, |whole|, lexed as
|scanAllCode| lexes them for the detectors, and the atom at index |ai| begins at
|offs[ai]| in it: its text gives the same tokens that |renderCode| sees, and a
reference, a \.{@@t} box, or verbatim material is a stand-in operand.
@<Lex the whole code part, for the mini-indexes@>=
atoms := common.ScanCode(code)
var whole []token
offs := make([]int, len(atoms))
var wst lexState
for i, a := range atoms {
	offs[i] = len(whole)
	switch a.Kind {
	case common.AText:
		whole = append(whole, lexGo(a.Text, &wst)...)
	case common.ARef, common.ATeX, common.AVerbatim:
		whole = append(whole, token{kind: tkString}) // a stand-in operand
	}
}
@z

@x recording a code token
		if k, ok := wv.lookupFormat(t.text, qual); ok {
			wv.xr.noteHead(t.text, k) // so a qualified type's head is bold too
		}
	}
}

@ A comment goes through |renderComment|, everything else through |renderToken| in
@y
		if k, ok := wv.lookupFormat(t.text, qual); ok {
			wv.xr.noteHead(t.text, k) // so a qualified type's head is bold too
		}
	}
	wv.twillNote(t, def, prevSigKind == tkOp && prevSigText == ".", whole, base+k)
}

@ A comment goes through |renderComment|, everything else through |renderToken| in
@z

@x recording an inline token
		if k, ok := wv.lookupFormat(t.text, qual); ok {
			wv.xr.noteHead(t.text, k) // so a qualified type's head is bold too
		}
	}
}
emit(curCat, renderToken(structTagged(token{kind: wv.effKind(t, qual), text: t.text}, prevSigKind, prevSigText)))
@y
		if k, ok := wv.lookupFormat(t.text, qual); ok {
			wv.xr.noteHead(t.text, k) // so a qualified type's head is bold too
		}
	}
	if record {
		wv.twillNote(t, def, prevSigKind == tkOp && prevSigText == ".", toks, k)
	}
}
emit(curCat, renderToken(structTagged(token{kind: wv.effKind(t, qual), text: t.text}, prevSigKind, prevSigText)))
@z

@x the index head
head := func(name string) string {
	kind, ok := wv.xr.identHead[name]
	if !ok {
		kind = wv.format[name]
	}
	switch kind {
	case tkMacro:
		return "\\MAC{" + escTT(name) + "}"
	case tkTeXCS:
		return "$\\" + texControlSeq(name) + "$" // its macro assumes math mode
	case tkBuiltin:
		return "\\KW{" + escIdent(name) + "}" // a defined type: bold, as cweave's \&
	}
	return "\\ID{" + escIdent(name) + "}"
}
@y
head := wv.indexHead // a mini-index entry heads its name the same way
@z

@x the new part goes before the tests
@* Tests.
The weave engine's tests, one section per case. %'
@y
@* Mini-indexes.
Here at last is the machinery that turns \.{gweave} into \.{gtwill}. \.{CTWILL}
grafted its data structures onto \.{CWEAVE} ``without major surgery,'' and I have
tried to do the same: \.{gweave} calls into this part at a handful of places---%
when a pass begins, when a section begins and ends, and whenever it records an
identifier in the index---and everything else happens here.
@<The mini-index machinery@>=
@<The mini-index types@>
@<The mini-index functions@>

@ A |meaning| is what a mini-index says about an identifier: in which program
(or header, or package) and in which section it was defined, and the \TEX/ that
describes it. The program is a number, an index into |twill.titles|; number~0 is
the program being woven, whose meanings cite a bare section number. Each
identifier has a |permMeaning|, its current ``permanent'' meaning, together with
the |stamp| of the last section in which an \.{@@-} or a temporary meaning
suppressed its output, and the flag |used| that keeps it from being listed twice
in a section's citations.
@<The mini-index types@>=
type meaning struct {
	id   string // the identifier this meaning belongs to
	prog int    // the program or header that defines it; 0 is this one
	sec  int    // the section of the definition, when |prog| names a program
	tex  string // the \TEX/ part
}

type permMeaning struct {
	perm  meaning
	stamp int  // the last section in which output was suppressed
	used  bool // already cited by the current section?
}

const (
	uninitialized  = "\\uninitialized" // the meaning of an identifier nobody defined
	notADefinition = "-"               // |guessMeaning|'s verdict on a false definition
)

@ A section's \.{@@\$}, \.{@@-}, \.{@@\%}, and \.{@@r} operations are taken out of its
text before \.{gweave} sees it, and kept as |twillOp|s, in the order of their
appearance, to be carried out when the section is woven.
@<The mini-index types@>=
type twillOp struct {
	code byte   // \.\$, \.-, \.\%, or \.r
	text string // the control text of \.{@@\$} or \.{@@-}
}

@ The |twill| record holds the rest of the state. The meanings, the citations, and
the switches start afresh with each pass (|beginPass|); the operations, the
titles, and the package names are gathered once, when the |Weaver| is made.
@<The mini-index types@>=
type twill struct {
	proof bool     // \.{-P}: \.{\\input gtproofmac} instead of \.{gtwimac}
	job   string   // the output's base name: the default title, the stem of \.{foo.bux}
	dirs  []string // where to look for the \.{.bux} files
	pass  int      // 1 while \.{gweave} scans silently, 2 while it writes

	titles []string                // program and header names, with their delimiters
	cur    map[string]*permMeaning // the current meanings
	usage  []*permMeaning          // the meanings the current section cites, in order
	temp   []meaning               // the current section's temporary meanings
	sec    int                     // the section being woven

	tempSwitch bool // has an odd number of \.{@@\%} occurred in this section?
	rightStart bool // has an \.{@@r} occurred since the last section began?

	ops  map[int][]twillOp // each section's operations
	pkgs map[string]bool   // the package names the program's imports bring in
	aux  []string          // this pass's new meanings, as \.{@@\$} control texts
}

@ The predeclared functions are \GO/'s counterpart of the \CEE/ library: the
lexer takes them for ordinary identifiers, and \.{gweave} indexes them, as
\.{cweave} indexes |printf|. Nobody defines them, so without a meaning they would
crowd every mini-index with `???'. They are cited only when they have been
given a meaning.
@<The mini-index types@>=
var predeclaredFuncs = map[string]bool{
	"append": true, "cap": true, "clear": true, "close": true, "complex": true,
	"copy": true, "delete": true, "imag": true, "len": true, "make": true,
	"max": true, "min": true, "new": true, "panic": true, "print": true,
	"println": true, "real": true, "recover": true,
}

@ When the |Weaver| is made, each section gives up its operations, the program's
title is looked for, and the imported package names are noted.
@<Prepare the mini-index state@>=
wv.tw = &twill{ops: map[int][]twillOp{}, pkgs: map[string]bool{}}
for _, s := range w.Sections {
	var ops, more []twillOp
	s.Tex, ops = extractTwillOps(s.Tex)
	s.Code, more = extractTwillOps(s.Code)
	wv.tw.ops[s.Number] = append(ops, more...)
}
@<Find the program's title in the limbo@>
@<Note the package names that the imports bring in@>

@ |extractTwillOps| removes the operations from a section's commentary or code,
returning what is left and the operations themselves. A doubled \.{@@@@} is an
at-sign and is left alone, as is every other control code. An operation is
written in a line by itself as often as not, so when its removal leaves its line
blank the line goes too, by the rule that \.{gweave} applies to an index entry
(see |closeUpBlankedLine|): in commentary a blank line would end the paragraph.
@<The mini-index functions@>=
func extractTwillOps(s string) (string, []twillOp) {
	var b strings.Builder
	var ops []twillOp
	for i := 0; i < len(s); {
		if s[i] != '@@' || i+1 == len(s) {
			b.WriteByte(s[i])
			i++
			continue
		}
		switch d := s[i+1]; d {
		case '$', '-':
			end := strings.Index(s[i+2:], "@@>")
			if end < 0 {
				b.WriteString(s[i:]) // unterminated: leave it for the reader to see
				return b.String(), ops
			}
			ops = append(ops, twillOp{code: d, text: s[i+2 : i+2+end]})
			i = closeUpBlankedLine(b.String(), s, i+2+end+2)
		case '%', 'r', 'R':
			ops = append(ops, twillOp{code: d | 0x20}) // \.R is \.r
			i = closeUpBlankedLine(b.String(), s, i+2)
		default:
			b.WriteString(s[i : i+2])
			i += 2
		}
	}
	return b.String(), ops
}

@ The program's title is the argument of the first \.{\\def\\title} that begins
a line of the limbo, as in \.{CTWILL}, and becomes title number~0. If there is
none, |beginPass| makes one from the job's name.
@<Find the program's title in the limbo@>=
for _, ln := range strings.Split(w.Limbo, "\n") {
	rest, ok := strings.CutPrefix(ln, "\\def\\title{")
	if !ok {
		continue
	}
	for i, depth := 0, 1; i < len(rest); i++ {
		if rest[i] == '{' {
			depth++
		} else if rest[i] == '}' {
			if depth--; depth == 0 {
				wv.tw.title("{" + rest[:i] + "}")
				break
			}
		}
	}
	break
}

@ An import brings in the last element of its path, or the name written before
the path. Each spec of an |import| holds just one string, so every string in
the declaration is a path.
@<Note the package names that the imports bring in@>=
wv.scanAllCode(func(toks []token) {
	for i := range toks {
		if toks[i].kind != tkKeyword || toks[i].text != "import" {
			continue
		}
		j := nextSignificant(toks, i+1)
		if j < 0 {
			return
		}
		end := j + 1
		if toks[j].kind == tkOp && toks[j].text == "(" {
			if end = closerOf(toks, j); end < 0 {
				end = len(toks)
			}
		} else if toks[j].kind == tkIdent {
			end = nextSignificant(toks, j+1) + 1
		}
		for k := j; k < end && k < len(toks); k++ {
			if toks[k].kind != tkString {
				continue
			}
			name := strings.Trim(toks[k].text, "\"`")
			name = name[strings.LastIndexByte(name, '/')+1:]
			if p := prevSignificant(toks, k); p >= 0 && toks[p].kind == tkIdent {
				name = toks[p].text
			}
			wv.tw.pkgs[name] = true
		}
	}
})

@ |title| converts a program title, delimited by braces or doublequotes, into its
number, giving a new title the next number. It is \.{CTWILL}'s |title_lookup|.
@<The mini-index functions@>=
func (tw *twill) title(t string) int {
	for i, s := range tw.titles {
		if s == t {
			return i
		}
	}
	tw.titles = append(tw.titles, t)
	return len(tw.titles) - 1
}

@ |meaningOf| finds the current meaning of an identifier, which is
\.{\\uninitialized} until somebody says otherwise.
@<The mini-index functions@>=
func (tw *twill) meaningOf(id string) *permMeaning {
	q := tw.cur[id]
	if q == nil {
		q = &permMeaning{perm: meaning{id: id, tex: uninitialized}}
		tw.cur[id] = q
	}
	return q
}

@ Complaints are made in the second pass only, so that each is made once.
@<The mini-index functions@>=
func (tw *twill) warn(format string, args ...any) {
	if tw.pass == 2 {
		fmt.Fprintf(os.Stderr, "gtwill: warning: "+format+"\n", args...)
	}
}

@ |beginPass| starts a pass with every meaning uninitialized, and then reads the
meanings in \.{CTWILL}'s order: \.{system.bux} first, then the program's own
definitions, then \.{foo.bux}, so that a later file overrides an earlier one. The
program's own definitions are the |primed| control texts that the first pass
collected; the first pass itself has none, as \.{CTWILL} has no \.{.aux} file on
its first run.
@<The mini-index functions@>=
func (tw *twill) beginPass(pass int, primed []string) {
	tw.pass = pass
	tw.cur = map[string]*permMeaning{}
	tw.usage, tw.temp, tw.aux = nil, nil, nil
	tw.tempSwitch, tw.rightStart, tw.sec = false, false, 0
	if len(tw.titles) == 0 {
		tw.title("{" + tw.job + "}")
	}
	tw.readBux(tw.find("system.bux"))
	for _, text := range primed {
		if err := tw.digest(text); err != nil {
			tw.warn("%v: @@$%s@@>", err, text)
		}
	}
	if tw.job != "" {
		tw.readBux(tw.find(tw.job + ".bux"))
	}
}

@ |find| looks for a \.{.bux} file in the directories |run| named and returns its
path, or |""| if there is no such file; not having one is perfectly normal.
@<The mini-index functions@>=
func (tw *twill) find(name string) string {
	for _, d := range tw.dirs {
		p := filepath.Join(d, name)
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	return ""
}

@ |readBux| digests the \.{@@\$} operations of a \.{.bux} file, following its
\.{@@i} includes, which are relative to the including file. Blank lines and \TEX/
comments may separate the operations; anything else gets a complaint.
@<The mini-index functions@>=
func (tw *twill) readBux(name string) {
	if name == "" {
		return
	}
	data, err := os.ReadFile(name)
	if err != nil {
		tw.warn("%v", err)
		return
	}
	s := string(data)
	for i := 0; i < len(s); {
		at := fmt.Sprintf("%s:%d", name, strings.Count(s[:i], "\n")+1)
		switch {
		case s[i] == ' ' || s[i] == '\t' || s[i] == '\r' || s[i] == '\n':
			i++
		@<Digest an \.{@@\$} operation of a \.{.bux} file@>
		@<Read the file that an \.{@@i} in a \.{.bux} file names@>
		default:
			if s[i] != '%' {
				tw.warn("%s: only @@$ is allowed in aux and bux files", at)
			}
			for i < len(s) && s[i] != '\n' {
				i++
			}
		}
	}
}

@ @<Digest an \.{@@\$} operation of a \.{.bux} file@>=
case strings.HasPrefix(s[i:], "@@$"):
	end := strings.Index(s[i+2:], "@@>")
	if end < 0 {
		tw.warn("%s: unterminated @@$", at)
		return
	}
	text := strings.ReplaceAll(s[i+2:i+2+end], "@@@@", "@@")
	if err := tw.digest(text); err != nil {
		tw.warn("%s: %v", at, err)
	}
	i += 2 + end + 2

@ @<Read the file that an \.{@@i} in a \.{.bux} file names@>=
case strings.HasPrefix(s[i:], "@@i"):
	j := strings.IndexByte(s[i:], '\n')
	if j < 0 {
		j = len(s) - i
	}
	f := strings.Trim(strings.TrimSpace(s[i+2:i+j]), "\"")
	tw.readBux(filepath.Join(filepath.Dir(name), f))
	i += j

@ |digest| carries out an \.{@@\$} operation, given its control text: an
identifier, a space, a location, a space, and the \TEX/ part. The location is a
title in braces followed by a section number, or a string in doublequotes; the
new meaning goes onto the temporary stack after an odd number of \.{@@\%}, and
becomes the identifier's permanent meaning otherwise.
@<The mini-index functions@>=
func (tw *twill) digest(text string) error {
	text = strings.TrimLeft(text, " \t\r\n")
	sp := strings.IndexAny(text, " \t\r\n")
	if sp <= 0 {
		return fmt.Errorf("identifier in meaning should be followed by space")
	}
	m := meaning{id: text[:sp]}
	rest := text[sp+1:]
	@<Read the location of |m| from the front of |rest|@>
	m.tex = strings.TrimSpace(rest)
	if tw.tempSwitch {
		tw.temp = append(tw.temp, m)
	} else {
		tw.meaningOf(m.id).perm = m
	}
	return nil
}

@ A doublequoted title may contain an escaped doublequote, and a braced one may
contain braces of its own, as long as they balance.
@<Read the location of |m| from the front of |rest|@>=
end := -1
switch {
case strings.HasPrefix(rest, "\""):
	for i := 1; i < len(rest) && end < 0; i++ {
		if rest[i] == '\\' {
			i++
		} else if rest[i] == '"' {
			end = i + 1
		}
	}
case strings.HasPrefix(rest, "{"):
	for i, depth := 0, 0; i < len(rest) && end < 0; i++ {
		if rest[i] == '{' {
			depth++
		} else if rest[i] == '}' {
			if depth--; depth == 0 {
				end = i + 1
			}
		}
	}
default:
	return fmt.Errorf("title should be enclosed in braces or doublequotes")
}
if end < 0 {
	return fmt.Errorf("title name didn't end")
}
m.prog = tw.title(rest[:end])
j := end
for rest[0] == '{' && j < len(rest) && rest[j] >= '0' && rest[j] <= '9' {
	m.sec = 10*m.sec + int(rest[j]-'0')
	j++
}
if j >= len(rest) || (rest[j] != ' ' && rest[j] != '\t') {
	return fmt.Errorf("location in meaning should be followed by space")
}
rest = rest[j+1:]

@*1 Weaving a section with mini-index entries.
When a section begins, its temporary meanings from last time are gone, its
\.{@@\%} switch is off, and its operations are carried out. The \.{@@r} of the
{\it previous\/} section, if any, is remembered as |rightStart| for the headline
about to be written; this section's \.{@@r} is for the next one.
@<Begin the section's mini-index bookkeeping@>=
tw := wv.tw
tw.sec = sec.Number
tw.tempSwitch, tw.temp = false, tw.temp[:0]
rightStart := tw.rightStart
tw.rightStart = false
for _, op := range tw.ops[sec.Number] {
	switch op.code {
	case '%':
		tw.tempSwitch = !tw.tempSwitch
	case 'r':
		tw.rightStart = true
	case '$':
		if err := tw.digest(op.text); err != nil {
			tw.warn("section %d: %v: @@$%s@@>", sec.Number, err, op.text)
		}
	case '-':
		if id := strings.TrimSpace(op.text); id != "" {
			tw.meaningOf(id).stamp = tw.sec // this is what actually suppresses output
		}
	}
}

@ At the end of a section comes the list that \.{gtwimac.tex} needs, in place of
the \.{\\fi} that \.{gweave} writes there: \.{\\mini}, then one line per meaning
that the section cites, then \.{\}\\FI}. The temporary meanings come first, and
each of them suppresses the permanent meaning of its identifier; then come the
permanent meanings of the identifiers the section has used, in the order of
their first use, except those suppressed or defined in this very section.
@<Write the section's mini-index entries@>=
bw.WriteString("\n\\mini\n")
for _, m := range tw.temp {
	wv.outMini(bw, m)
	tw.meaningOf(m.id).stamp = tw.sec // suppress output from ``permanent'' data
}
for _, q := range tw.usage {
	if q.stamp != tw.sec {
		wv.outMini(bw, q.perm)
	}
	q.used = false
}
tw.usage = tw.usage[:0]
bw.WriteString("}\\FI\n")

@ |outMini| writes one line of a section's list. A meaning from this program cites
its section with \.{\\[}, or not at all if that section is the current one; a
meaning from elsewhere cites its title with \.{\\]}, followed by the section number
when the title is braced. Then come the identifier, set as in the index and
braced so that it makes a single argument, and the \TEX/ part, which runs to the
end of the line.
@<The mini-index functions@>=
func (wv *Weaver) outMini(bw *bufio.Writer, m meaning) {
	switch t := wv.tw.titles[m.prog]; {
	case m.prog == 0:
		if m.sec == wv.tw.sec {
			return // defined in the current section
		}
		fmt.Fprintf(bw, "\\[%d", m.sec)
	case t[0] == '{':
		fmt.Fprintf(bw, "\\]%s%d", t, m.sec)
	default:
		fmt.Fprintf(bw, "\\]%s", t)
	}
	fmt.Fprintf(bw, " {%s} %s\n", wv.indexHead(m.id), m.tex)
}

@ An identifier is set in a mini-index the way the index sets it: in typewriter
if it is a \.{@@d} name or a constant in capitals, as a control sequence of the
user's if \.{@@f} made it one, in bold if it names a type, and in italic
otherwise. The class is the one the body was set in, qualifier resolved, which
|noteHead| recorded as the tokens went by; failing that, |wv.format|.
@<The mini-index functions@>=
func (wv *Weaver) indexHead(name string) string {
	kind, ok := wv.xr.identHead[name]
	if !ok {
		kind = wv.format[name]
	}
	switch kind {
	case tkMacro:
		return "\\MAC{" + escTT(name) + "}"
	case tkTeXCS:
		return "$\\" + texControlSeq(name) + "$" // its macro assumes math mode
	case tkBuiltin:
		return "\\KW{" + escIdent(name) + "}" // a defined type: bold, as cweave's \&
	}
	return "\\ID{" + escIdent(name) + "}"
}

@ |twillNote| is called for every identifier that \.{gweave} records in the index
while it sets a code part or a \.{\|...\|} fragment, with |def| telling whether the
index records a definition and |selector| whether a dot precedes the name. A
definition gets a new meaning: what \.{gtwill} can make out of it, or else
\.{\\zip}, which at least tells where it is---a name defined in the commentary
with \.{@@!}, for one, has no declaration to read. So does the name of a method's
receiver, which the index does not count as a definition (it would be underlined
in nearly every method) but which the mini-indexes ought to explain.
Then the identifier is scheduled for citation by the current section.
@<The mini-index functions@>=
func (wv *Weaver) twillNote(t token, def, selector bool, toks []token, k int) {
	tw := wv.tw
	if t.text == "_" {
		return
	}
	if p := prevSignificant(toks, k); p >= 0 && toks[p].kind == tkKeyword && toks[p].text == "package" {
		return // the package clause names no identifier of the program
	}
	q := tw.meaningOf(t.text)
	receiver := false
	@<Set |receiver| if |toks[k]| names a method's receiver@>
	if t.kind == tkIdent && (def || receiver) {
		tex := wv.guessMeaning(toks, k)
		if tex == "" && def {
			tex = "\\zip" // defined here, as what we cannot tell
		}
		if tex != "" && tex != notADefinition {
			@<Give |q| the new meaning |tex|, and record it for the \.{.aux} file@>
		}
	}
	@<Schedule |q| for citation, unless it has no meaning and needs none@>
}

@ The receiver list of a method follows a |func| that begins its line, and the
method's name follows the list.
@<Set |receiver| if |toks[k]| names a method's receiver@>=
if p := prevSignificant(toks, k); p >= 0 && toks[p].kind == tkOp && toks[p].text == "(" {
	if f := prevSignificant(toks, p); f >= 0 && toks[f].kind == tkKeyword &&
		toks[f].text == "func" && beginsLine(toks, f) {
		if c := closerOf(toks, p); c >= 0 {
			n := nextSignificant(toks, c+1)
			receiver = n >= 0 && toks[n].kind == tkIdent
		}
	}
}

@ This is \.{CTWILL}'s |new_meaning|. An \.{@@-} for the identifier earlier in the
section keeps its current meaning as it is; either way the current meaning goes
into the \.{.aux} file.
@<Give |q| the new meaning |tex|, and record it for the \.{.aux} file@>=
if q.stamp != tw.sec {
	q.perm = meaning{id: t.text, sec: tw.sec, tex: tex}
}
loc := tw.titles[q.perm.prog]
if loc[0] == '{' {
	loc = fmt.Sprintf("%s%d", loc, q.perm.sec)
}
tw.aux = append(tw.aux, q.perm.id+" "+loc+" "+q.perm.tex)

@ An identifier that nobody has given a meaning is cited---as `???'---only if it
is an ordinary name of the program, which somebody ought to define. A
predeclared type or constant, a predeclared function, an imported package, and
a name selected with a dot, which belongs to some other package or type, are
cited only when they have a meaning. (\.{CTWILL} makes the same exception for
\CEE/'s reserved words.)
@<Schedule |q| for citation, unless it has no meaning and needs none@>=
abnormal := t.kind != tkIdent || selector || predeclaredFuncs[t.text] || tw.pkgs[t.text]
if (!abnormal || q.perm.tex != uninitialized) && !q.used {
	q.used = true
	tw.usage = append(tw.usage, q)
}

@*1 Guessing a meaning.
The trickiest part of \.{CTWILL} is the procedure |make_ministring|, which tries
to figure out a symbolic form of a definition from the \CEE/ grammar's partly
reduced scraps. \.{gweave} has no grammar to lean on, only the tokens of the
code part around the name being defined, as \.{gweave}'s own detectors see them;
so |guessMeaning| reads the declaration directly from those tokens. It returns
the \TEX/ part of the meaning, or |""| when it cannot make out anything, in which
case the identifier keeps the meaning it had.

First the cases in which the name itself tells what follows: a label, a function,
a method. Otherwise the name is one of a list, |a, b, c|, which belongs to a
declaration of some |kind|: a |var|, |const|, or |type| declaration, a field of a
|struct|, a method of an |interface|, or the parameters of a function. What
follows the list then settles the meaning; and when the list belongs to no
declaration, it may still head a short variable declaration, |a, b := |\dots.
@<The mini-index functions@>=
func (wv *Weaver) guessMeaning(toks []token, k int) string {
	p := prevSignificant(toks, k)
	@<Return the meaning of a label, a function, or a method@>
	@<Find the extent |h|$\,\ldots\,$|j| of the name list around |k|@>
	kind := ""
	@<Find the |kind| of declaration that the name list belongs to@>
	r := nextOnLine(toks, j+1) // what follows the name list
	switch kind {
	case "type":
		@<Return the definition of the type |k|@>
	case "const":
		@<Return the value or the type of the constant |k|@>
	case "var", "field", "param":
		@<Return the type of the variable, field, or parameter |k|@>
	case "method":
		return wv.codeTeX(sigCode(toks, nextSignificant(toks, k+1)))
	}
	if r >= 0 && toks[r].kind == tkOp && toks[r].text == ":=" {
		return wv.codeTeX(wv.inferCode(toks, r+1, idx, count))
	}
	return ""
}

@ A label stands at the head of its line, followed by a colon; its meaning is the
word \.{\\twilllabel}, which \.{gtwimac.tex} defines as `label' and a
localization may translate. But a long |case| list may be continued on a line of
its own, and then its last value stands there just as a label would, after a
comma; \.{gweave} takes it for one, and we say |notADefinition|. A function's name follows |func|, and a method's
follows the parenthesis that closes its receiver.
@<Return the meaning of a label, a function, or a method@>=
if n := nextOnLine(toks, k+1); n >= 0 && toks[n].kind == tkOp && toks[n].text == ":" &&
	beginsLine(toks, k) {
	if p >= 0 && toks[p].kind == tkOp && toks[p].text == "," {
		return notADefinition // the end of a |case| list, continued on a line of its own
	}
	return "\\twilllabel"
}
if p >= 0 && toks[p].kind == tkKeyword && toks[p].text == "func" {
	return wv.codeTeX(sigCode(toks, nextSignificant(toks, k+1)))
}
if p >= 0 && toks[p].kind == tkOp && toks[p].text == ")" {
	@<Return the signature of the method whose receiver list ends at |p|@>
}

@ A method's meaning is its signature, preceded by the type of its receiver in
parentheses: |(*Weaver) func|$(\,)$ |error|, say.
@<Return the signature of the method whose receiver list ends at |p|@>=
o := p
for depth := 0; o >= 0; o-- {
	if toks[o].kind == tkOp && toks[o].text == ")" {
		depth++
	} else if toks[o].kind == tkOp && toks[o].text == "(" {
		if depth--; depth == 0 {
			break
		}
	}
}
if f := prevSignificant(toks, o); o >= 0 && f >= 0 && toks[f].kind == tkKeyword && toks[f].text == "func" {
	a := nextSignificant(toks, o+1) // the receiver's name, or its type
	if b := nextSignificant(toks, a+1); a >= 0 && b >= 0 && b < p && toks[a].kind == tkIdent &&
		toks[b].text != "." && toks[b].text != "[" {
		a = b
	}
	if sig := sigCode(toks, nextSignificant(toks, k+1)); sig != "" {
		return wv.codeTeX("(" + goCode(toks, a, p) + ") " + sig)
	}
	return ""
}

@ The list runs from |h| to |j|, and |k| is its |idx|th name of |count|; the
position matters when the list is matched against a list of values,
|a, b := 1, "x"|.
@<Find the extent |h|$\,\ldots\,$|j| of the name list around |k|@>=
h, idx := k, 0
for {
	c := prevSignificant(toks, h)
	if c < 0 || toks[c].kind != tkOp || toks[c].text != "," {
		break
	}
	n := prevSignificant(toks, c)
	if n < 0 || toks[n].kind != tkIdent {
		break
	}
	h, idx = n, idx+1
}
j, count := k, idx+1
for {
	c := nextSignificant(toks, j+1)
	if c < 0 || toks[c].kind != tkOp || toks[c].text != "," {
		break
	}
	n := nextSignificant(toks, c+1)
	if n < 0 || toks[n].kind != tkIdent {
		break
	}
	j, count = n, count+1
}

@ A list right after |var|, |const|, or |type| is declared by that keyword.
Otherwise we look at the bracket that encloses the name, if any: the parenthesis
of a declaration group, the brace of a |struct| or an |interface|, or a
parenthesis or bracket of a function's signature. (A definition inside any other
parenthesis is not valid \GO/; within a block's brace, it can only be a short
variable declaration.)
@<Find the |kind| of declaration that the name list belongs to@>=
if q := prevSignificant(toks, h); q >= 0 && toks[q].kind == tkKeyword &&
	(toks[q].text == "var" || toks[q].text == "const" || toks[q].text == "type") {
	kind = toks[q].text
} else {
	e := k - 1
	for depth := 0; e >= 0; e-- {
		if toks[e].kind == tkOp {
			switch toks[e].text {
			case ")", "]", "}":
				depth++
			case "(", "[", "{":
				depth--
			}
		}
		if depth < 0 {
			break
		}
	}
	@<Set |kind| by the bracket at |e|@>
}

@ @<Set |kind| by the bracket at |e|@>=
if e >= 0 {
	q := prevSignificant(toks, e)
	keyword := ""
	if q >= 0 && toks[q].kind == tkKeyword {
		keyword = toks[q].text
	}
	switch {
	case toks[e].text == "(" && (keyword == "var" || keyword == "const" || keyword == "type"):
		kind = keyword
	case toks[e].text == "{" && keyword == "struct":
		kind = "field"
	case toks[e].text == "{" && keyword == "interface":
		kind = "method"
	case toks[e].text == "(" || toks[e].text == "[":
		kind = "param"
	}
}

@ A type's meaning is `$=$' and its definition. Type parameters are written right
against the name, |List[T any]|, while an array type is set off by a space,
|Vector [3]float64|; an alias has an |=| of its own.
@<Return the definition of the type |k|@>=
r = k + 1
if r < len(toks) && toks[r].kind == tkOp && toks[r].text == "[" {
	if r = closerOf(toks, r) + 1; r == 0 {
		return ""
	}
}
r = nextOnLine(toks, r)
if r >= 0 && toks[r].kind == tkOp && toks[r].text == "=" {
	r = nextOnLine(toks, r+1)
}
if r < 0 || toks[r].kind == tkNewline || toks[r].kind == tkComment {
	return ""
}
return "=" + wv.codeTeX(goCode(toks, r, typeEnd(toks, r)))

@ A constant whose value is a literal means `$=$' and the literal, like a \CEE/
macro that is just a constant; so does one whose value is a short expression
without |iota|, like |memTop - 11|, as in \.{TWILL}'s mini-indexes for \TEX/.
Otherwise its meaning is its type, if the declaration gives one, or just
\&{const}. A spec with nothing after its names repeats the one before, |iota|
and all.
@<Return the value or the type of the constant |k|@>=
if r < 0 || toks[r].kind == tkNewline || toks[r].kind == tkComment {
	return wv.codeTeX("const")
}
typ := ""
if toks[r].kind != tkOp || toks[r].text != "=" {
	e := typeEnd(toks, r)
	typ, r = goCode(toks, r, e), nextOnLine(toks, e)
}
if r >= 0 && toks[r].kind == tkOp && toks[r].text == "=" {
	if a, b, ok := rhsPart(toks, r+1, idx, count); ok {
		@<Return the value from |a| to |b|, if it is a literal or a short expression@>
	}
}
if typ != "" {
	return wv.codeTeX(typ)
}
return wv.codeTeX("const")

@ A short expression has at most |maxConstTokens| tokens, and no |iota|, and its
code is at most |maxConstWidth| characters long; a mini-index has narrow columns,
and a string cannot be broken across their lines. (\.{CTWILL} replaces a \TEX/ part
that is too long by \.{\\zip}.) A string or a character that is too long shows
its type instead.
@<Return the value from |a| to |b|, if it is a literal or a short expression@>=
short := true
n, lit := 0, -1
for i := a; i < b; i++ {
	switch toks[i].kind {
	case tkSpace, tkComment:
	case tkNewline:
		short = false
	default:
		n, lit = n+1, i
		short = short && toks[i].text != "iota"
	}
}
if code := goCode(toks, a, b); short && n > 0 && n <= maxConstTokens {
	if len(code) <= maxConstWidth {
		return "=" + wv.codeTeX(code)
	}
	if n == 1 && toks[lit].kind == tkString && toks[lit].text != "" {
		if toks[lit].text[0] == '\'' {
			return wv.codeTeX("rune")
		}
		return wv.codeTeX("string")
	}
}

@ @<The mini-index types@>=
const (
	maxConstTokens = 5  // the most tokens that a constant's meaning shows
	maxConstWidth  = 24 // the longest code it shows
)

@ A variable, a field, or a parameter means its type, which follows the names;
a variable declared without one has the type of its initial value, as far as
|inferCode| can tell.
@<Return the type of the variable, field, or parameter |k|@>=
if r < 0 || toks[r].kind == tkNewline || toks[r].kind == tkComment || toks[r].kind == tkString {
	return ""
}
if toks[r].kind == tkOp {
	switch toks[r].text {
	case "=":
		return wv.codeTeX(wv.inferCode(toks, r+1, idx, count))
	case ")", "]", "}", ",", ";", ":=":
		return ""
	}
}
return wv.codeTeX(goCode(toks, r, typeEnd(toks, r)))

@ |codeTeX| sets a piece of \GO/ code as \.{gweave} sets a \.{\|...\|} fragment, without
recording anything in the index.
@<The mini-index functions@>=
func (wv *Weaver) codeTeX(code string) string {
	if code == "" {
		return ""
	}
	return wv.inlineCode(code, 0, false)
}

@ |nextOnLine| is |nextSignificant| for a single line: it skips the blanks after
|i|, but not a newline, and returns $-1$ at the end of the tokens.
@<The mini-index functions@>=
func nextOnLine(toks []token, i int) int {
	for ; i < len(toks); i++ {
		if toks[i].kind != tkSpace {
			return i
		}
	}
	return -1
}

@ |typeEnd| finds the end of the type that begins at |i|: the first token, at the
type's own level, that cannot continue it. The body of a |struct| or an
|interface| and the parameters of a |func| type are passed over whole, since they
may contain anything.
@<The mini-index functions@>=
func typeEnd(toks []token, i int) int {
	depth := 0
	for ; i < len(toks); i++ {
		t := toks[i]
		switch t.kind {
		case tkNewline, tkComment, tkString:
			if depth == 0 {
				return i
			}
		case tkKeyword:
			@<Pass over the body of a |struct| or |interface|, or a |func|'s parameters@>
		case tkOp:
			switch t.text {
			case "(", "[":
				depth++
			case ")", "]", "}":
				if depth == 0 {
					return i
				}
				depth--
			case "{", "{}", ",", ";", "=", ":=":
				if depth == 0 {
					return i
				}
				if t.text == "{" {
					depth++
				}
			}
		}
	}
	return i
}

@ @<Pass over the body of a |struct| or |interface|, or a |func|'s parameters@>=
if n := nextSignificant(toks, i+1); n >= 0 && toks[n].kind == tkOp {
	switch {
	case (t.text == "struct" || t.text == "interface") && toks[n].text == "{}":
		i = n
	case (t.text == "struct" || t.text == "interface") && toks[n].text == "{",
		t.text == "func" && toks[n].text == "(":
		if c := closerOf(toks, n); c >= 0 {
			i = c
		}
	}
}

@ |goCode| turns the tokens from |i| to |end| back into \GO/ code, eliding what a
mini-index has no room for: the body of a |struct| or an |interface|, the
parameters of a |func|, which become $(\,)$, and the length of an array, unless
it is a single short token, which becomes $[\,]$; \.{CTWILL} likewise suppresses
``text that may appear between parentheses or brackets.'' The elision is an
\.{@@t} box, which \.{gweave} sets as an operand, and an at-sign of the code is
doubled, so that the result can go through |inlineCode|.
@<The mini-index functions@>=
func goCode(toks []token, i, end int) string {
	var b strings.Builder
	prev := token{kind: tkNewline} // the last token written
	for ; i < end && i < len(toks); i++ {
		t := toks[i]
		if t.kind == tkSpace || t.kind == tkNewline || t.kind == tkComment {
			continue
		}
		if b.Len() > 0 {
			b.WriteByte(' ')
		}
		b.WriteString(strings.ReplaceAll(t.text, "@@", "@@@@"))
		switch t.kind {
		case tkKeyword:
			@<Elide the body or the parameters that follow the keyword |t|@>
		case tkOp:
			@<Elide the length of an array, if |t| opens one@>
		}
		prev = t
	}
	return b.String()
}

@ A bracket opens an array's length unless it follows a name (an index, or a
generic type's arguments) or |map| (a map's key type).
@<Elide the length of an array, if |t| opens one@>=
if t.text == "[" && prev.kind != tkIdent && prev.kind != tkBuiltin && prev.text != "map" {
	if c := closerOf(toks, i); c >= 0 && c < end {
		// a short length, like the |4| of |[4]int|, stays
		if n := nextSignificant(toks, i+1); n != prevSignificant(toks, c) || len(toks[n].text) > 8 {
			b.WriteString("@@t\\,@@>]")
			i = c
		}
	}
}

@ @<Elide the body or the parameters that follow the keyword |t|@>=
if n := nextSignificant(toks, i+1); n >= 0 && toks[n].kind == tkOp {
	switch {
	case (t.text == "struct" || t.text == "interface") && toks[n].text == "{":
		if c := closerOf(toks, n); c >= 0 {
			i = c
		}
	case t.text == "func" && toks[n].text == "(":
		if c := closerOf(toks, n); c >= 0 {
			b.WriteString("(@@t\\,@@>)")
			i = c
		}
	}
}

@ |sigCode| gives the meaning of a function, a method, or a function literal: the
signature that begins at |j|, just past the name or the |func|, with the
parameters elided; an empty parameter list is left as it is. Type parameters are
dropped altogether.
@<The mini-index functions@>=
func sigCode(toks []token, j int) string {
	if j >= 0 && toks[j].kind == tkOp && toks[j].text == "[" {
		if c := closerOf(toks, j); c >= 0 {
			j = nextSignificant(toks, c+1)
		}
	}
	if j < 0 || toks[j].kind != tkOp {
		return ""
	}
	code := "func()"
	switch toks[j].text {
	case "(":
		c := closerOf(toks, j)
		if c < 0 {
			return ""
		}
		j, code = c, "func(@@t\\,@@>)"
	case "()":
	default:
		return ""
	}
	r := nextOnLine(toks, j+1)
	if r < 0 || toks[r].kind == tkNewline || toks[r].kind == tkComment ||
		toks[r].kind == tkOp && (toks[r].text == "{" || toks[r].text == "{}") {
		return code
	}
	return code + " " + goCode(toks, r, typeEnd(toks, r))
}

@ |rhsPart| finds the |idx|th of the |count| values that begin at |s|, up to the
end of the line or of the statement, and reports whether the values were as many
as the names. A brace ends the values unless it opens a composite literal, which
it does when it follows a type: a name, a bracket, or a brace.
@<The mini-index functions@>=
func rhsPart(toks []token, s, idx, count int) (int, int, bool) {
	var parts [][2]int
	a, depth, prev := s, 0, -1
	i := s
scan:
	for ; i < len(toks); i++ {
		t := toks[i]
		switch t.kind {
		case tkSpace:
			continue
		case tkNewline, tkComment:
			if depth == 0 {
				break scan
			}
			continue
		case tkOp:
			@<Follow the nesting of the values at the punctuation |t|@>
		}
		prev = i
	}
	parts = append(parts, [2]int{a, i})
	if len(parts) != count {
		return 0, 0, false
	}
	return parts[idx][0], parts[idx][1], true
}

@ @<Follow the nesting of the values at the punctuation |t|@>=
switch t.text {
case "(", "[":
	depth++
case ")", "]", "}":
	if depth == 0 {
		break scan
	}
	depth--
case "{":
	if depth == 0 && (prev < 0 || !(toks[prev].kind == tkIdent || toks[prev].kind == tkBuiltin ||
		toks[prev].kind == tkOp && (toks[prev].text == "]" || toks[prev].text == "}"))) {
		break scan
	}
	depth++
case ",":
	if depth == 0 {
		parts = append(parts, [2]int{a, i})
		a = i + 1
	}
case ";":
	if depth == 0 {
		break scan
	}
}

@ |inferCode| guesses the type of the |idx|th of |count| values that begin at |s|,
for a declaration that leaves the type to the compiler; it returns \GO/ code, or
just |var| when it has no idea. The guess is made on the value's form alone: a
literal has its default type, a composite literal its stated one, |make(T, n)|
gives~|T| and |new(T)| gives |*T|, a conversion |T(x)| gives~|T|, and a function
literal gives its signature. Anything else---a call, an expression, a
|range|---would take a type checker, which we do not have.
@<The mini-index functions@>=
func (wv *Weaver) inferCode(toks []token, s, idx, count int) string {
	if f := nextSignificant(toks, s); f >= 0 && toks[f].kind == tkKeyword && toks[f].text == "range" {
		return "var"
	}
	a, b, ok := rhsPart(toks, s, idx, count)
	if !ok {
		return "var"
	}
	var sig []int
	for i := a; i < b; i++ {
		if toks[i].kind != tkSpace && toks[i].kind != tkNewline && toks[i].kind != tkComment {
			sig = append(sig, i)
		}
	}
	if len(sig) == 0 {
		return "var"
	}
	t := toks[sig[0]]
	switch {
	@<Infer the type of a literal@>
	case t.kind == tkKeyword && t.text == "func":
		if c := sigCode(toks, nextSignificant(toks, sig[0]+1)); c != "" {
			return c
		}
	case t.kind == tkIdent && (t.text == "make" || t.text == "new") && len(sig) > 2 &&
		toks[sig[1]].text == "(":
		typ := goCode(toks, sig[2], typeEnd(toks, sig[2]))
		if t.text == "new" {
			return "*" + typ
		}
		return typ
	case t.kind == tkOp && t.text == "&" && len(sig) > 1:
		if c := compositeType(toks, sig[1], b); c != "" {
			return "*" + c
		}
	case (t.kind == tkBuiltin || wv.format[t.text] == tkBuiltin) && len(sig) > 1 &&
		toks[sig[1]].kind == tkOp && toks[sig[1]].text == "(":
		return t.text // a conversion
	default:
		if c := compositeType(toks, sig[0], b); c != "" {
			return c
		}
	}
	return "var"
}

@ An untyped constant has a default type, |int|, |float64|, |complex128|,
|rune|, |string|, or |bool|, which is what a variable initialized with it gets.
@<Infer the type of a literal@>=
case len(sig) == 1 && t.kind == tkNumber:
	switch s := strings.ToLower(t.text); {
	case strings.HasSuffix(s, "i"):
		return "complex128"
	case strings.HasPrefix(s, "0x"):
		if strings.Contains(s, "p") {
			return "float64"
		}
		return "int"
	case strings.ContainsAny(s, ".e"):
		return "float64"
	}
	return "int"
case len(sig) == 1 && t.kind == tkString && t.text != "": // not a stand-in
	if t.text[0] == '\'' {
		return "rune"
	}
	return "string"
case len(sig) == 1 && t.kind == tkMacro && (t.text == "true" || t.text == "false"):
	return "bool"

@ |compositeType| returns the type of the composite literal that begins at |i|,
or |""| if what begins there is not one: a type---a name, a slice, array, or map
type, or a |struct|---followed directly by its brace.
@<The mini-index functions@>=
func compositeType(toks []token, i, b int) string {
	t := toks[i]
	if !(t.kind == tkIdent || t.kind == tkBuiltin || t.kind == tkOp && (t.text == "[]" || t.text == "[") ||
		t.kind == tkKeyword && (t.text == "map" || t.text == "struct")) {
		return ""
	}
	e := typeEnd(toks, i)
	if e >= b || toks[e].kind != tkOp || (toks[e].text != "{" && toks[e].text != "{}") {
		return ""
	}
	return goCode(toks, i, e)
}

@* Tests.
The weave engine's tests, one section per case. %'
@z

@x a section now ends with its mini-index list
@ Every section closes with a \.{\\fi}: it matches the \.{\\ifon} its \.{\\M}/\.{\\N}
headline leaves open, so \.{\\let\\maybe=\\iffalse} in a change file can make \TEX/
skip an untouched section's whole body (\.{cweave}'s change-only listing). There is
exactly one closer per section, so the conditionals stay balanced.
@(gweave_test.go@>=
func TestWeaveSectionClosesConditional(t *testing.T) {
	out := weaveString(t, "@@* One.\n@@c\nx := 1\n@@ Two.\ntwo.\n@@ Three.\n@@c\ny := 2\n")
	opens := 0
	for _, m := range []string{`\M{`, `\N{`, `\Ms{`, `\Ns{`} {
		opens += strings.Count(out, m)
	}
	// Each headline opens one \ifon that a \fi closes; the back matter's \ifsecs
	// bookmark block adds one more balanced \fi.
	if fis := strings.Count(out, "\n\\fi\n"); fis != opens+1 {
		t.Errorf("want %d closing \\fi, got %d:\n%s", opens+1, fis, out)
	}
}
@y
@ Every section closes with its mini-index list, \.{\\mini}$\,\ldots\,$\.{\}\\FI},
where \.{gweave} writes a \.{\\fi}; in proofmode \.{\\FI} is that \.{\\fi}, and
matches the \.{\\ifon} that the section's \.{\\M}/\.{\\N} leaves open. There is
exactly one closer per section, so the conditionals stay balanced.
@(gweave_test.go@>=
func TestWeaveSectionClosesConditional(t *testing.T) {
	out := weaveString(t, "@@* One.\n@@c\nx := 1\n@@ Two.\ntwo.\n@@ Three.\n@@c\ny := 2\n")
	opens := 0
	for _, m := range []string{`\M{`, `\N{`, `\Ms{`, `\Ns{`} {
		opens += strings.Count(out, m)
	}
	if fis := strings.Count(out, "\n}\\FI\n"); fis != opens {
		t.Errorf("want %d closing \\FI, got %d:\n%s", opens, fis, out)
	}
	// The back matter's \ifsecs bookmark block has a balanced \fi of its own.
	if fis := strings.Count(out, "\n\\fi\n"); fis != 1 {
		t.Errorf("want 1 closing \\fi, got %d:\n%s", fis, out)
	}
}
@z

@x the macro package is gtwimac
func TestWeaveInjectsGwebmac(t *testing.T) {
	// gweave supplies \.{\\input} gwebmac; the .w file need not.
	out := weaveString(t, "@@ x\n@@c\npackage main\n")
	if !strings.HasPrefix(out, "\\input gwebmac\n") {
		t.Errorf("woven output should start with \\input gwebmac, got:\n%.30q", out)
	}
	// A stray copy in the limbo is stripped, never duplicated.
	out2 := weaveString(t, "\\input gwebmac\n@@ x\n@@c\npackage main\n")
	if n := strings.Count(out2, "\\input gwebmac"); n != 1 {
		t.Errorf("want exactly one \\input gwebmac, got %d", n)
	}
}
@y
func TestWeaveInjectsGwebmac(t *testing.T) {
	// gtwill supplies \.{\\input} gtwimac, which loads gwebmac; the .w file need not.
	out := weaveString(t, "@@ x\n@@c\npackage main\n")
	if !strings.HasPrefix(out, "\\input gtwimac\n") {
		t.Errorf("woven output should start with \\input gtwimac, got:\n%.30q", out)
	}
	// A stray copy of gwebmac in the limbo is stripped: gtwimac has loaded it.
	out2 := weaveString(t, "\\input gwebmac\n@@ x\n@@c\npackage main\n")
	if n := strings.Count(out2, "\\input gwebmac"); n != 0 {
		t.Errorf("want no \\input gwebmac, got %d", n)
	}
}
@z

@x the tests of the mini-indexes go before the index
@** Index.
This index covers \.{GWEAVE} alone, as it stands when \.{gweave.w} is woven by
itself: every identifier it uses (a section number is underlined where the
identifier is defined), together with the manual index entries. In the combined
\.{GWEB} document \.{gweb.ch} removes this section, and the index at the end of
\.{gweb.w} covers all three webs. The list of section names follows.
@y
@ The tests of the mini-index machinery need a web woven by a |Weaver| that we
can look into afterwards, and the lists that its sections hand to \TEX/: the
lines between each \.{\\mini} and the \.{\}\\FI} that ends it, one list per
section.
@(gweave_test.go@>=
func weaveTwill(t *testing.T, src string) (string, *Weaver) {
	t.Helper()
	var b strings.Builder
	wv := New(common.ParseString(src))
	if err := wv.Weave(&b); err != nil {
		t.Fatal(err)
	}
	return b.String(), wv
}
@#
func miniLists(out string) [][]string {
	var lists [][]string
	for _, part := range strings.Split(out, "\n\\mini\n")[1:] {
		body, _, _ := strings.Cut(part, "}\\FI\n")
		lists = append(lists, strings.Split(strings.TrimSuffix(body, "\n"), "\n"))
	}
	return lists
}
@#
func hasLine(list []string, prefix string) bool {
	for _, ln := range list {
		if strings.HasPrefix(ln, prefix) {
			return true
		}
	}
	return false
}

@ A section cites what it uses and others define, before or after it: the
first pass primes the second, so a forward reference is cited too. What a
section defines itself, it does not cite.
@(gweave_test.go@>=
func TestTwillCitesUsesDefinedElsewhere(t *testing.T) {
	out, _ := weaveTwill(t, `@@* Intro.
@@c
package main

var count int

func bump(n int) int { return count + n }
@@ Use.
@@c
func main() { count = bump(limit) }
@@ Later.
@@c
const limit = 10
`)
	lists := miniLists(out)
	if len(lists) != 3 {
		t.Fatalf("want 3 lists, got %d:\n%s", len(lists), out)
	}
	for _, want := range []string{
		`\[1 {\ID{count}} \PB{\KW{int}}`,
		`\[1 {\ID{bump}} \PB{\KW{func}`,
		`\[3 {\ID{limit}} =\PB{\NU{10}}`,
	} {
		if !hasLine(lists[1], want) {
			t.Errorf("section 2 should cite %q:\n%s", want, strings.Join(lists[1], "\n"))
		}
	}
	if len(lists[0]) != 1 || lists[0][0] != "" {
		t.Errorf("section 1 defines all it uses, yet cites %q", lists[0])
	}
}

@ |guessMeaning| reads the meaning off each kind of declaration. A case defines
|name| in its code, which a second section then uses; the meaning that the
second section cites must be the |want| code as \.{gweave} sets it in that web
(where a declared type is bold), after the prefix |pre|.
@(gweave_test.go@>=
func TestTwillGuessesMeanings(t *testing.T) {
	cases := []struct{ code, name, pre, want string }{
		{"var s []byte", "s", "", "[]byte"},
		{"var a, b int", "b", "", "int"},
		{"var x = 3.5", "x", "", "float64"},
		{"x := map[string]int{}", "x", "", "map[string]int"},
		{"p := &Node{next: nil}", "p", "", "*Node"},
		{"q := make([]*Node, n)", "q", "", "[]*Node"},
		{"r := new(Graph)", "r", "", "*Graph"},
		{"f := func(a int) bool { return a > 0 }", "f", "", "func(@@t\\,@@>) bool"},
		{`i, j := 0, "s"`, "j", "", "string"},
		{"w, err := open()", "w", "", "var"},
		{"const max = 100", "max", "=", "100"},
		{"const (\n\tA = iota\n\tB\n)", "B", "", "const"},
		{"type Node struct {\n\tnext *Node\n}", "Node", "=", "struct"},
		{"type Node struct {\n\tnext *Node\n}", "next", "", "*Node"},
		{"type Celsius float64", "Celsius", "=", "float64"},
		{"func area(w, h float64) (float64, error) {}", "area", "", "func(@@t\\,@@>) (float64, error)"},
		{"func (g *Graph) Order() int { return 0 }", "Order", "", "(*Graph) func() int"},
		{"func (g *Graph) Order() int { return 0 }", "g", "", "*Graph"},
		{"func g(x, y int, s ...string) {}", "s", "", "...string"},
		{"func f() {\nloop:\n\tfor {\n\t\tbreak loop\n\t}\n}", "loop", "", ""},
		{"const unsetNode = 13", "unsetNode", "=", "13"},
	}
	for _, c := range cases {
		out, wv := weaveTwill(t, "@@ a\n@@c\n"+c.code+"\n@@ b\n@@c\n_ = "+c.name+"\n")
		lists := miniLists(out)
		want := `\[1 {` + wv.indexHead(c.name) + `} ` + c.pre + wv.codeTeX(c.want)
		if c.name == "loop" {
			want = `\[1 {\ID{loop}} \twilllabel`
		}
		if len(lists) != 2 || !hasLine(lists[1], want) {
			t.Errorf("%q: want %q in\n%s", c.code, want, out)
		}
	}
}

@ The last value of a |case| list continued on its own line looks like a label,
but it keeps the meaning that its declaration gave it.
@(gweave_test.go@>=
func TestTwillCaseListIsNoLabel(t *testing.T) {
	out, _ := weaveTwill(t, "@@ a\n@@c\nconst unsetNode = 13\n@@ b\n@@c\nswitch x {\n"+
		"case aNode,\n\tunsetNode:\n\ty()\n}\n@@ c\n@@c\n_ = unsetNode\n")
	if list := miniLists(out)[2]; !hasLine(list, `\[1 {\ID{unsetNode}} =`) {
		t.Errorf("unsetNode should keep its meaning from section 1:\n%s", strings.Join(list, "\n"))
	}
}

@ The operations: a temporary meaning (between two \.{@@\%}) replaces the
permanent one in its section's list, an \.{@@-} keeps the identifier out of it,
an \.{@@\$} outside the \.{@@\%} switch is permanent, and an \.{@@r} puts
\.{\\shortpage} before the next section.
@(gweave_test.go@>=
func TestTwillOperations(t *testing.T) {
	out, _ := weaveTwill(t, `@@* A.
@@c
var count int
@@ B. @@%@@$count {LIB}7 \zip@@>@@%
@@c
_ = count
@@ C. @@-count@@>
@@c
_ = count
@@ D. @@$limit "lib" =\NU{1}@@>@@r
x.
@@ E.
@@c
_ = limit + count
`)
	lists := miniLists(out)
	if len(lists) != 5 {
		t.Fatalf("want 5 lists, got %d:\n%s", len(lists), out)
	}
	if !hasLine(lists[1], `\]{LIB}7 {\ID{count}} \zip`) || hasLine(lists[1], `\[1 `) {
		t.Errorf("section 2 should cite only the temporary meaning:\n%s", strings.Join(lists[1], "\n"))
	}
	if hasLine(lists[2], `\[1 `) {
		t.Errorf("section 3 suppressed count:\n%s", strings.Join(lists[2], "\n"))
	}
	if !hasLine(lists[4], `\]"lib" {\ID{limit}} =\NU{1}`) || !hasLine(lists[4], `\[1 {\ID{count}}`) {
		t.Errorf("section 5 should cite limit and count:\n%s", strings.Join(lists[4], "\n"))
	}
	if !strings.Contains(out, "\n\\shortpage\n\\M{5}") {
		t.Errorf("@@r should put \\shortpage before section 5:\n%s", out)
	}
	if strings.Contains(out, "@@$") || strings.Contains(out, "@@-") {
		t.Errorf("an operation leaked into the output:\n%s", out)
	}
}

@ A name that the commentary defines with \.{@@!} has no declaration to read a
meaning from; it means \.{\\zip}, and is cited with the section that defines it.
@(gweave_test.go@>=
func TestTwillProseDefinition(t *testing.T) {
	out, _ := weaveTwill(t, "@@ A |@@!charNode| is small.\n@@ b\n@@c\n_ = charNode\n")
	if !hasLine(miniLists(out)[1], `\[1 {\ID{charNode}} \zip`) {
		t.Errorf("want charNode cited from section 1:\n%s", out)
	}
}

@ An identifier without a meaning is cited as uninitialized only if it is an
ordinary name of the program: not an imported package, a predeclared function,
or a selected name.
@(gweave_test.go@>=
func TestTwillUninitialized(t *testing.T) {
	out, _ := weaveTwill(t, "@@ a\n@@c\nimport \"fmt\"\n\nfunc main() { fmt.Println(len(x), y.Len()) }\n")
	list := miniLists(out)[0]
	if !hasLine(list, `\[0 {\ID{x}} \uninitialized`) || !hasLine(list, `\[0 {\ID{y}} \uninitialized`) {
		t.Errorf("x and y should be cited as uninitialized:\n%s", strings.Join(list, "\n"))
	}
	for _, name := range []string{"fmt", "Println", "len", "Len"} {
		if hasLine(list, `\[0 {\ID{`+name+`}}`) {
			t.Errorf("%s should not be cited:\n%s", name, strings.Join(list, "\n"))
		}
	}
}

@ The \.{.aux} lines record the program's own definitions under its title, which
comes from the limbo; a title of another program makes an external citation.
@(gweave_test.go@>=
func TestTwillAuxAndTitles(t *testing.T) {
	_, wv := weaveTwill(t, "\\def\\title{FOO}\n@@ a\n@@c\nvar count int\n")
	if len(wv.tw.aux) != 1 || wv.tw.aux[0] != `count {FOO}1 \PB{\KW{int}}` {
		t.Errorf("aux = %q", wv.tw.aux)
	}
	out, _ := weaveTwill(t, "\\def\\title{FOO}\n@@ a @@$n {BAR}4 \\KW{int}@@>\n@@c\n_ = n\n")
	if !hasLine(miniLists(out)[0], `\]{BAR}4 {\ID{n}} \KW{int}`) {
		t.Errorf("want an external citation of n:\n%s", out)
	}
}

@ |extractTwillOps| takes the operations out of the text, leaves every other
control code alone, and closes up a line that an operation had to itself.
@(gweave_test.go@>=
func TestExtractTwillOps(t *testing.T) {
	text, ops := extractTwillOps("a\n@@$x {P}1 t@@>\nb @@@@ c@@-y@@>@@<n@@>@@%@@R")
	if text != "a\nb @@@@ c@@<n@@>" {
		t.Errorf("text = %q", text)
	}
	want := []twillOp{{'$', "x {P}1 t"}, {'-', "y"}, {'%', ""}, {'r', ""}}
	if len(ops) != len(want) {
		t.Fatalf("ops = %q", ops)
	}
	for i := range want {
		if ops[i] != want[i] {
			t.Errorf("op %d = %q, want %q", i, ops[i], want[i])
		}
	}
}

@ |digest| reads the three forms of location and complains about a malformed
operation.
@(gweave_test.go@>=
func TestTwillDigest(t *testing.T) {
	tw := &twill{cur: map[string]*permMeaning{}}
	tw.title("{ME}")
	if err := tw.digest(` x {ME}12 \KW{int}`); err != nil {
		t.Fatal(err)
	}
	if m := tw.meaningOf("x").perm; m.prog != 0 || m.sec != 12 || m.tex != `\KW{int}` {
		t.Errorf("x: %+v", m)
	}
	if err := tw.digest(`y "a \"b\"" \zip`); err != nil {
		t.Fatal(err)
	}
	if m := tw.meaningOf("y").perm; tw.titles[m.prog] != `"a \"b\""` || m.tex != `\zip` {
		t.Errorf("y: %+v", m)
	}
	for _, bad := range []string{"z", "z FOO", "z {FOO", "z {FOO}3"} {
		if err := tw.digest(bad); err == nil {
			t.Errorf("%q should be rejected", bad)
		}
	}
}

@ The last section, when it is starred, is the index section: \.{\\twilllast}
comes before its headline, so that \TEX/ returns to ordinary pages for it.
@(gweave_test.go@>=
func TestTwillLastSection(t *testing.T) {
	out, _ := weaveTwill(t, "@@* A.\n@@c\nvar x int\n@@* Index.\nThe index.\n")
	if !strings.Contains(out, "\n\\twilllast\n\\N{0}{2}{Index}") {
		t.Errorf("want \\twilllast before the index section:\n%s", out)
	}
	if strings.Count(out, "\\twilllast") != 1 {
		t.Errorf("want one \\twilllast:\n%s", out)
	}
}

@ In proofmode the woven output loads \.{gtproofmac} instead.
@(gweave_test.go@>=
func TestTwillProofmode(t *testing.T) {
	wv := New(common.ParseString("@@ a\n@@c\nvar x int\n"))
	wv.tw.proof = true
	var b strings.Builder
	if err := wv.Weave(&b); err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(b.String(), "\\input gtproofmac\n") {
		t.Errorf("proofmode output should start with \\input gtproofmac:\n%.40q", b.String())
	}
}

@** Index.
This index covers \.{GTWILL}, that is \.{gweave.w} together with the changes in
\.{gtwill.ch}: every identifier it uses (a section number is underlined where the
identifier is defined), together with the manual index entries. The list of
section names follows.
@z
