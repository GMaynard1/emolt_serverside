#!/bin/bash

TARGET=/var/lib/mysql-files/emolt_dat
    inotifywait -m -e create --format "%f" $TARGET \
  | while read FILENAME
  do
  DATE=$(date)
  echo Detected $FILENAME at $DATE
  rm "/var/www/html/emolt.dat"
  mv "$TARGET/$FILENAME" "/var/www/html/emolt.dat"
  chmod --reference=/var/www/html/index.html /var/www/html/emolt.dat 
done
