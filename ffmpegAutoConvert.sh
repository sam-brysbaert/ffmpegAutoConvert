#!/usr/bin/env bash

inputDir="$1"
destinationDir="$2"

# function to show errors and exit
showError() {
	echo "$1" 1>&2
	exit 1
}

# check if script is already running, and exit if it is
if ps ax | grep $0 | grep -v $$ | grep bash | grep -v -q grep; then
	showError "ffmpegAutoConvert already running; exiting."
fi

# check if number of arguments is correct
if [ "$#" -ne 2 ]; then
	showError "ERROR: Please provide exactly two directories as arguments. The first being the input directory (where the files you want to convert are located), the second being the output directory (where the converted files will be placed).
Like so: ffmpegAutoConvert /path/to/input/dir /path/to/output/dir"
fi

# check if inputDir exists
if [ ! -d "$inputDir" ]; then
	showError "ERROR: Input directory does not exist."
fi

# make destination directory if it doesn't already exist
mkdir -p $destinationDir
if [ $? -eq 1 ]; then
    showError "ERROR: Error creating target directory."
fi

# if this isn't set, then globs are evaluated literally if no matching files
# are found, which we don't want for the main for-loop.
shopt -s nullglob
# this makes it possible to glob into directories
shopt -s globstar

for inputFile in "$inputDir"/**/*.{mkv,mp4,avi,m4a,flv,mov,wmv,m4v}; do

	# calculate path for output file
	relativeFilename="${inputFile#"$inputDir"/}"
	outputFile=""$destinationDir"/"${relativeFilename%.*}".mp4"

	# if the output file already exists, skip to next file
	if [ -f "$outputFile" ]; then
		echo "$outputFile already exists; skipping."
		continue
	fi

	# create directory for output file
	outputDir="$(dirname "$outputFile")"
	mkdir -p "$outputDir"

	# copy any existing external subtitle files
	for subFile in "$(dirname "$inputFile")"/*.{srt,ssa,ass}; do
		cp "$subFile" "$outputDir"
	done

	# this string is where all the options for ffmpeg will be collected
	options=""

	# for quicker start of video when streaming
	options+="-movflags faststart "

	# strip title metadata
	options+="-metadata Title= "

	# determine video settings
	formatVid="$(mediainfo --Inform="Video;%Format%" "$inputFile")"
	heightVid="$(mediainfo --Inform="Video;%Height%" "$inputFile")"
	if [ "$formatVid" = "AVC" ] || [ "$heightVid" = "2160" ]; then
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

echo "Script complete."
