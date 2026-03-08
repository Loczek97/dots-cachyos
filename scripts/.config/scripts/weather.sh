#!/bin/bash

city="Nysa"
cachedir="$HOME/.cache/rbn"
cachefile=${0##*/}-$1

if [ ! -d $cachedir ]; then
    mkdir -p $cachedir
fi

if [ ! -f $cachedir/$cachefile ]; then
    touch $cachedir/$cachefile
fi

# Save current IFS
SAVEIFS=$IFS
# Change IFS to new line.
IFS=$'\n'

cacheage=$(($(date +%s) - $(stat -c '%Y' "$cachedir/$cachefile")))
if [ $cacheage -gt 1740 ] || [ ! -s $cachedir/$cachefile ]; then
    data=($(curl -s https://en.wttr.in/"$city"$1\?0qnT 2>&1))
    echo ${data[0]} | cut -f1 -d, > $cachedir/$cachefile
    echo ${data[1]} | sed -E 's/^.{15}//' >> $cachedir/$cachefile
    echo ${data[2]} | sed -E 's/^.{15}//' >> $cachedir/$cachefile
fi

weather=($(cat $cachedir/$cachefile))

# Restore IFS
IFS=$SAVEIFS

temperature=$(echo ${weather[2]} | sed -E 's/([[:digit:]]+)\.\./\1 to /g')

case $(echo ${weather[1]##*,} | tr '[:upper:]' '[:lower:]') in
"clear" | "sunny")
    condition=""
    description_pl="Słonecznie"
    ;;
"partly cloudy")
    condition="󰖕"
    description_pl="Częściowe zachmurzenie"
    ;;
"cloudy")
    condition=""
    description_pl="Pochmurno"
    ;;
"overcast")
    condition=""
    description_pl="Całkowite zachmurzenie"
    ;;
"fog" | "freezing fog")
    condition=""
    description_pl="Mgła"
    ;;
"patchy rain possible" | "patchy light drizzle" | "light drizzle" | "patchy light rain" | "light rain" | "light rain shower" | "mist" | "rain" | "patchy rain nearby")
    condition="󰼳"
    description_pl="Lekki deszcz"
    ;;
"moderate rain at times" | "moderate rain" | "heavy rain at times" | "heavy rain" | "moderate or heavy rain shower" | "torrential rain shower" | "rain shower")
    condition=""
    description_pl="Ulewa"
    ;;
"patchy snow possible" | "patchy sleet possible" | "patchy freezing drizzle possible" | "freezing drizzle" | "heavy freezing drizzle" | "light freezing rain" | "moderate or heavy freezing rain" | "light sleet" | "ice pellets" | "light sleet showers" | "moderate or heavy sleet showers")
    condition="󰼴"
    description_pl="Opady śniegu/marznący deszcz"
    ;;
"blowing snow" | "moderate or heavy sleet" | "patchy light snow" | "light snow" | "light snow showers")
    condition="󰙿"
    description_pl="Lekki śnieg"
    ;;
"blizzard" | "patchy moderate snow" | "moderate snow" | "patchy heavy snow" | "heavy snow" | "moderate or heavy snow with thunder" | "moderate or heavy snow showers")
    condition=""
    description_pl="Zamieć śnieżna"
    ;;
"thundery outbreaks possible" | "patchy light rain with thunder" | "moderate or heavy rain with thunder" | "patchy light snow with thunder")
    condition=""
    description_pl="Burza"
    ;;
*)
    condition=""
    description_pl="${weather[1]} - nieznana pogoda"
    ;;
esac

echo -e "{\"text\":\"$city, $description_pl $temperature $condition\", \"alt\":\"${weather[0]}\", \"tooltip\":\"$description_pl – $temperature\"}"

cached_weather=" $temperature  \n$condition ${description_pl}"
echo -e "$cached_weather" > "$HOME/.cache/.weather_cache"
