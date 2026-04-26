#!/usr/bin/env bash

# Skrypt do "uwalania" wideo pod limity GitHub (100MB)
# Użycie: ./compress_video.sh plik_wejsciowy.mp4

INPUT="$1"

if [ -z "$INPUT" ]; then
    echo "Użycie: $0 <plik_wideo>"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "Błąd: Plik '$INPUT' nie istnieje."
    exit 1
fi

EXTENSION="${INPUT##*.}"
FILENAME="${INPUT%.*}"
OUTPUT="${FILENAME}_compressed.mp4"
RESOLUTION="1920"

echo "Kompresuje: $INPUT -> $OUTPUT (szerokosc: $RESOLUTION px)"

ffmpeg -i "$INPUT" \
    -vf "scale=$RESOLUTION:-2" \
    -c:v libx264 \
    -crf 28 \
    -an \
    -y \
    "$OUTPUT"

if [ $? -eq 0 ]; then
    echo "Gotowe!"
    ls -lh "$INPUT" "$OUTPUT"
else
    echo "Cos poszlo nie tak podczas kompresji."
fi
