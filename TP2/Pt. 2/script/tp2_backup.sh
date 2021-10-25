#!/bin/bash
# Simple backup script
# Yrlan - 12/10/2021

destination=$1
folder2backup=$2

if [ -z "$destination" ]; then

  echo "Donnez le nom de dossier en tant qu'argument."
  exit 0
fi


if [ -d "$destination" ]; then
        filename="${folder2backup}_$(date '+%y-%m-%d_%H-%M-%S').tar.gz"
        tar -czf "$filename" "$folder2backup"
        rsync -av $filename $destination
        echo "Archive successfully created."
        else
        echo "ATTENTION: Le dossier de destination n'existe pas: $destination"

fi