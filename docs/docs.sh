#! /bin/sh

haxe docs/docs.hxml
haxelib run dox -i docs -o pages --title "Leather Engine Mobile Documentation" -in "mobile" -in "android"