#!/usr/bin/bash
<<'COMMENT'
 * This file is part of the TORUScan project.
 * TORUScan - driver for TORUS(R) series network scaners by Jetcom(R)
 * Copyright (C) 2022 Denis Kazakov <kazakow.denis@yandex.ru>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; withoutput even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.

 dependencies list:
 dd - convert and copy a file
 xxd - make a hexdump or do the reverse
 bc - An arbitrary precision calculator language
 which - shows the full path of (shell) commands
 mawk - pattern scanning and text processing language
 ImageMagick - software for the processing of bitmap images
COMMENT


# ******************************************************************
# Global variables
# ******************************************************************
# read values of input argumnets
args=("$@")

aTMP="/tmp/torus"
aResult="empty"
DELIM=" | "

fUdefWidth=0.0; fUdefHeight=0.0 	# unit=1mm
fXOffset=0.0; 	fYOffset=0.0		# unit=1mm
dUdefWidth=0; 	dUdefHeight=0		# unit=0.1mm
dXOffset=0; 	dYOffset=0			# unit=0.1mm
dFullWidth=0; 	dFullHeight=0;		# unit=0.1mm
dMinWidth=1820; dMinHeight=2100 	# unit=0.1mm
dMaxWidth=9140; dMaxHeight=150000	# unit=0.1mm

# ******************************************************************
# Main Routputins
# ******************************************************************
function printBanner()
{ # Begin Sub
	printf "Driver for TORUS(R) series network scaners by Jetcom(R)\n"
	printf "Usage: TORUScan [OPTION] [OPTION]..[OPTION]\n"
	printf "To see available options type TORUScan --help command\n"
} # End Sub

function printHelp()
{ # Begin Sub
	echo "Usage: TORUScan [OPTION] [OPTION]..[OPTION]"
	echo "List of available options and arguments:"
	echo "--ipaddr            ip address of scaner"
	echo "--resolution        may be in: <150 | 200 | 300 | 400 | 600>"
	
	echo "--clrmode           may be in: <mono | grey | color>"
	echo "                    by default = grey"
	
	echo "--speed             may be in: <normal | medium>"
	echo "                    by default = normal"
	
	echo "--preset            for color mode may be in:"
	echo "                    <photo | text | text/photo | map>"
	echo "                    for mono mode may be in:"
	echo "                    <photo | text/photo | text/graph | svetocopy>"
	echo "                    by default = photo"

	echo "--direction         may be in: <back | forward | start>"
	echo "                    by default = back"
	
	echo "--format            by default = auto; may be in:"
	echo "                    <autoa | a4 | a3 | a2 | a1 | a0 | userdef>"
	
	echo "--orient            may be in: <portrait | landscape>"
	echo "                    by default = portrait"
	
	echo "                    These options must be specified"
	echo "                    if a <userdef> format is selected"
	echo "--width             required to specify width in mm"
	echo "--height            required to specify height in mm"
	echo "--xoffset           X axis offset in mm; by default = 0"
	echo "--xoffset           Y axis offset in mm; by default = 0"
	
	echo "                    These options, if specified, will overwrite"
	echo "                    the values ​​that are set in the presets"
	echo "--density           may be in: 0..8; default value=5 for grey image"
	echo "--sharpness         may be in: 0..4; default value=3 for grey image"
	echo "--contrast          may be in: 0..2; default value=1 for grey image"
	echo "--negative          may be in: 0..1; default value=0 for grey image"
	echo "--balance           may be in: 0..12; default value=0 for grey image"
	echo "--binvalue          may be in: 0..255; default value=128 for grey image"
	
	echo "--output            path to save the image; by default: /$HOME/torus"
	echo "--logfile           path to logfile; by default: $aTMP/TORUScan.log"
	echo "--renderer          path to renderer; by default: none"
} # End Sub

