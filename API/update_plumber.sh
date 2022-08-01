#!/bin/bash
now=$(date)
printf "%s\nChecking GitHub for updates at: $now\n\n"
## Download the most recent file from GitHub
curl https://raw.githubusercontent.com/GMaynard1/emolt_serverside/main/API/plumber.R > /etc/plumber/newPlumber.R
## Compare the new file and the old file and replace the old with the new if they differ
if [ -n "$(cmp /etc/plumber/plumber.R /etc/plumber/newPlumber.R)" ]; then
  now=$(date)
  printf "\nStopping plumber service at: $now\n\n"
  systemctl stop plumber-api
  mv plumber.R oldPlumber.R
  mv newPlumber.R plumber.R
  printf "\nUpdate applied\n\n"
  systemctl start plumber-api
  now=$(date)
  printf "\nPlumber service restarted at: $now\n\n"
else
  rm newPlumber.R
  printf "\nNo newer version found \n update applied\n\n"
fi
## End of file