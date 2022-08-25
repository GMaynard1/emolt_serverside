#!/bin/bash
now=$(date)
printf "%s\nChecking GitHub for updates at: $now\n\n"
## Download the most recent API files from GitHub
wget https://github.com/GMaynard1/emolt_serverside/archive/refs/heads/main.zip
## Unpack the archive
unzip main.zip

## Copy the files to the correct locations
## Development API
mv emolt_serverside-main/API/plumber.R /etc/plumber/
## Test API
mv emolt_serverside-main/API/test_plumber.R /etc/plumber
## API Header
mv emolt_serverside-main/API/API_header.R /etc/plumber

## Refresh API Functions
rm /etc/plumber/Functions/*
mv emolt_serverside-main/API/Functions/* /etc/plumber/Functions/

## Clean up
rm main.zip
rm -R emolt_serverside-main

## Stop the current API services
systemctl stop plumber-api
systemctl stop test-plumber-api

## Restart the plumber services
systemctl start plumber-api
systemctl start test-plumber-api

## Print the status of the development API
systemctl status plumber-api

## End of file
