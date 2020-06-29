#!/usr/bin/env bash

# one-liner to output all STDOUT and STDERR to a log file
mkdir -p ~/ffmpegAutoConvert/logs
exec > >(tee "/home/sam/ffmpegAutoConvert/logs/log-$(date +"%FT%T")") 2>&1

echo "Starting conversion of films."
bash ~/ffmpegAutoConvert/ffmpegAutoConvert.sh "/hdd/films" "/hdd/filmsConverted"
echo "Films converted."

echo "Starting conversion of series."
bash ~/ffmpegAutoConvert/ffmpegAutoConvert.sh "/hdd/series" "/hdd/seriesConverted"
echo "Series converted."
echo "Done."
