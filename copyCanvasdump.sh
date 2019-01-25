#!/bin/bash

src=$1
dst=$2

echo "src $src"
echo "dst $dst"

for item in $src/*;
do
    IFS=_ read name number1 number2 filename <<< "$item";
    name=$(basename $name);
    echo "Student: $name"
    echo "File: $filename"

    if [[ ! -e "$dst/$name" ]];then
	mkdir -p "$dst/$name"
    elif [[ ! -d "$dst/$name" ]]; then
	echo "$dst/name already exists but it not a directory";
    fi

    echo "Copying $item -> $dst/$name/$filename"
    cp $item $dst/$name/$filename
    
       
done
    
