% refsort.w -- sort the mini-index entries of a gtwill listing
\def\title{GTWILL-REFSORT}
\def\topofcontents{\null\vfill
  \centerline{\titlefont The {\ttitlefont GTWILL-REFSORT} program}
  \vskip 15pt
  \centerline{(GTWILL Version 0.10.5)}
  \vfill}
\def\botofcontents{\vfill\centerline{\smallfont
  Copyright \copyright\ 2026 Soojin Nam. MIT License.}}

@* Introduction.
This short program sorts the mini-indexes of listings prepared by \.{gtwill}.
It is Knuth's \.{refsort}, from the \.{CTWILL} package, rewritten in \GO/ for the
\.{GWEB} system, and I have kept to it except where \.{gtwill}'s output differs
from \.{CTWILL}'s.

More precisely, suppose you have said \.{gtwill} \.{foo.w}, getting a file
\.{foo.tex}, and that you've then said \.{luatex} \.{foo.tex}, getting files
\.{foo.pdf} and \.{foo.mref}. If you're happy with \.{foo.pdf} except for the
alphabetic order of the mini-indexes, you can then say
$$\hbox{\tt gtwill-refsort <foo.mref >foo.smref}$$
after which \.{luatex} \.{foo} will produce \.{foo.pdf} again, this time with
the mini-indexes in order.

