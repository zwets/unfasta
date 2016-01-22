# unfasta

_Command-line pipes and filters for genomic sequence data._


## Introduction

[Unfasta](http://io.zwets.it/unfasta) is a suite of command-line utilities for working with sequence data.

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

Pipelines are a simple and powerful way to process large streams of data, but the FASTA format is the party pooper.  By allowing sequences to span multiple lines, FASTA defies processing by line-oriented standard tools.  Even a seemingly obvious `fgrep -q 'GAATCATCTTTA'` fails with a false negative in 10-15% of cases.  Unfasta came about out of frustration over this missed opportunity.

Unfasta solves the issue by converting FASTA format to 'unfasta format' when it enters the pipeline.  The unfasta format is simply FASTA without line breaks in the sequence data.  As is explained below, [unfasta files are still valid FASTA files](#unfasta-is-fasta).

Unfasta isn't intended as the be-all and end-all of genomic sequence processing.  It won't work for everyone.  It does for me because I usually work in bash and have been using the Unix/GNU toolset for twenty years.  Over that period I have written software in at least a dozen 'proper' programming languages, but when it comes to string processing nothing beats piping together a quick one-liner in bash.  If you recognise this, then unfasta will work for you.

If your natural preference is to work in a graphical user environment, then unfasta may be the occasion to get out of your comfort zone and discover the beauty and power of the command line.


## Design principles

### The unfasta file format

The unfasta file format is FASTA with no line breaks in the sequence data.  For example:

    >id1 Sequence title 1
    CGCACTGTGGCCCCCGAATCTATCTTTACGGC... (indefinite length sequence terminated by newline) 
    >id2 Sequence title 2
    SEQUENCE DATA ...
    ...

As in FASTA, there can be an arbitrary number of sequences of arbitrary length.  Contrary to FASTA, the sequence data cannot be broken across lines.  Therefore every sequence is serialised in exactly two lines.  Every odd-numbered line starts with `>` and is a header line.  Every even-numbered line is a sequence line.

The [`uf`](uf) command (filter) converts a stream of FASTA to a stream of unfasta.  It can also do the reverse, but read section [unfasta *is* FASTA](#unfasta-is-fasta) first.

##### Header line syntax

The **header line** must start with `>`, immediately followed by the sequence identifier.  The sequence identifier must contain no whitespace.  NCBI specifies additional constraints on the sequence identifier [here](http://ncbi.github.io/cxx-toolkit/pages/ch_demo#fasta-sequence-id-format), summarised [here](http://io.zwets.it/blast-cmdline-ref).  A summary may be followed by whitespace and a sequence title consisting of arbitrary text.

##### Sequence line syntax

The sequence line can contain any character except newline (which terminate it).  However to be useful it should contain only characters defined by IUPAC here.  @@@HERE@@@  however to make sense.   except 

### Open Ends

* [ ] extend `uf` to convert also EMBL format data
* [ ] check what to do with whitespace in sequence data (currently `uf` removes ALL whitespace)

#### Why the unfasta format?

Some examples will illustrate the benefits of the unfasta file format.

Extract all deflines using `sed` or `awk`:

```bash
$ sed -n 1~2p
$ awk 'NR%2==1'
```
  
Extract the data for the 3rd and 12th sequence:

```bash
$ sed -n 7,25p
```

Extract the header and sequence data for identifier `gi|22888`:

```bash
$ sed -n '/>gi|22888 /,+1p'
```

Extract the bases at positions 952-1238 in the first sequence:

```bash
$ sed -n 2p | cut -b 952-1238
```

Extract a 500 base fragment at position 135:

```bash
$ tail -c +135 | head -c 500	# or: cut -b 135-$((134+500))
```

How long are the Borrelia sequences?

```bash
$ awk '/Borrelia/ { getline; print length; }'
```

Does any sequence contain fragment `ACGTATAGCGGC`? 

```bash
# Wouldn't fgrep work for FASTA files too?  No, you'd get a false negative
# about once every 15 queries (at query length 12).  Pesky line breaks.
$ fgrep -q 'ACGTATAGCGGC' && echo "Yes" || echo "No"
```

#### Unfasta *is* FASTA

Technically, every unfasta file is a also a FASTA file.  There is no formal specification of the FASTA format, but none of the *de facto* specifications (see the [links below](#fasta-specification)) **mandate** a maximum line length.  Several **recommend** an 80 or 120 character limit.  My favourite interoperability adage _"be strict in what you send, lenient in what you accept"_ then implies that software which consumes FASTA must tolerate indefinite line lengths, while software that produces FASTA must write 80 character lines.

The `uf` tool has a --revert option which does precisely this.  But since the character limit recommendation was set [over 30 years ago](https://en.wikipedia.org/wiki/FASTA)!), technological progress has obliterated its reasons for existence, and I fail to see why we should continue to stick with them.  And of course, any FASTA consumer which fails to read longer lines _does_ violate the spec -- the length limit is only a *recommendation*, right?)  In short, don't revert unfasta back to FASTA and let's see if anything breaks.


### Pipes and Filters architecture

#### Bash is perfect for pipelines

Bash, or indeed any POSIX shell, natively supports pipelines in the most parsimonious way.  A minimum of syntax, a single `|` character, suffices to spawn two concurrent processes and a communication channel between them.  Neither process needs to be specifically written or adapted to participate in a pipeline.  Pipes connect the standard output of the left hand side process to the standard input of the right hand side process.  Processes read from their standard input and write to their standard output without being aware that there is a file or another process at either end.

#### Why pipelines are good

Shell pipelines like the GC-counter in the [Introduction](#introduction) are highly efficient, in more ways than you would realise:

* _I/O_. Apart from the obvious initial read, the pipeline performs no disc I/O.  All data travels in-memory from process to process.
* _Storage_. There is no intermediate storage of data.  Disc space requirement of the pipeline is zero.
* _Memory_. Each of the four processes needs only analyse a single byte at a time.  The theoretical memory requirement of the pipeline is 4 bytes.
* _Time_. The four processes run concurrently.  Theoretical time requirement is no worse than that of the slowest process.  The transparent parallelism provided by shell pipelines is underrated.

Apart from run-time efficiency, the pipes and filters approach of chaining simple tools together has benefits such as robustness, reusability, and simplicity in terms of cognitive load.  It suffices to understand the individual tools in order to understand their composition -- which in turn is just another stream processor.  As in functional programming (that is, in the absence of side-effects), cognitive load goes up linearly with the number of parts, not quadratically as it does in effectful systems where _N_ parts yield _N×N_ potential interactions to take into account.


### Other design decisions

#### No Singletons

As in FASTA, an unfasta file contains a list of zero (does FASTA support this?) or more 'records' where record is a defline and a sequence.  All unfasta filters (`uf-*`) operates on all records in a FASTA file.  As in the R Language, single records are no special case, they are a lists of one element.

#### Comply with BLAST practices

The FASTA definition may be underspecified, but the defline definition even more so.  BLAST does put some requirements on it.  E.g. it must start with `>` followed immediately (no space) by an identifier which must not contain spaces, followed by an optional title.  The identifier must conform to a list (there are multiple ,,,), but can apparently also be a concatenation?  Local sequences must have prefix `lcl` or `gnl`.

#### Requirements for filters

Filters must read standard input and write to standard output.  Filters must produce valid unfasta output, that is pairs of lines with the first starting with `>` and the second @TODO@ what requirements for the SEQUENCE DATA?  Pragmatics: filters must be self-documenting, that is support at least the `--help` option.

#### Zero-length sequences

Unfasta supports zero-length sequences. (Does FASTA support these? If not, how to export them?)  They look like this:

    >ident1 An empty sequence
    
    >ident2 The next sequence
    SEQUENCE DATA

There are two reasons to support zero-length sequences.  Firstly, a zero-length sequence could arise in the course of a pipeline, so we must at that point either error out (because it is [required](#requirements-for-filters) that filters produce valid unfasta, or output the zero-length sequence.  Secondly, zero-length sequences fit in well with the functional (algebraic) definition of a sequence: a sequence is either the empty sequence, or an element (base, character) followed by a sequence.

#### Infinite sequences

Infinite sequences are not relevant to unfasta.  Unfasta is a file format, and no finite file can represent an infinite sequence.  In a processing node, an infinite sequence can exist, but it cannot be streamed out.  (Infinite sequences make sense for circular genomes or peptides.)

## Miscellaneous

### Useful Links

#### FASTA Specification

* [Wikipedia entry FASTA format](https://en.wikipedia.org/wiki/FASTA_format)
* [NCBI BLAST specification](http://blast.ncbi.nlm.nih.gov/blastcgihelp.shtml)
* [NCBI Sequence Identifier convention](http://ncbi.github.io/cxx-toolkit/pages/ch_demo)
* [BioStars Discussion](https://www.biostars.org/p/11254/)
* [Genomatix overview of DNA Sequence Formats](https://www.genomatix.de/online_help/help/sequence_formats.html)
* [Sequence Ontology Project](http://www.sequenceontology.org/)

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

