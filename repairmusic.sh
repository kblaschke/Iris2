#!/bin/bash
for i in *.mp3; do
    mpg123 -w "$(echo $i | sed "s/.mp3/.wav/")" "$i";
done
rm *.mp3

for i in *.wav; do
    lame -h -V2 $i $(echo $i | sed "s/.wav/.mp3/");
done
rm *.wav