Still more precisely, this program reads from standard input a file consisting
of groups of unsorted lines and writes to standard output a file consisting of
groups of sorted lines. Each input group begins with an identification line
whose first character is \.!; the remaining characters are a page number. The
other lines in the group all have the form
$$\.{+\ }\alpha\.{\ \{}\nu\.{\}\ }\omega$$
where $\alpha$ is the location of a definition---\.{\\[} and a section number,
or \.{\\]} and the title of another program or package---which contains no
blank except inside braces or doublequotes; $\nu$ is the identifier, as the
index of \.{gtwill} sets it; and $\omega$ is an arbitrary string, its meaning.
The output groups contain the same lines without the initial \.{+\ }, sorted
alphabetically by the identifiers, followed by a closing line that says
`\.{\\donewithpage}' followed by the page number copied from the identification
line.

The program reads and writes through |refsort|, which the tests below call
too.
@c
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"sort"
	"strings"
)

@<Types@>
@<The collating order@>
@<Functions@>

func main() {
	if err := refsort(os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "gtwill-refsort:", err)
		os.Exit(1)
	}
}

@ An item of a group is an entry, the line that will be written, together with
the key by which it is sorted.
@<Types@>=
type item struct {
	key   string // the identifier, mapped to the collating order
	entry string // the line, without its \.{+\ }
}

@ |refsort| reads all its input, a group at a time, and writes each group out
sorted. A group ends where a line does not begin with \.+, and the line that
ends a group had better begin the next one.
@<Functions@>=
func refsort(r io.Reader, w io.Writer) error {
	in := bufio.NewScanner(r)
	in.Buffer(make([]byte, 64*1024), 16*1024*1024)
	out := bufio.NewWriter(w)
	line, n := "", 0 // the current line, and its number
	more := in.Scan()
	if more {
		line, n = in.Text(), 1
	}
	for more {
		@<Check that |line| is a valid page-number line@>
		@<Read the group's items, until |line| ends the group@>
		@<Output the current group@>
	}
	if err := in.Err(); err != nil {
		return err
	}
	return out.Flush()
}

@ @<Check that |line| is a valid page-number line@>=
if !strings.HasPrefix(line, "!") {
	return fmt.Errorf("line %d: missing '!': %s", n, line)
}
page := line[1:]

@ An item's key is found as the line is read.
@<Read the group's items, until |line| ends the group@>=
var items []item
for {
	if more = in.Scan(); !more {
		break
	}
	line, n = in.Text(), n+1
	if !strings.HasPrefix(line, "+") {
		break
	}
	e, ok := strings.CutPrefix(line, "+ ")
	if !ok {
		return fmt.Errorf("line %d: missing blank after +: %s", n, line)
	}
	@<Find the identifier |name| of the entry |e|@>
	items = append(items, item{sortKey(name), e})
}

@ The identifier is the braced group after the location~$\alpha$, and the location
ends at the first blank that is neither within braces nor between doublequotes.
(Knuth's original found the end of $\alpha$ by the blank alone, and later had to
teach it about doublequotes, in a section called ``A bugfix.'' The braces are new:
a program's title, between braces, may contain blanks of its own.)
@<Find the identifier |name| of the entry |e|@>=
i, depth, quoted := 0, 0, false
for ; i < len(e) && (e[i] != ' ' || depth > 0 || quoted); i++ {
	switch e[i] {
	case '\\':
		i++ // a brace or a quote after a backslash does not count
	case '"':
		quoted = !quoted
	case '{':
		depth++
	case '}':
		depth--
	}
}
if i+1 >= len(e) || e[i+1] != '{' {
	return fmt.Errorf("line %d: missing identifier after the location: %s", n, line)
}
j := i + 1
for depth = 0; j < len(e); j++ {
	if e[j] == '\\' {
		j++
	} else if e[j] == '{' {
		depth++
	} else if e[j] == '}' {
		if depth--; depth == 0 {
			break
		}
	}
}
if j == len(e) {
	return fmt.Errorf("line %d: unbalanced identifier: %s", n, line)
}
name := e[i+2 : j]

@ A stable sort keeps entries with equal keys in the order of the first pass.
@<Output the current group@>=
sort.SliceStable(items, func(a, b int) bool { return items[a].key < items[b].key })
for _, it := range items {
	fmt.Fprintln(out, it.entry)
}
fmt.Fprintf(out, "\\donewithpage%s\n", page)

@* Sorting.
The identifier comes as \.{gtwill}'s index sets it, after \TEX/ has written it
out: \.{\\ID\ \{foo\\\_bar\}} for an ordinary name, \.{\\KW} for a type, \.{\\MAC} in
typewriter---where an underscore is \.{\\char\ 95}---or \.{\$\\foo\ \$} for a name
that the web formats as the control sequence \.{\\foo}. |sortKey| recovers the
name and maps it to the collating order. The first control word, the one that
sets the style, is dropped; a \.{\\char} code becomes its character, a control
symbol like \.{\\\_} its symbol, and any other control word, that of a custom
name, its own letters. Braces, blanks, and dollar signs are dropped.
@<Functions@>=
func sortKey(name string) string {
	var b []byte
	first := true
	for i := 0; i < len(name); i++ {
		c := name[i]
		switch {
		case c == '\\' && i+1 < len(name) && isLetter(name[i+1]):
			@<Translate the control word at |i|@>
		case c == '\\' && i+1 < len(name):
			i++
			b = append(b, collateRank[name[i]])
		case c == '{' || c == '}' || c == ' ' || c == '$':
		default:
			b = append(b, collateRank[c])
		}
	}
	return string(b)
}

@ @<Translate the control word at |i|@>=
j := i + 1
for j < len(name) && isLetter(name[j]) {
	j++
}
word := name[i+1 : j]
switch {
case word == "char":
	for j < len(name) && name[j] == ' ' {
		j++
	}
	code := 0
	for j < len(name) && name[j] >= '0' && name[j] <= '9' {
		code = 10*code + int(name[j]-'0')
		j++
	}
	b = append(b, collateRank[byte(code)])
case first && name[0] != '$':
	// the style, \.{\\ID} or the like
default:
	for k := i + 1; k < j; k++ {
		b = append(b, collateRank[name[k]])
	}
}
first = false
i = j - 1

@ @<Functions@>=
func isLetter(c byte) bool { return 'a' <= c && c <= 'z' || 'A' <= c && c <= 'Z' }

@ The mini-indexes follow the order of \.{gtwill}'s own index, which is
\.{cweave}'s: the punctuation, then the underscore, then the letters with upper
and lower case alike, then the digits, then the bytes beyond {\mc ASCII} (so
Hangul comes last). Knuth's \.{refsort} gets nearly the same effect by mapping
upper case to lower and an underscore to a blank. Each byte of a key is
replaced by its rank, so that an ordinary comparison of keys follows that order.
@<The collating order@>=
var collateRank = func() (r [256]byte) {
	order := []byte{0, ' '}
	for c := byte(1); c < ' '; c++ {
		order = append(order, c)
	}
	order = append(order, "!\"#$%&'()*+,-./:;<=>?@@[\\]^`{|}~\x7f_"...)
	order = append(order, "abcdefghijklmnopqrstuvwxyz0123456789"...)
	for i, c := range order {
		r[c] = byte(i)
	}
	for c := 128; c < 256; c++ {
		r[c] = byte(len(order) + c - 128)
	}
	for c := 'A'; c <= 'Z'; c++ {
		r[c] = r[c-'A'+'a']
	}
	return r
}()

