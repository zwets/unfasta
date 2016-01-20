# unfasta

_Command-line pipes and filters for genomic sequence data._


## Introduction

[Unfasta](http://io.zwets.it/unfasta) is a suite of command-line utilities for working with sequence data.

The rationale behind unfasta is to have the ability to process genomic sequence data using simple standard utilities like `grep`, `cut` and `head`, in the common [pipes and filters](http://www.dossier-andreas.net/software_architecture/pipe_and_filter.html) style of Unix and GNU.

For instance:

```bash
# Compute the GC content of all sequences in a FASTA file
uf file.fa | sed -n 2~2p | tr -dc 'GC' | wc -c
```

Here:

* `uf` reads a FASTA file and outputs it in 'unfasta' format (explained [below](#the-unfasta-file-format), but essentially just FASTA without line breaks in the sequence data)
* `sed` filters every second line from its input, the even-numbered lines having the sequence data
* `tr` drops from its input all characters except `G` and `C`
* `wc` counts the number of characters it reads and writes this to standard output

Simple shell pipelines like this are highly efficient, in more ways than you'd realise:

* _I/O_. Apart from the obvious initial read, the pipeline performs no disc I/O.  All data travels in-memory from process to process.
* _Storage_. There is no intermediate storage of data.  Disc space requirement of the pipeline is zero.
* _Memory_. Each of the four processes needs only analyse a single byte at a time.  The theoretical memory requirement of the pipeline is 4 bytes.
* _Time_. The four processes run concurrently.  Theoretical time requirement is no worse than that of the slowest process.  The transparent parallelism provided by shell pipelines is underrated.

Apart from run-time efficiency, the pipes and filters approach of chaining simple tools together has benefits such as robustness, reusability, and simplicity in terms of cognitive load.  It suffices to understand the individual tools in order to understand their composition -- which in turn is just another stream processor.  As in functional programming (that is, in the absence of side-effects), cognitive load goes up linearly with the number of parts, not quadratically as it does in effectful systems where _N_ parts yield _N×N_ potential interactions to consider.

Unfasta won't work for everyone.  For those who grew up with `sh` and the likes of `grep`, `sed`, and `awk`, unfasta will be second nature.  For those more used to looking at the world through a window while holding a mouse: welcome outside!


## Design principles

### The `unfasta` file format

The `unfasta` file format is FASTA with no line breaks in the sequence data.  So, an unfasta file could look like this:

    >id1 Sequence title 1
    CGCACTGTGGCCCCCGAATCTATCTTTACGGC... indefinite length sequence containing any character except new line
    >id2 Sequence title 2
    SEQUENCE DATA ...
    ...

As in FASTA, there can be an arbitrary number of sequences of arbitrary length.  Contrary to FASTA, sequences are never broken across lines.  This implies that every odd-numbered line starts with `>` and is a comment, and every even-numbered line contains sequence data.

#### Why this is good

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

Technically, every unfasta file is a also a FASTA file.  To the extent that there is a formal specification for the FASTA file format, this specification does not *mandate* a maximum line length.  The 80 and 120 character limits are *recommendations*.  My favourite interoperability adage _"be strict in what you send, be lenient in what you accept"_ then implies that software which consumes FASTA must tolerate indefinite line lengths, while software that produces FASTA must write either 80 or 120 character lines.

As an experiment, I will violate the first half of my adage until I find a tool which breaks on long lines, and I encourage others to do the same.  I will post my findings here.


## Miscellaneous

### License

`unfasta` - command-line pipes and filters for genomic sequence data  
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

