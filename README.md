# unfasta

_Command-line pipes and filters for genomic sequence data._


## Introduction

[Unfasta](http://github.com/zwets/unfasta) is a suite of command-line utilities for working with sequence data.

The rationale behind unfasta is to have the ability to process genomic sequence data using simple standard utilities like `grep`, `cut` and `head`, in the common [pipes and filters style](http://www.dossier-andreas.net/software_architecture/pipe_and_filter.html) of Unix and GNU.

For instance,

```bash
# Compute the GC content of all sequences in a FASTA file
uf 'file.fa' | sed -n '2~2p' | tr -dc 'GC' | wc -c
```

In that pipeline,

* `uf` reads a FASTA file and outputs it in 'unfasta' format, collapsing sequence data to single lines;
* `sed -n 2~2p` filters every second line from its input, thus dropping the header lines;
* `tr -dc GC` drops from its input all characters except `G` and `C`;
* and `wc -c` counts the number of characters it reads, then writes this to standard output.

Pipelines are a simple and powerful way to process large streams of data, but the FASTA format is the party pooper.  By allowing sequences to span multiple lines, FASTA defies processing by standard line-oriented tools.  Even a seemingly obvious `fgrep -q 'GAATCATCTTTA'` fails with a false negative in 10-15% of cases.  Unfasta originated from frustration over this missed opportunity.

Unfasta resolves the issue by converting FASTA format to 'unfasta format' when it enters the pipeline.  The unfasta format is FASTA without line breaks in the sequence data.  As is explained below, [unfasta files are still valid FASTA files](#unfasta-is-fasta).

##### Motivating examples

Some examples to illustrate the benefits of single-line sequence data:

```bash
# Extract all deflines using sed or awk
$ sed -n 1~2p
$ awk 'NR%2==1'

# Extract the data for the 3rd and 12th sequence
$ sed -n 7,25p

# Extract the header and sequence data for identifier 'gi|22888'
$ sed -n '/[>|]gi|22888[| $]/,+1p'

# Extract the bases at positions 952-1238 in the first sequence
$ sed -n 2p | cut -b 952-1238

# Extract a 500 base fragment at position 135
$ tail -c +135 | head -c 500	# or: cut -b 135-$((134+500))

# How long are the Borrelia sequences?
$ awk '/Borrelia/ { getline; print length; }'

# Does any sequence contain fragment 'ACGTATAGCGGC'? 
$ fgrep -q 'ACGTATAGCGGC' && echo "Yes" || echo "No"
```

##### Audience for unfasta

Unfasta isn't intended as the be-all and end-all of genomic sequence processing.  It won't work for everyone.  It does for me because I usually work in bash and have been using the Unix/GNU toolset for over two decades.  In that same period I have written software in at least a dozen 'proper' programming languages, but when it comes to string processing nothing beats piping together a one-liner in bash.  If you recognise this, then unfasta will work for you.

If your natural preference is to work in a graphical user environment, then unfasta may be just the occasion to get out of your comfort zone and discover the beauty and power of the command line.

Find [Unfasta on GitHub](http://github.com/zwets/unfasta).



## Current unfasta collection

|Tool|Description|
|----|-----------|
|`uf`| Convert FASTA to unfasta |
|`uf-bare`| Strip the headers, output only the bare sequences |
|`uf-circut`| Cut sections out of circular sequences, allowing wraparound |
|`uf-cut`| Cut sections from linear sequences |
|`uf-dress`| Undo the effect of `uf-bare`: add headers to a stream of bare sequence data |
|`uf-drop`| Drop the initial N elements from a sequence, or drop elements until N are left |
|`uf-freqs`| Count the frequencies of elements in sequences |
|`uf-headers`| Strip the sequence data, output only the sequence headers |
|`uf-map`| Apply an operation to every line of sequence data in turn |
|`uf-random`| Generate random sequences of DNA, RNA, amino acids, or any other alphabet |
|`uf-rc`| Reverse and/or complement a stream of unfasta |
|`uf-select`| Select sequences by position or by grepping their header for a regular expression |
|`uf-take`| Take the initial N elements from a sequence, or take elements until N are left |
|`uf-valid`| Validate an unfasta stream against its allowed alphabet and NCBI conventions |

Each has a `-h|--help` option for usage instructions.  All depend only on `awk` and a POSIX shell, except `uf-random` which requires `bash` for its `RANDOM` extension.


## Design principles

### The unfasta file format

The unfasta file format is FASTA with no line breaks in the sequence data.  For example:

    >id1 Sequence title 1
    CGCACTGTGGCCCCCGAATCTATCTTTACGGC... (indefinite length sequence terminated by newline) 
    >id2 Sequence title 2
    SEQUENCE DATA ...
    ...

The [`uf`](uf) command (filter) converts a stream of FASTA to a stream of unfasta.  It can also do the reverse, but read section [unfasta *is* FASTA](#unfasta-is-fasta) first.

##### Overall structure

As in FASTA, there can be an arbitrary number of sequences of arbitrary length.  Contrary to FASTA, the sequence data cannot be broken across lines.  Therefore every sequence is serialised in exactly two lines.  Every odd-numbered line starts with `>` and is a header line.  Every even-numbered line is a sequence line.

##### Header line syntax

The header line must start with `>`, immediately followed by the _sequence identifier_.  The sequence identifier must contain no whitespace.  NCBI [specifies](http://ncbi.github.io/cxx-toolkit/pages/ch_demo#fasta-sequence-id-format) additional constraints on the sequence identifier, summarised [here](http://io.zwets.it/blast-cmdline-ref/#about-sequence-identifiers), and allows the sequence identifier to consist of multiple concatenated sequence identifiers[\*](#footnotes).  The sequence identifier may be followed by whitespace followed by a _sequence title_ consisting of arbitrary text.

##### Sequence line syntax

The sequence line can syntactically contain any character except newline (which terminates it).  However to be semantically valid it must contain only characters defined by IUPAC, and listed in the [NCBI Blast Specification](http://blast.ncbi.nlm.nih.gov/blastcgihelp.shtml).  Note that `uf` does not check the validity of the characters in the input FASTA file but copies them verbatim to stdout, removing only whitespace.  Use the `uf-valid` filter to check sequence validity.

#### Unfasta *is* FASTA

Technically, every unfasta file is a also a FASTA file.  None of the *de facto* specifications (see the [links below](#fasta-specification)) of the FASTA format **mandate** a maximum line length.  Several **recommend** an 80 or 120 character limit.  My favourite interoperability adage _"be strict in what you send, lenient in what you accept"_ would then imply that software which consumes FASTA must tolerate indefinite line lengths, while software that produces FASTA must write 80 character lines.

The `uf` tool has a `--revert` option which does precisely this.  However the character limit recommendation was set [over 30(!) years ago](https://en.wikipedia.org/wiki/FASTA).  Any reasons for its existence have long since been obliterated by technological progress.  What's more, any FASTA consumer which fails to read longer lines _does_ violate the spec -- the limit is a *recommendation*, right?  In short, I suggest not reverting unfasta back to 'length-capped FASTA' and finding out if anything breaks.  In the unlikely case that it does, then that needs fixing.


### Pipes and filters architecture

#### Bash is perfect for pipelines

Bash, or indeed any POSIX shell, natively supports pipelines in the most parsimonious way.  The bare minimum of syntax, a single `|`, suffices to spawn two concurrent processes and create a communication channel between them.  Neither process needs to be specifically written or adapted to participate in a pipeline.  Processes read from their standard input and write to their standard output without being aware whether there is a file or another process at either end.

#### Pipelines are highly efficient

Shell pipelines like the GC-counter in the [Introduction](#introduction) are highly efficient.  Repeating it here for reference,

```bash
# Compute the GC content of all sequences in a FASTA file
uf 'file.fa' | sed -n '2~2p' | tr -dc 'GC' | wc -c
```

This pipeline is efficient in more ways than you might realise:

* **I/O**. Apart from the obvious initial read, the pipeline performs no disc I/O.  All data travels in-memory from process to process.
* **Storage**. There is no intermediate storage of data.  Disc space requirement of the pipeline is zero.
* **Memory**. Each of the four processes needs only analyse a single byte at a time.  The theoretical memory requirement of the pipeline is 4 bytes.
* **Time**. The four processes run concurrently.  Theoretical time requirement is no worse than that of the slowest process.  The transparent parallelism provided by shell pipelines is underrated.

#### Pipelines are inherently simple

Apart from run-time efficiency, the pipes and filters approach of chaining simple tools together has benefits such as robustness, reusability, and simplicity in terms of cognitive load.  In a pipeline architecture it suffices to understand the individual filters in order to understand the whole -- which in turn is just another filter.  As in functional programming (that is, in the absence of side-effects), cognitive load goes up only linearly with the number of parts, not quadratically as it does in effectful systems where _N_ parts yield _N×N_ potential interactions to take into account.


### Miscellaneous design decisions

#### Lists of sequences

As in FASTA, an unfasta file contains a list of zero (does FASTA support this?) or more 'records', where a record is a pair of a header and a sequence.  All unfasta filters (`uf-*`) operate on all records in a FASTA file.  As in the R Language, there is no special case for a single record.  It is simply a list of one element.

#### Comply with BLAST practices

Stick with the NCBI BLAST specifications for FASTA header lines, sequence identifiers and sequence data, as specified in the [NCBI BLAST specification aka "Web BLAST page options"](http://blast.ncbi.nlm.nih.gov/blastcgihelp.shtml), and the [NCBI Sequence Identifier specification as hidden in the bottom drawer of a locked filing cabinet stuck in a disused lavatory with a sign of the door saying "Beware of the Leopard"](http://www.goodreads.com/quotes/40705-but-the-plans-were-on-display-on-display-i-eventually), aka ["Table 5"](http://ncbi.github.io/cxx-toolkit/pages/ch_demo#ch_demo.T5) in the Examples and Demos chapter of the NCBI C++ Toolkit Handbook.[\*\*](#footnotes).

#### Requirements for filters

Filters must read standard input and write to standard output.  Filters must produce valid unfasta output, that is pairs of lines with the first starting with `>` and the second having sequence data.  For constraints on the sequence data, refer to `uf-valid`.  Filters must be self-documenting, that is support at least the `--help` option.  

The self-documentation requirement is the reason why several of the `uf-*` tools have been implemented as shell scripts while a simple alias would suffice.  E.g. `uf-bare` could have just been `alias uf-bare='awk "NR%2==1"'`, but then there would be no `uf-bare --help`.

#### Zero-length sequences

Unfasta supports zero-length sequences. (Does FASTA support these? If not, how to export them?)  They would look like this on the line:

    >ident1 An empty sequence
    
    >ident2 The next sequence
    SEQUENCE DATA

There are two reasons to support zero-length sequences.  Firstly, a zero-length sequence could arise in the course of a pipeline, so we must at that point either error out (because it is [required](#requirements-for-filters) that filters produce valid unfasta, or output the zero-length sequence.  Secondly, zero-length sequences fit in well with the functional (algebraic) recursive definition of a sequence: a sequence is either the empty sequence, or an element followed by a sequence.



## Miscellaneous

### Useful Links

#### FASTA Specifications

* [Wikipedia entry FASTA format](https://en.wikipedia.org/wiki/FASTA_format)
* [NCBI BLAST specification (Web BLAST page options)](http://blast.ncbi.nlm.nih.gov/blastcgihelp.shtml)
* [NCBI Sequence Identifier specification (Table 5)](http://ncbi.github.io/cxx-toolkit/pages/ch_demo)
* [BioStars Discussion](https://www.biostars.org/p/11254/)
* [Genomatix overview of DNA Sequence Formats](https://www.genomatix.de/online_help/help/sequence_formats.html)
* [Sequence Ontology Project](http://www.sequenceontology.org/)

### Open Issues

* [ ] extend `uf` to also convert EMBL format data

### Glossary

bare sequence, raw sequence
: sequence data for a single sequence without the associated header

defline
: Abbreviation for "definition line", NCBI synonym for the header line.

header
: Tuple of a sequence identifier and an optional sequence title.  Serialised as a header line.  Associated with sequence data.

header line
: The line preceding one or more lines of sequence data in FASTA (and hence in unfasta).  It must start with `>` immediately followed by the sequence identifier.  Whitespace terminates the identifier.  Optional text following the whitespace is called the sequence title.

filter
: A processing component in a pipeline which is both a sink and a source.

pipe
: A channel connecting a source with a sink.

sequence
: Tuple of a bare sequence and its header.  Serialised in unfasta as a sequence record.  Also used as short for sequence record.  Also used as short for bare sequence.

sequence record
: The serialised form of a sequence in an unfasta file, being a header line followed by a sequence line.

sequence line
: The line containing the sequence data for a single sequence in an unfasta format file.  Must be preceded by its associated header line.  Avoid this term for FASTA as it has multiple lines containing data for a single sequence.

sink
: A component in a pipeline which consumes data from its standard input.  Every filter is a sink.  Not every sink is a filter.

source
: A component in a pipeline which writes data to its standard output.  Every filter is a source.  Not every source is a filter.

### License

unfasta - command-line pipes and filters for genomic sequence data  
Copyright (C) 2016  Marco van Zwetselaar

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

### Footnotes

\*) Who makes this up?  NCBI specifies that multiple sequence identifiers must be separated by `|`, the same character that is used _within_ identifiers.  This makes it impossible to parse the list of identifiers without knowing the internal structure of every possible identifier ahead of time -- instant forward incompatibility.  Why not use a different separator?  Why not reuse the `>`?

\*\*) Yes, I have a peeve with that.  I'm baffled by the neglect for formalism when the whole purpose of the effort is enabling interchange of data.  When you set a standard, be explicit about it: make it identifiable, give it a **name**, give it a URI.  Don't call it "Web BLAST Page Options" or name it "Table 5" and put it in the _Examples and Demos_ section of a handbook.`</miff-mode>`

