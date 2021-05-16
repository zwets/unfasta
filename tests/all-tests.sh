#!/bin/sh
#
#  all-tests.sh - Run all tests for the unfasta suite of tools
#  Copyright (C) 2016  Marco van Zwetselaar <io@zwets.it>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Function to exit this script with an error message on stderr
err_exit() { echo "$(basename "$0"): $*" >&2; exit 1; }

# Function to show usage information and exit
usage_exit() {
    echo "
Usage: $(basename $0) [OPTIONS]

  Run all tests.

  OPTIONS
   -h, --help  Show this information and exit
" && exit ${1:-1}
}

# Parse options

while [ $# -ne 0 -a "$(expr "$1" : '\(.\).*')" = "-" ]; do
    case $1 in
    -h|--help) usage_exit 0 ;;
    *) usage_exit ;;
    esac
    shift
done

### Test uf

cd "$(dirname "$0")"

E='>Sequence 0
>Sequence 1
1234
>Sequence 2
1234
>Sequence 3
1234
>Sequence 4
1234'
EE="$E
$E"

UF="../uf"
T="testdata.fa"
Z="testdata.fa.gz"
F="faulty.fa"

# Test UF with valid input
[ "$E" = "$($UF $T)" ]             || err_exit "failed: test 1"
[ "$E" = "$(cat $T | $UF)" ]       || err_exit "failed: test 2"
[ "$E" = "$(cat $T | $UF -)" ]     || err_exit "failed: test 3"
[ "$EE" = "$(cat $T $T | $UF)" ]   || err_exit "failed: test 4"
[ "$EE" = "$($UF $T $T)" ]         || err_exit "failed: test 5"
[ "$EE" = "$(cat $T | $UF $T -)" ] || err_exit "failed: test 6"
[ "$EE" = "$(cat $T | $UF - $T)" ] || err_exit "failed: test 7"

# Test UF with gzipped valid input
[ "$E" = "$($UF $Z)" ]             || err_exit "failed: test 1"
[ "$E" = "$(cat $Z | $UF)" ]       || err_exit "failed: test 2"
[ "$E" = "$(cat $Z | $UF -)" ]     || err_exit "failed: test 3"
[ "$EE" = "$(cat $Z $Z | $UF)" ]   || err_exit "failed: test 4"
[ "$EE" = "$($UF $Z $Z)" ]         || err_exit "failed: test 5"
[ "$EE" = "$(cat $Z | $UF $Z -)" ] || err_exit "failed: test 6"
[ "$EE" = "$(cat $Z | $UF - $Z)" ] || err_exit "failed: test 7"

# Test UF with faulty input
! $UF $F 2>/dev/null || err_exit "failed: test 8" 

# vim: sts=4:sw=4:et:si:ai
