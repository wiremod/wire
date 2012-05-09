#!/bin/sh
echo "git (`git describe --always`)" > data/wire_version.txt
rm -rf .git
