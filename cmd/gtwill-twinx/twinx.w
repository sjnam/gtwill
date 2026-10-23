% twinx.w -- a master index for a set of programs woven by gtwill
\def\title{GTWILL-TWINX}
\def\topofcontents{\null\vfill
  \centerline{\titlefont The {\ttitlefont GTWILL-TWINX} program}
  \vskip 15pt
  \centerline{(GTWILL Version 0.10.5)}
  \vfill}
\def\botofcontents{\vfill\centerline{\smallfont
  Copyright \copyright\ 2026 Soojin Nam. MIT License.}}

@* Introduction.
This short program compiles a master index for a set of programs that have been
processed by \.{gtwill} (or by \.{gweave}, for that matter). To use it, you say,
e.g., \.{gtwill-twinx} \.{*.tex} \.{>index.tex}, and then \.{luatex} \.{index}.
The individual programs should define their names with a line of the form
`\.{\\def\\title\{NAME\}}', and each entry of the master index cites the
sections of each program under that name. It is Knuth's \.{twinx}, from the
\.{CTWILL} package, rewritten in \GO/.

\.{CTWILL} wrote its index to a file of its own, half formatted, for \.{twinx} to
finish. \.{gtwill}, like \.{gweave}, sets the index at the end of the \.{.tex} file
itself, one line per entry between \.{\\inx} and \.{\\fin}:
$$\.{\\II\{}\eta\.{\}\{}\sigma\.{\}}$$
where $\eta$ is the entry, \.{\\ID\{foo\}} or \.{\\KW\{Graph\}} or \.{\\IR\{...\}}
and so on, and $\sigma$ the list of sections, \.{\\SN\{3\},\ \\SND\{7\}}, with the
sections of definition underlined. So \.{gtwill-twinx} reads those lines, and it
reads the title off the limbo, which the \.{.tex} file begins with.

The program does its work in |twinx|, which the tests below call too.
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
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: gtwill-twinx file.tex ... > index.tex")
		os.Exit(2)
	}
	if err := twinx(os.Args[1:], os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "gtwill-twinx:", err)
		os.Exit(1)
	}
}

@ An |entry| of the master index collects, for one head $\eta$, the citations of
the programs in which it appears, in the order of the files on the command line.
@<Types@>=
type citation struct {
	title string // the program's title
	secs  string // its list of sections, $\sigma$
}

type entry struct {
	head  string // $\eta$, as the index sets it
	key   string // the head's name, mapped to the collating order
	cites []citation
}

@ |twinx| reads the files one by one, merging their entries into |entries| by
head, and then writes the master index. Two entries are the same if they are set
the same; an identifier set in italic in one program and in bold in another
makes two entries, as in Knuth's \.{twinx}, where they differed in ``ilk.''
@<Functions@>=
func twinx(files []string, w io.Writer) error {
	byHead := map[string]*entry{}
	var entries []*entry
	for _, name := range files {
		data, err := os.ReadFile(name)
		if err != nil {
			return err
		}
		@<Find the title of the program in |data|@>
		@<Merge the index entries of |data| into |entries|@>
	}
	@<Sort the entries@>
	@<Write the master index@>
}

@ The title is the argument of the first \.{\\def\\title} that begins a line; a
file without one is cited by its own name, with a complaint.
@<Find the title of the program in |data|@>=
title := strings.TrimSuffix(name, ".tex")
found := false
for _, ln := range strings.Split(string(data), "\n") {
	if rest, ok := strings.CutPrefix(ln, "\\def\\title"); ok {
		if t, _, ok := group(rest, 0); ok {
			title, found = t, true
			break
		}
	}
}
if !found {
	fmt.Fprintf(os.Stderr, "gtwill-twinx: (no title found in file %s)\n", name)
}

@ The index runs from the line \.{\\inx} to the line \.{\\fin}. A line there that
is not an entry is one we cannot deal with, and we say so.
@<Merge the index entries of |data| into |entries|@>=
inIndex := false
for n, ln := range strings.Split(string(data), "\n") {
	switch {
	case ln == "\\inx":
		inIndex = true
	case ln == "\\fin":
		inIndex = false
	case inIndex && strings.HasPrefix(ln, "\\II"):
		@<Add the entry on the line |ln|@>
	case inIndex && ln != "":
		fmt.Fprintf(os.Stderr, "gtwill-twinx: couldn't deal with %s:%d: %.20s...\n", name, n+1, ln)
	}
}

@ @<Add the entry on the line |ln|@>=
head, i, ok := group(ln, 3)
secs, _, ok2 := group(ln, i)
if !ok || !ok2 {
	return fmt.Errorf("%s:%d: unbalanced entry: %.30s...", name, n+1, ln)
}
e := byHead[head]
if e == nil {
	e = &entry{head: head, key: headKey(head)}
	byHead[head] = e
	entries = append(entries, e)
}
e.cites = append(e.cites, citation{title, secs})

@ |group| returns the contents of the braced group that begins at |s[i]|, and the
index just past it. A brace after a backslash, as in \.{\char`\\\{}, is not a
brace to \TEX/, and is not counted.
@<Functions@>=
func group(s string, i int) (string, int, bool) {
	if i >= len(s) || s[i] != '{' {
		return "", i, false
	}
	depth := 0
	for j := i; j < len(s); j++ {
		switch s[j] {
		case '\\':
			j++
		case '{':
			depth++
		case '}':
			if depth--; depth == 0 {
				return s[i+1 : j], j + 1, true
			}
		}
	}
	return "", i, false
}

