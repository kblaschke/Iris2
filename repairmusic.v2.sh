#!/bin/bash
echo "please edit before use"
exit 1;
 
 
#convert to clean mp3-format
for i in *.mp3; do
    mpg123 -w - "$i" | lame -h -V2 - "$i"
done
 
#convert to ogg and change config
for i in *.mp3; do
    mpg123 -w - "$i" | oggenc -q 6 - -o "$(echo $i | sed "s/.mp3/.ogg/")"
done
mv Config.txt Config_old.txt;
sed "s/.mp3/.ogg/" Config_old.txt > Config.txt;