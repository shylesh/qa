#!/bin/bash

set -e;

if [ $# -eq 0 ]; then
    echo "Usage: $0 <dir1> [dir2 [dir3 [dir4 ...]]]";
    exit 1
fi

for dir in "$@"; do
    if [ ! -d "$dir" ]; then
	echo "$0: $dir not a directory"
	exit 1;
    fi
done

subdirs="{00"
for i in {1..255}; do
    n=$(printf "%02x" $i);
    subdirs="$subdirs,$n";
done
subdirs="$subdirs}"

mkdir -v "$dir/.glusterfs";

for dir in $@; do
    for i in {0..255}; do
	n=$(printf "%02x" $i);
	mkdir -v "$dir/.glusterfs/$n"
	eval "mkdir -v $dir/.glusterfs/$n/$subdirs"
    done
done