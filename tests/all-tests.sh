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
#
#  Created on 2016-01-16

# Function to exit this script with an error message on stderr
err_exit() {
	echo "$(basename "$0"): $*" >&2
	exit 1
}

# Function to show usage information and exit
usage_exit() {
	echo
	echo "Usage: $(basename $0) [OPTIONS]"
	echo
	echo "  Run all tests."
	echo
	exit ${1:-1}
}

# Parse options

while [ $# -ne 0 -a "$(expr "$1" : '\(.\).*')" = "-" ]; do
	case $1 in
	-h|--help)
		usage_exit 0
		;;
	*) usage_exit
		;;
	esac
	shift
done

# @TODO@: look at https://github.com/illusori/bash-tap.git for testing.

err_exit "

  sole hand in spring forest
  claps as tree falls soundlessly
  no tests fail to fail
"

