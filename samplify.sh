#!/bin/sh
rm -Rf sample.dist
cp -R sample sample.dist
cd sample.dist
capp gen -f --force --build
#rm Frameworks/WyzihatKit
mkdir Frameworks/WyzihatKit
cp ../WKTextView.j Frameworks/WyzihatKit/