@ The entries are sorted by key, and entries with equal keys by their heads, as
\.{gtwill} sorts its own index.
@<Sort the entries@>=
sort.SliceStable(entries, func(a, b int) bool {
	if entries[a].key != entries[b].key {
		return entries[a].key < entries[b].key
	}
	return entries[a].head < entries[b].head
})

@ Each entry becomes a line \.{\\I\{}$\eta$\.{\}\{}$\ldots$\.{\}} whose second
argument cites each program with \.{\\twinxref\{}{\it title\/}\.{\}\{}$\sigma$\.{\}};
\.{gtwinxmac.tex} sets them in two columns.
@<Write the master index@>=
out := bufio.NewWriter(w)
fmt.Fprintln(out, "\\input gtwinxmac")
fmt.Fprintln(out, "\\twinxtop")
fmt.Fprintln(out, "\\inx")
for _, e := range entries {
	fmt.Fprintf(out, "\\I{%s}{", e.head)
	for _, c := range e.cites {
		fmt.Fprintf(out, "\\twinxref{%s}{%s}", c.title, c.secs)
	}
	fmt.Fprintln(out, "}")
}
fmt.Fprintln(out, "\\fin")
fmt.Fprintln(out, "\\end")
return out.Flush()

@* Sorting.
The head is set as \.{gtwill}'s index sets it: \.{\\ID\{foo\\\_bar\}} for an
ordinary name, \.{\\KW} for a type, \.{\\MAC} in typewriter, where an underscore
is \.{\\char95}, \.{\$\\foo\$} for a name that the web formats as the control
sequence \.{\\foo}, and \.{\\IR}, \.{\\IT}, or \.{\\IC} for an entry made by hand.
|headKey| recovers the name from the head, the way that \.{gtwill-refsort}
recovers it from a mini-index entry, and maps it to the collating order. In an
\.{\\IC} entry only the key before \.{\}\{} counts, as in \.{gtwill}'s index;
in the other entries a control symbol is its symbol.
@<Functions@>=
func headKey(head string) string {
	if strings.HasPrefix(head, "\\IC{") {
		if k := strings.Index(head, "}{"); k >= 0 {
			head = head[:k]
		}
	}
	var b []byte
	first := true
	for i := 0; i < len(head); i++ {
		c := head[i]
		switch {
		case c == '\\' && i+1 < len(head) && isLetter(head[i+1]):
			@<Translate the control word at |i|@>
		case c == '\\' && i+1 < len(head):
			i++
			b = append(b, collateRank[head[i]])
		case c == '{' || c == '}' || c == '$':
		default:
			b = append(b, collateRank[c])
		}
	}
	return string(b)
}