function checkArgs()
{ # Begin Sub
	for aArg in "${args[@]}"; do
		if [ ${aArg:0:2} != "--" ]; then
			printf "Error: The argument should start with '--' <$aArg>\n"
			exit 1
		fi
	
		aContent=${aArg#*--}
		case ${aContent%=*} in
			"ipaddr") 		aIPaddr=${aContent#*=} ;;
			"resolution") 	aResolution=${aContent#*=} ;;
			"speed") 		aSpeed=${aContent#*=} ;;
			"clrmode") 		aClrMode=${aContent#*=} ;;
			"preset") 		aPreset=${aContent#*=} ;;
			"direction") 	aDirection=${aContent#*=} ;;
			"format") 		aFormat=${aContent#*=} ;;
			"orient") 		aOrient=${aContent#*=} ;;
			"width") 		aUdefWidth=${aContent#*=} ;;
			"height") 		aUdefHeight=${aContent#*=} ;;
			"xoffset") 		aXOffset=${aContent#*=} ;;
			"yoffset") 		aYOffset=${aContent#*=} ;;
			"density") 		aDensity=${aContent#*=} ;;
			"sharpness") 	aSharpness=${aContent#*=} ;;
			"contrast") 	aContrast=${aContent#*=} ;;
			"negative") 	aNegative=${aContent#*=} ;;
			"balance") 		aBalance=${aContent#*=} ;;
			"binvalue") 	aBinValue=${aContent#*=} ;;
			"output") 		aOutput=${aContent#*=} ;;
			"renderer") 	aRenderer=${aContent#*=} ;;
			"logfile") 		aLogFile=${aContent#*=} ;;
			"help") 		aNeedHelp="true" ;;
			*) printf "Warn: unknown parameter: ${aContent%:*}\n" ;;
		esac
	done

	# Checking aNeedHelp for valid value
	if ! [ -z ${aNeedHelp} ]
		then printHelp; exit 0
		else printBanner
	fi

	# Checking aLogFile for valid value
	if ! [ -z ${aLogFile} ]; then
		local aDirPath=$(dirname "${aLogFile}")
		if ! [ -d "$aDirPath" ]; then
			printf "Warn: logfile value wrong or not specified\n"
			aLogFile=""
		fi
	fi
	
	if [ -z ${aLogFile} ]; then
		aLogFile="$aTMP/TORUScan.log"
		printf "Info: See $aLogFile file for logs\n"
	fi
	
	if [ -f "$aLogFile" ]; then rm "$aLogFile" > /dev/null; fi
	touch "$aLogFile" > /dev/null
	
	# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
	exec > >( tee -i "$aLogFile" )
	# Without this, only stdout would be captured
	# i.e. your log file would not contain any error messages.
	exec 2>&1

	aDate=$( date '+%Y-%m-%d %H:%M:%S' )
	printf "Start Log..at ${aDate}\n"

	# Checking IP for valid value
	IFS=$'.'; local ipItems=($aIPaddr); IFS=$' '
	local dItemsCount=${#ipItems[@]}
	
	if 	[ -z ${aIPaddr} ] || \
		(( $dItemsCount != 4 )); then 
		printf "Error: IP address value wrong or not specified\n"; exit 1
	fi

	local ipItem=""
	for ipItem in ${ipItems[@]}
	do
		if 	! [[ $ipItem =~ ^[+-]?[0-9]+$ ]] || \
			(( $ipItem > 254 )); then
			printf "Error: IP address value wrong or not specified\n"; exit 1
		fi
	done

	# Checking Resolution for valid values
	LIST="150 | 200 | 300 | 400 | 600"
	if 	[ -z ${aResolution} ] || \
		! [[ $LIST =~ ($DELIM|^)$aResolution($DELIM|$) ]]; then 
		printf "Error: scan resolution value wrong or not specified\n"; exit 1
	fi

	# Checking aClrMode for valid values
	LIST="mono | grey | color"
	if 	[ -z $aClrMode ] || \
		! [[ "$LIST" =~ ($DELIM|^)$aClrMode($DELIM|$) ]]; then 
		printf "Warn: color mode mode value wrong or not specified\n"
		printf "Info: default color mode value <grey> will be used\n"
		aClrMode="grey"
	fi

	# Checking aSpeed for valid values
	LIST="normal | medium"
	if 	[ -z ${aSpeed} ] || \
		! [[ "$LIST" =~ ($DELIM|^)$aSpeed($DELIM|$) ]]; then 
		printf "Warn: scan speed value wrong or not specified\n"
		printf "Info: default scan speed value <normal> will be used\n"
		aSpeed="normal"
	fi

	# Checking aDirection for valid values
	LIST="back | fwd | start"
	if 	[ -z ${aDirection} ] || \
		! [[ "$LIST" =~ ($DELIM|^)$aDirection($DELIM|$) ]]; then 
		printf "Warn: return direction value wrong or not specified\n"
		printf "Info: default return direction value <start> will be used\n"
		aDirection="start"
	fi
	
	# Checking aFormat for valid values
	LIST="autoa | a4 | a3 | a2 | a1 | a0 | userdef"
	if 	[ -z ${aFormat} ] || \
		! [[ "$LIST" =~ ($DELIM|^)$aFormat($DELIM|$) ]]; then 
		printf "Warn: sheet format value wrong or not specified\n"
		printf "Info: default sheet format value <auto> will be used\n"
		aFormat="auto"
	fi
	
	# Checking aOrient for valid values
	LIST="a4 | a3 | a2 | a1 | a0"
	if [[ "$LIST" =~ ($DELIM|^)$aFormat($DELIM|$) ]]; then 
	
		LIST="portrait | landscape"
		if 	[ -z ${aOrient} ] || \
			! [[ "$LIST" =~ ($DELIM|^)$aOrient($DELIM|$) ]]; then 
			printf "Warn: sheet format value specified as <$aFormat>,\n"
			printf "Warn: but sheet orientation wrong or not specified\n"
			printf "Info: default sheet orientation <portrait> will be used\n"
			aOrient="portrait"
		fi
	fi

	# Checking aUdefWidth, aUdefHeight for valid values
	if [ "$aFormat" == "userdef" ]; then
		if 	[ -z ${aUdefWidth} ] || [ -z ${aUdefHeight} ] || \
			( ! [[ $aUdefWidth =~ ^[+-]?[0-9]+$ ]] && \
			! [[ $aUdefWidth =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] ) || \
			( ! [[ $aUdefHeight =~ ^[+-]?[0-9]+$ ]] && \
			! [[ $aUdefHeight =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] ); then
				printf "Error: sheet format value <userdef> was specified, but\n"
				printf "Error: sheet width, height values wrong or not specified\n"
				exit 1
		fi
			
		fUdefWidth=$( printf "$aUdefWidth*10\n" | bc )
		dUdefWidth=${fUdefWidth%.*}
		if 	! [ -z ${aXOffset} ]; then
			if 	! [[ $aXOffset =~ ^[+-.]?[0-9]+$ ]] && \
				! [[ $aXOffset =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
				printf "Error: sheet format value <userdef> was specified,\n"
				printf "Error: but X-offset wrong value specified\n"
				exit 1
			else
				fXOffset=$( printf "$aXOffset*10\n" | bc )
				dXOffset=${fXOffset%.*}
			fi
		fi
		
		dFullWidth=$(( dUdefWidth+dXOffset ))
		if 	(( dFullWidth > dMaxWidth )) || \
			(( dFullWidth < dMinWidth )); then
				printf "Error: sheet width and X-offset values together\n"
				printf "Error: must be more then 182mm. and less then 914mm.\n"
				exit 1
		fi
		
		fUdefHeight=$( printf "$aUdefHeight*10\n" | bc )
		dUdefHeight=${fUdefHeight%.*}
		if 	! [ -z ${aYOffset} ]; then
			if 	! [[ $aYOffset =~ ^[+-.]?[0-9]+$ ]] && \
				! [[ $aYOffset =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
				printf "Error: sheet format value <userdef> was specified,\n"
				printf "Error: but Y-offset wrong value specified\n"
				exit 1
			else
				fYOffset=$( printf "$aYOffset*10\n" | bc )
				dYOffset=${fYOffset%.*}
			fi
		fi

		dFullHeight=$(( dUdefHeight+dYOffset ))
		if 	(( dFullHeight > dMaxHeight )) || \
			(( dFullHeight < dMinHeight )); then
				printf "Error: sheet height and Y-offset values together\n"
				printf "Error: must be more then 210mm. and less then 15m.\n"
				exit 1
		fi
	fi

	# Checking aPreset for valid values
	if 	[ -z ${aPreset} ] && [ "$aClrMode" != "grey" ]; then 
		printf "Warn: preset value not specified\n"
		printf "Info: default preset value <photo> will be used\n"
		aPreset="photo"
	
	elif ! [ -z ${aPreset} ] && [ "$aClrMode" != "grey" ]; then
		
		case "$aClrMode" in
			"mono") LIST="photo | text/photo | text/graph | svetocopy" ;;
			"color") LIST="photo | text | text/photo | map" ;;
		esac
		
		if ! [[ "$LIST" =~ ($DELIM|^)$aPreset($DELIM|$) ]]; then
			printf "Warn: preset value wrong specified\n"
			printf "Info: preset for mono image must be in: $LIST\n"
			printf "Info: default preset value <photo> will be used\n"
			aPreset="photo"
		fi
	
	elif ! [ -z ${aPreset} ] && [ "$aClrMode" == "grey" ]; then
		printf "Warn: preset value wrong specified\n"
		printf "Info: for grey image preset not necessarily\n"
		aPreset=""
	fi
	
	# Checking aNegative for valid values
	if 	[ -z ${aNegative} ] || \
		! [[ $aNegative =~ ^[+-]?[0-9]+$ ]] || \
		(( $aNegative > 1 )); then 
		printf "Warn: negative value wrong or not specified\n"
		printf "Info: by default negative function disabled\n"
		aNegative="0"
	fi

	# Checking aDensity for valid values
	if 	[ -z ${aDensity} ] || \
		! [[ $aDensity =~ ^[+-]?[0-9]+$ ]] || \
		(( $aDensity > 8 )); then 
		printf "Warn: density value wrong or not specified\n"
		printf "Info: density value from preset will be used\n"
		aDensity=""
	fi

	# Checking aSharpness for valid values
	if 	[ -z ${aSharpness} ] || \
		! [[ $aSharpness =~ ^[+-]?[0-9]+$ ]] || \
		(( $aSharpness > 4 )); then 
		printf "Warn: sharpness value wrong or not specified\n"
		printf "Info: sharpness value from preset will be used\n"
		aSharpness=""
	fi

	# Checking aContrast for valid values
	if 	[ -z ${aContrast} ] || \
		! [[ $aContrast =~ ^[+-]?[0-9]+$ ]] || \
		(( $aContrast > 2 )); then 
		printf "Warn: contrast value wrong or not specified\n"
		printf "Info: contrast value from preset will be used\n"
		aContrast=""
	fi

	# Checking aBalance for valid values
	if 	[ -z ${aBalance} ] || \
		! [[ $aBalance =~ ^[+-]?[0-9]+$ ]] || \
		(( $aBalance > 12 )); then 
		printf "Warn: balance value wrong or not specified\n"
		printf "Info: balance value from preset will be used\n"
		aBalance=""
	fi

	# Checking aBinValue for valid values
	if 	[ -z ${aBinValue} ] || \
		! [[ $aBinValue =~ ^[+-]?[0-9]+$ ]] || \
		(( $aBinValue > 255 )); then 
		printf "Warn: binarization value wrong or not specified\n"
		printf "Info: binarization value from preset will be used\n"
		aBinValue=""
	fi

	# Checking aOutput for valid value
	if [ -z ${aOutput} ]; then 
		printf "Warn: not specified path for saving result\n"
		printf "Info: path </home/$USER/torus> will be used\n"
		aOutput="/home/$USER/torus"
	fi

	if ! [ -d "$aOutput" ]; then
		printf "Warn: specified dir <$aOutput> not exist\n"
		printf "Info: trying to create a directory <$aOutput>\n"
		install -d "$aOutput" > /dev/null 2>&1
	fi

	if ! [ -d "$aOutput" ]; then
		printf "Error: failed to create directory $aOutput\n"; exit 1
	fi

	# Checking aRenderer for valid value
	if ! [ -z ${aRenderer} ]; then
		local aRdrPath=""
		aRdrPath=$( which "$aRenderer" )
		if [ -z ${aRdrPath} ]; then
			printf "Warn: specified renderer was not found\n"
			printf "Info: rendering function turned off\n"
			aRenderer=""
		fi
	fi

	printf "=================================================\n"
	printf "DEBUG: aIPaddr       | $aIPaddr\n"
	printf "DEBUG: aResolution   | $aResolution\n"
	printf "DEBUG: aClrMode      | $aClrMode\n"
	printf "DEBUG: aPreset       | $aPreset\n"
	printf "DEBUG: aSpeed        | $aSpeed\n"
	printf "DEBUG: aDirection    | $aDirection\n"
	printf "DEBUG: aFormat       | $aFormat\n"
	printf "DEBUG: aOrient       | $aOrient\n"
	printf "DEBUG: aUdefWidth    | $aUdefWidth\n"
	printf "DEBUG: aUdefHeight   | $aUdefHeight\n"
	printf "DEBUG: aXOffset      | $aXOffset\n"
	printf "DEBUG: aYOffset      | $aYOffset\n"
	printf "DEBUG: aDensity      | $aDensity\n"
	printf "DEBUG: aSharpness    | $aSharpness\n"
	printf "DEBUG: aContrast     | $aContrast\n"
	printf "DEBUG: aNegative     | $aNegative\n"
	printf "DEBUG: aBalance      | $aBalance\n"
	printf "DEBUG: aBinValue     | $aBinValue\n"
	printf "DEBUG: aOutput       | $aOutput\n"
	printf "DEBUG: aRenderer     | $aRenderer\n"
} # End Sub

# ******************************************************************
# Begin Main
# ******************************************************************
if [ -d "$aTMP" ]; then rm -rd "$aTMP" > /dev/null; fi
install -d "$aTMP" > /dev/null

checkArgs

aRunDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "$aRunDir/scan.lib"
scanJob; if [ "$aResult" == "failed" ]; then exit 1; fi

source "$aRunDir/conv.lib"
convJob; if [ "$aResult" == "failed" ]; then exit 1; fi

if ! [ -z ${aRenderer} ]; then
	$( $aRenderer $aOutput)
fi

printf "Info: scan result was saved to file: ${aOutput}\n"
exit 0
# ******************************************************************
# End Main
# ******************************************************************
