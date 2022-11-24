#!/usr/bin/bash

aMainFileName=$1
fMainContent=$( < "$aMainFileName" )
dMainLinesCount=$( echo "$fMainContent" | wc -l )

aOutputFileName=${aMainFileName::-3}
aOutputFileName="${aOutputFileName}.build"

while (( dLineNumber <  dMainLinesCount )); do

	dLineNumber=0
	while read -r line; do
	dLineNumber=$(( dLineNumber+1 ))
	if [[ "$line" == *"source"* ]]
		then break; fi
	done <<< "$fMainContent"

	if (( dLineNumber >=  dMainLinesCount ))
		then break; fi

	aPrefix='source "$aRunDir/'
	aSrcFileName=${line#"$aPrefix"}
	aSrcFileName=${aSrcFileName::-1}
	fSrcContent=$( tail -n +2 "$aSrcFileName" )

	echo "DEBUG: $dLineNumber: $line"
	echo "DEBUG: SrcFileName: $aSrcFileName"


	fHeader=$( head -n "$(( dLineNumber-1 ))" "$aMainFileName" )
	fTail=$( tail -n "+$(( dLineNumber+1 ))" "$aMainFileName" )

	echo "$fHeader" > "./$aOutputFileName"
	echo "" >> "./$aOutputFileName"
	echo "# /// START SOURCE FILE $aSrcFileName ///" >> "./$aOutputFileName"
	echo "" >> "./$aOutputFileName"
	echo "$fSrcContent" >> "./$aOutputFileName"
	echo "" >> "./$aOutputFileName"
	echo "# /// END SOURCE FILE aSrcFileName ///" >> "./$aOutputFileName"
	echo "" >> "./$aOutputFileName"
	echo "$fTail" >> "./$aOutputFileName"

	aMainFileName="./$aOutputFileName"
	fMainContent=$( < "$aMainFileName" )
	dMainLinesCount=$( echo "$fMainContent" | wc -l )

done

shc -r -f "./$aOutputFileName"

exit 0
