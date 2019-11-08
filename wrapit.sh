#!/bin/bash

TMP_DIR=`mktemp -d`
ZIPFILE="$TMP_DIR/bins.zip"
EXE="$1"
BASE_EXE=`basename "$EXE"`

LDD=`ldd "$EXE"  | cut -f3 -d" " | grep -v libc.so. | grep -v libpthread.so. | tr "\n" " "`
echo $LDD >&2

zip -q -j "$ZIPFILE" $LDD "$EXE"

openssl base64 < "$ZIPFILE" > "$ZIPFILE.asc"



cat <<SCRIPT
#!/bin/bash
TMP_DIR=\`mktemp -d\`

RUNDIR=\`pwd\`

cd "\$TMP_DIR"

openssl base64 -d > "\$TMP_DIR/bins.zip" <<ZIP
`cat "$ZIPFILE.asc"`
ZIP

#extract exe
echo unzip -q "\$TMP_DIR/bins.zip" "$BASE_EXE"
unzip -l "\$TMP_DIR/bins.zip" >&2
unzip -q "\$TMP_DIR/bins.zip" "$BASE_EXE"
ldd -v "\$TMP_DIR/$BASE_EXE" >&2

NEEDED_LDD=\`ldd -v "\$TMP_DIR/$BASE_EXE"  | grep -i "not found" | cut -f3 | cut -f1 -d" " | tr "\n" " " \`

echo "NEEDED_LDD: \$NEEDED_LDD" >&2
if [ "\$NEEDED_LDD" ]; then
	unzip  "\$TMP_DIR/bins.zip" \$NEEDED_LDD >& 2
fi

export LD_LIBRARY_PATH="\$TMP_DIR:\$LD_LIBRARY_PATH"
trap 'echo "terminated"; rm -rf "\$TMP_DIR"' SIGINT SIGTERM

echo "running \$TMP_DIR/$BASE_EXE" >&2
ldd "\$TMP_DIR/$BASE_EXE" >&2

cd "\$RUNDIR"
"\$TMP_DIR/$BASE_EXE" "\$@"

#rm -rf "\$TMP_DIR"

SCRIPT
rm -rf "$TMP_DIR"