@* Tests.
A small group in, the same group sorted out: the entries are ordered by their
identifiers whatever their style, an underscore sorts before a letter, and case
does not matter.
@(refsort_test.go@>=
package main

import (
	"strings"
	"testing"
)

func TestRefsortSortsAGroup(t *testing.T) {
	in := `!2
+ \[3 {\ID {zeta}} \PB {\KW {int}}
+ \]{GBGRAPH}12 {\KW {Graph}} =\PB {\KW {struct}}
+ \]"fmt" {\ID {Println}} \zip
+ \[5 {\MAC {MAX\char 95 N}} =\PB {\NU {9}}
+ \[7 {\ID {x\_1}} \PB {\KW {int}}
+ \[8 {\ID {xa}} \PB {\KW {int}}
!4
`
	want := `\]{GBGRAPH}12 {\KW {Graph}} =\PB {\KW {struct}}
\[5 {\MAC {MAX\char 95 N}} =\PB {\NU {9}}
\]"fmt" {\ID {Println}} \zip
\[7 {\ID {x\_1}} \PB {\KW {int}}
\[8 {\ID {xa}} \PB {\KW {int}}
\[3 {\ID {zeta}} \PB {\KW {int}}
\donewithpage2
\donewithpage4
`
	var out strings.Builder
	if err := refsort(strings.NewReader(in), &out); err != nil {
		t.Fatal(err)
	}
	if out.String() != want {
		t.Errorf("got\n%s\nwant\n%s", out.String(), want)
	}
}

@ A title in braces may hold blanks, and a custom name sorts by its control
sequence.
@(refsort_test.go@>=
func TestRefsortKeys(t *testing.T) {
	cases := map[string]string{
		`\ID {foo\_bar}`:      "foo_bar",
		`\MAC {MAX\char 95 N}`: "max_n",
		`$\xone $`:            "xone",
		`\KW {Graph}`:         "graph",
	}
	for name, plain := range cases {
		if got, want := sortKey(name), sortKey(`\ID {`+plain+`}`); got != want {
			t.Errorf("sortKey(%q) = %q, want %q", name, got, want)
		}
	}
	var out strings.Builder
	in := "!1\n+ \\]{A TITLE}3 {\\ID {b}} \\zip\n+ \\[2 {\\ID {a}} \\zip\n"
	if err := refsort(strings.NewReader(in), &out); err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(out.String(), "\\[2 {\\ID {a}}") {
		t.Errorf("a blank in a braced title confused the parser:\n%s", out.String())
	}
}

@ A malformed file is rejected with the number of the offending line.
@(refsort_test.go@>=
func TestRefsortRejects(t *testing.T) {
	for _, in := range []string{"+ \\[1 {\\ID {a}} x\n", "!1\n+\\[1 {a} x\n", "!1\n+ \\[1 a x\n"} {
		if err := refsort(strings.NewReader(in), &strings.Builder{}); err == nil {
			t.Errorf("%q should be rejected", in)
		}
	}
}

@* Index.
