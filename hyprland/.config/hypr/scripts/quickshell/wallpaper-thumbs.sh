THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"
SRC_DIR="$HOME/.config/backgrounds"
mkdir -p "$THUMB_DIR"

for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif}; do
    [ -e "$img" ] || continue
    filename=$(basename "$img")
    thumb="$THUMB_DIR/$filename"
    if [ ! -f "$thumb" ]; then
        magick "$img" -resize x420 -quality 70 "$thumb"
    fi
done

for vid in "$SRC_DIR"/*.{mp4,mkv,mov,webm}; do
    [ -e "$vid" ] || continue
    filename=$(basename "$vid")
    thumb="$THUMB_DIR/000_$filename"
    if [ ! -f "$thumb" ]; then
        ffmpeg -y -ss 00:00:05 -i "$vid" -vframes 1 -f image2 -q:v 2 "${thumb%.*}.jpg" > /dev/null 2>&1
    fi
done