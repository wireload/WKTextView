#!/bin/sh
rm -Rf sample.dist
cp -R sample sample.dist
cd sample.dist
capp gen -f --force --build
#rm Frameworks/WKTextView
mkdir Frameworks/WKTextView
cp ../WKTextView.j Frameworks/WKTextView/
rm Resources/WKTextView
cp -Rf ../Resources/WKTextView Resources/WKTextView
