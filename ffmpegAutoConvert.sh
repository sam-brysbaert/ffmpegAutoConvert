#!/usr/bin/env bash

inputDir="$1"
outputDir="$2"

# if this isn't set, then globs are evaluated literally if no matching files
# are found.
shopt -s nullglob
# this makes it possible to glob into directories
shopt -s globstar

for file in $inputDir/**/*.{mkv,mp4,avi,m4a,flv,mov,wmv,m4v}; do

	# stops wildcard chars from being interpreted as globs.
	shopt -u nullglob

	options=""

	# for quicker start of video when streaming
	options+="-movflags faststart "

	# video
	formatVid="$(mediainfo --Inform="Video;%Format%" "$file")"
	if [ "$formatVid" = "AVC" ]; then
		options+="-c:v copy "
	else
		options+="-c:v libx264 -preset ultrafast -crf 22 "
	fi
	options+="-map 0:v:0 "

	# audio
	options+="-c:a aac -ac 2 "
	options+="-map 0:a? "

	# subtitles
	formatSub="$(mediainfo --Inform="Text;%Format%" "$file")"
	if [[ $formatSub != *"PGS"* && $formatSub != *"VobSub"* ]]; then
		options+="-c:s mov_text "
		options+="-map 0:s? "
	fi

	# calculate path for output file
	relativeFileName="${file#"$inputDir"/}"
	outputFile=""$outputDir"/"${relativeFileName%.*}".mp4"

	# create directory for output file
	dirToCreate="$(dirname "$outputFile")"
	mkdir -p "$dirToCreate" 

	# copy potential srt files
	cp $(dirname "$file")/*.srt $dirToCreate
	
	# execute ffmpeg
	ffmpeg -n -i "$file" $options "$outputFile"

done
