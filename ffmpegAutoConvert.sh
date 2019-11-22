#!/usr/bin/env bash

inputDir="/hdd/filmsUnconverted"
outputDir="/hdd/filmsConverted"

# locations of executables on system, change this to match the locations on your personal system
mediainfo="/run/current-system/sw/bin/mediainfo"
ffmpeg="/run/current-system/sw/bin/ffmpeg"

# if this isn't set, then globs are evaluated literally if no matching files are found, this can cause errors later on in the program, e.g. with ffmpeg
shopt -s nullglob
# this makes it possible to glob into directories
shopt -s globstar

for file in $inputDir/**/*.{mkv,mp4,avi,m4a,flv,mov,wmv}; do
	format="$($mediainfo --Inform="Video;%Format%" "$file")"
	if [ "$format" = "AVC" ]; then
		videoSettings="-c:v copy"
	else
		videoSettings="-c:v libx264 -preset ultrafast -crf 22"
	fi

	audioSettings="-c:a aac -ac 2"
	subtitleSettings="-c:s mov_text"

	relativeFileName="${file#"$inputDir"/}"
	outputFile=""$outputDir"/"${relativeFileName%.*}".mp4"
	dirToCreate="${outputFile%/*}"
	
	mkdir -p "$dirToCreate" 

	$ffmpeg -n -i "$file" -movflags faststart $videoSettings $audioSettings $subtitleSettings -map 0 "$outputFile"
done
