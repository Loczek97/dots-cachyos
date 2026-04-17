#!/usr/bin/env bash

echo "--- Rozpoczynam czyszczenie cache wyszukiwarki tapet ---"

# 1. Zabijanie aktywnych procesów
echo "Zabijam procesy basha i pythona..."
pkill -f ddg_search.sh || true
pkill -f get_ddg_links.py || true

# 2. Usuwanie plików tymczasowych i miniatur
echo "Usuwam miniaturki wyszukiwania..."
rm -rf "$HOME/.cache/wallpaper_picker/search_thumbs"/*

echo "Resetuję mapę URL-i..."
rm -f "$HOME/.cache/wallpaper_picker/search_map.txt"
touch "$HOME/.cache/wallpaper_picker/search_map.txt"

# 3. Usuwanie markerów kolorów dla wyników z sieci
echo "Usuwam stare markery kolorów..."
rm -f "$HOME/.cache/wallpaper_picker/colors_markers/ddg_"*

# 4. Synchronizacja systemu plików
sync

echo "--- Cache został całkowicie wyczyszczony ---"
