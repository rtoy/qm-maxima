#!/bin/bash

usage ()
{
    echo "gen_docs.sh [-hD] [-M maxima] package"
    echo "    -M maxima     Path to Maxima. Defaults to maxima."
    echo "    -D            Enable debugging messages"
    echo "    -h            This help"
    echo "    package       Basename of texi file"

    exit 1
}

MAXIMA=maxima
DEBUG=

while getopts "M:hD" arg
do
    case $arg in
        M) MAXIMA=$OPTARG ;;
        D) DEBUG=yes ;;
        h) usage ;;
    esac
done

shift `expr $OPTIND - 1`
# Package is required
if [ $# -lt 1 ]; then
    usage
fi

package="$1"

if [ ! -f "$package.texi" ]; then
    echo "$package.texi is not a file"
    exit 2
fi

# Get the maxima source dir
SRCDIR=`$MAXIMA -d | grep srcdir | sed 's/maxima-srcdir=\(.*\)/\1/'`

buildindex=$SRCDIR/../doc/info/build_index.pl

if [ -n "$DEBUG" ]; then
    set -x
fi

makeinfo $package.texi
makeinfo --pdf $package.texi
makeinfo --split=chapter --no-node-files --html \
	 -c OUTPUT_ENCODING_NAME=UTF-8 -e 10000 $package.texi

# build the .info index
$buildindex $package.info > $package-index.lisp

# Build the batch string in pieces here to make shell quoting easier.
DIR="${package}"'_html/*.html'
OUTPUT="${package}"-index-html.lisp
BATCH=`echo build_and_dump_html_index\(\"$DIR\", output_file=\"$OUTPUT\", truenamep=true\)\;`

$MAXIMA --no-init --no-verify-html-index  \
       --preload=$SRCDIR/../doc/info/build-html-index.lisp \
       --batch-string="$BATCH"
