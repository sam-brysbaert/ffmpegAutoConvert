#!/usr/bin/env bash

inputDir="$1"
destinationDir="$2"

# if this isn't set, then globs are evaluated literally if no matching files
# are found, which we don't want for the main for-loop.
shopt -s nullglob
# this makes it possible to glob into directories
shopt -s globstar

for inputFile in $inputDir/**/*.{mkv,mp4,avi,m4a,flv,mov,wmv,m4v}; do

	# calculate path for output file
	relativeFilename="${inputFile#"$inputDir"/}"
	outputFile=""$destinationDir"/"${relativeFilename%.*}".mp4"

	# if the output file already exists, skip to next file
	if [ -f "$outputFile" ]; then
		continue
	fi

	# create directory for output file
	outputDir="$(dirname "$outputFile")"
	mkdir -p "$outputDir"

	# copy any existing srt files
	for subFile in "$(dirname "$inputFile")"/*.srt; do
		cp "$subFile" "$outputDir"
	done

	# this string is where all the options for ffmpeg will be collected
	options=""

	# for quicker start of video when streaming
	options+="-movflags faststart "

	# determine video settings
	formatVid="$(mediainfo --Inform="Video;%Format%" "$inputFile")"
	if [ "$formatVid" = "AVC" ]; then
		options+="-c:v copy "
	else
		options+="-c:v libx264 -preset ultrafast -crf 22 "
	fi
	options+="-map 0:v:0 "

	# determine audio settings
	options+="-c:a aac -ac 2 "
	options+="-map 0:a? "

	# determine subtitle settings
	formatSub="$(mediainfo --Inform="Text;%Format%" "$inputFile")"
	if [[ $formatSub != *"PGS"* && $formatSub != *"VobSub"* ]]; then
		options+="-c:s mov_text "
		options+="-map 0:s? "
	fi
	
	# execute ffmpeg
	set -o noglob # disable globbing because of potential wildcards in $options
	ffmpeg -n -i "$inputFile" $options "$outputFile"
	set +o noglob # re-enable globbing
done
