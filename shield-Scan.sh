#! /usr/bin/bash
set -e
script_pid=$$
fingerprints_directory="/home/kali/Desktop/root-permissions"

function _scan_for_changes(){
local filename=$(basename $1)
local first_check=$(cat $fingerprints_directory/$filename)
	sleep 2
local second_check=$(md5sum "$1" | awk '{ print $1 }')
	if [ "$first_check" != "$second_check" ]
		then
			echo "exit_signal"
	fi
}

check_result=0
first_check=0
if [ $first_check -eq 0 ]
	then
		for FILE in "${PWD}/"*
		do
			if [ -f "$FILE" ]
				then
					filename=$(basename $FILE)
					touch $filename $fingerprints_directory/
					md5sum $FILE | awk '{ print $1 }' >> $fingerprints_directory/$filename
			fi
		done
		first_check=1
fi

while [ $check_result -eq 0 ]
do
	for FILE in "${PWD}/"*
	do
        	if [ -f "$FILE" ]
        		then
            			file_integrity=$(_scan_for_changes $FILE)
            			if [ "$file_integrity" == "exit_signal" ]
            				then
            					echo "EXIT!"
            					exit 1
            					check_result=1
            				else
            					echo "Everything looks ok..."
            					check_result=0
            			fi
        	fi
	done	
	sleep 1
done

rm -Rf $fingerprints_directory/*
