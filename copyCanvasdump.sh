#!/bin/bash

src=$1
dst=$2

echo "src $src"
echo "dst $dst"

for item in $src/*;
do
    IFS=_ read name number1 number2 filenameBase <<< "$item";
    name=$(basename $name);
    filename=$(echo $filenameBase | sed 's/-[0-9]//g' )

    echo "Working on $item "
    echo "Student: $name"
    echo "File: $filename  ($filenameBase) "

    if [[ ! -e "$dst/$name" ]];then
	mkdir -p "$dst/$name"
    elif [[ ! -d "$dst/$name" ]]; then
	echo "$dst/name already exists but it not a directory";
    fi

    echo "Copying $item -> $dst/$name/$filename"
    cp $item $dst/$name/$filename
    echo "-------------"
    echo " "
    
       
done
    
