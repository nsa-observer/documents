#! /bin/bash
BN=${0##*/}
MYPID=$(echo $$)
MYPATH=$( dirname $(realpath "${BASH_SOURCE[0]}") ) 
HASH_FILE="/tmp/`date "+%s"`-hash.list"
OCR_TODO_FILE="$MYPATH/../OCR.todo"
REFUSED_PATH="$MYPATH/../refused"

exit_msg(){
    echo $@
    exit 1
}

refused (){
    mv "$f" "$REFUSED_PATH"
}


cd $MYPATH"/../"

# check files exist
if [ ! -f $OCR_TODO_FILE ] ; then 
    touch $OCR_TODO_FILE
fi

# check files in tmp
TMP_NUM=$(ls "$MYPATH/../tmp" | wc -l ) 

if [ 0 -eq $TMP_NUM ] ; then 
    exit_msg "no files to merge in tmp"
    fi

# compile hash list for pdf
echo "Calculating files hashes..."
pushd "$MYPATH/../files/pdf" 1>/dev/null
for f in $( find .  -name "*pdf"); do
    HASH=$(md5sum "$f")
    echo "$HASH" >> "$HASH_FILE"

done
popd 1>/dev/null

pushd "$MYPATH/../tmp" 1>/dev/null
IFS="
"
for f in $(find . -name "*pdf") ; do 
    

    VALID_NAME=`echo $f|tr " " "-"`
    echo $VALID_NAME
    mv "$f" "$VALID_NAME"
    echo -e "Checking file $VALID_NAME... ";
    # compare if name found
    NAME=$(grep "$VALID_NAME" "$HASH_FILE");
    if [[ "" != $NAME ]] ; then
	echo -e "  ERROR File exists with same name\n"
	refused "$VALID_NAME"
	continue
    fi

    # compare if hash found
    HASH=̀`md5sum "$VALID_NAME" |cut -d " " -f 1`
    HASH_EXISTS=$(grep "$HASH" "$HASH_FILE");
    echo "hash $HASH "
    if [[ "" != $HASH_EXISTS ]] ; then
	echo -e "  ERROR File exists with same content : '$HASH_EXISTS'\n"
	refused "$VALID_NAME"
	continue
    fi

    # merge file
    mv "$f" "$MYPATH/../files/pdf"
    echo "$f" >> $OCR_TODO_FILE
    echo "  OK"

done
popd 1>/dev/null
# cleanup
rm -f $HASH_FILE