@ A \.{\\char} code becomes its character and \.{\\SP} a blank; the first control
word, which sets the style, is dropped, unless it is the custom one of a
\.{\$\\foo\$} head, whose letters are the name.
@<Translate the control word at |i|@>=
j := i + 1
for j < len(head) && isLetter(head[j]) {
	j++
}
switch word := head[i+1 : j]; {
case word == "char":
	code := 0
	for j < len(head) && head[j] >= '0' && head[j] <= '9' {
		code = 10*code + int(head[j]-'0')
		j++
	}
	b = append(b, collateRank[byte(code)])
case word == "SP":
	b = append(b, collateRank[' '])
case first && head[0] != '$':
	// the style
default:
	for k := i + 1; k < j; k++ {
		b = append(b, collateRank[head[k]])
	}
}
if j < len(head) && head[j] == ' ' {
	j++ // the blank that ends a control word
}
first = false
i = j - 1

@ @<Functions@>=
func isLetter(c byte) bool { return 'a' <= c && c <= 'z' || 'A' <= c && c <= 'Z' }

@ The collating order is \.{gtwill}'s, and \.{cweave}'s: the punctuation, then the
underscore, then the letters with upper and lower case alike, then the digits,
then the bytes beyond {\mc ASCII}.
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
Two programs share an entry and each has one of its own; the master index
merges the shared one, in the order of the files, and sorts the rest.
@(twinx_test.go@>=
package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestTwinxMerges(t *testing.T) {
	dir := t.TempDir()
	a := filepath.Join(dir, "a.tex")
	b := filepath.Join(dir, "b.tex")
	os.WriteFile(a, []byte("\\input gtwimac\n\\def\\title{ALPHA}\n\\inx\n"+
		"\\II{\\KW{Graph}}{\\SND{3}, \\SN{9}}\n\\II{\\ID{zeta}}{\\SN{4}}\n\\fin\n"), 0o644)
	os.WriteFile(b, []byte("\\def\\title{BETA}\n\\inx\n"+
		"\\II{\\KW{Graph}}{\\SN{2}}\n\\II{\\MAC{MAX\\char95 N}}{\\SND{1}}\n\\fin\n"), 0o644)
	var out strings.Builder
	if err := twinx([]string{a, b}, &out); err != nil {
		t.Fatal(err)
	}
	want := `\input gtwinxmac
\twinxtop
\inx
\I{\KW{Graph}}{\twinxref{ALPHA}{\SND{3}, \SN{9}}\twinxref{BETA}{\SN{2}}}
\I{\MAC{MAX\char95 N}}{\twinxref{BETA}{\SND{1}}}
\I{\ID{zeta}}{\twinxref{ALPHA}{\SN{4}}}
\fin
\end
`
	if out.String() != want {
		t.Errorf("got\n%s\nwant\n%s", out.String(), want)
	}
}

@ The keys follow \.{gtwill}'s index: |x_1| before |xa|, case ignored, and an
\.{\\IC} entry by its key.
@(twinx_test.go@>=
func TestTwinxKeys(t *testing.T) {
	order := []string{`\IC{Konig}{K\H{o}nig}`, `\IR{Lamport}`, `\ID{x\_1}`, `\ID{xa}`, `$\xone$`}
	for i := 1; i < len(order); i++ {
		if headKey(order[i-1]) >= headKey(order[i]) {
			t.Errorf("%s should sort before %s", order[i-1], order[i])
		}
	}
}

@* Index.
