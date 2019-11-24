#!/usr/bin/env bash

inputDir="$1"
outputDir="$2"

# if this isn't set, then globs are evaluated literally if no matching files are found, this can cause errors later on in the program, e.g. with ffmpeg
shopt -s nullglob
# this makes it possible to glob into directories
shopt -s globstar

for file in $inputDir/**/*.{mkv,mp4,avi,m4a,flv,mov,wmv,m4v}; do
	formatVid="$(mediainfo --Inform="Video;%Format%" "$file")"
	if [ "$formatVid" = "AVC" ]; then
		videoSettings="-c:v copy"
	else
		videoSettings="-c:v libx264 -preset ultrafast -crf 22"
	fi

	vidMapSettings="0:v:0"

	audioSettings="-c:a aac -ac 2"
	audioMapSettings="0:a?"

	relativeFileName="${file#"$inputDir"/}"
	outputFile=""$outputDir"/"${relativeFileName%.*}".mp4"
	dirToCreate="$(dirname "$outputFile")"
	
	mkdir -p "$dirToCreate" 
	cp $(dirname "$file")/*.srt $dirToCreate
	
	formatSub="$(mediainfo --Inform="Text;%Format%" "$file")"
	if [[ $formatSub = *"PGS"* || $formatSub = *"VobSub"* ]]; then
		ffmpeg -n -i "$file" -movflags faststart $videoSettings $audioSettings -map $vidMapSettings -map "$audioMapSettings" "$outputFile"
	else
		subtitleSettings="-c:s mov_text"
		subMapSettings="0:s?"
		ffmpeg -n -i "$file" -movflags faststart $videoSettings $audioSettings $subtitleSettings -map $vidMapSettings -map "$audioMapSettings" -map "$subMapSettings" "$outputFile"
	fi
done
