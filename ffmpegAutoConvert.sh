#!/usr/bin/env bash

inputDir="/hdd/filmsUnconverted"
outputDir="/hdd/filmsConverted"
mediainfo="/run/current-system/sw/bin/mediainfo"
ffmpeg="/run/current-system/sw/bin/ffmpeg"

shopt -s nullglob

for file in $inputDir/*.{mkv,mp4,avi}; do
	format="$($mediainfo --Inform="Video;%Format%" "$file")"
	if [ "$format" = "AVC" ]; then
		$ffmpeg -y -ss 500 -i "$file" -t 20 -c copy "$outputDir/$(basename ${file%.*}).mp4"
	fi
done
