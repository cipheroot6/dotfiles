#!/bin/bash
cava -p <(
  cat <<CAVAEOF
[general]
bars = 12
framerate = 60
sensitivity = 250

[smoothing]
monstercat = 0
gravity = 200
noise_reduction = 0.3


[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
CAVAEOF
) | while read -r line; do
  if playerctl status 2>/dev/null | grep -q "Playing"; then
    bars=$(echo "$line" | sed 's/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;s/;//g' | tr -d ' \n' | sed 's/./& /g')
    echo "{\"text\":\"$bars\",\"class\":\"playing\"}"
  else
    echo "{\"text\":\"▁ ▁ ▁ ▁ ▁ ▁\",\"class\":\"paused\"}"
  fi
done
