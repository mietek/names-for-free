. ./config.sh
redo-ifchange "${BIBS[@]}" $BASE.tex

mkdir -p _build/$BASE/
rubber-pipe --keep --cache --into _build/$BASE --pdf ${rubberopts[@]} < $BASE.tex
