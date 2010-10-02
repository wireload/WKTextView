CLOSURE_LIBRARY=google-closure-library
CLOSURE_COMPILER=../../deps/closurecompiler/compiler.jar
DESTINATION=../Resources/WKTextView/closure-editor.js

$CLOSURE_LIBRARY/closure/bin/calcdeps.py -i closure-editor-requirements.js -p $CLOSURE_LIBRARY -o compiled \
    -c $CLOSURE_COMPILER -f "--compilation_level=ADVANCED_OPTIMIZATIONS" >$DESTINATION
