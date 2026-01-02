#!/bin/bash

BASE_PLUGIN="/var/www/gtbabel"
BASE_WORDPRESS="/var/www/wordpress"

FOLDER=false
if [ -d "$BASE_WORDPRESS/wp-content/plugins/gtbabel" ]; then
    FOLDER="gtbabel_tmp"
fi
if [[ "$FOLDER" == false ]]; then
    echo "folder missing"
    exit
fi

if [[ ( -n "$1" ) && ( $1 == "start" ) ]]; then
    if [ ! -d "$BASE_WORDPRESS/wp-content/plugins/gtbabel_tmp" ]; then
        echo "starting..."
        mv "$BASE_WORDPRESS/wp-content/plugins/$FOLDER" "$BASE_WORDPRESS/wp-content/plugins/gtbabel_tmp"

        ln -s "$BASE_PLUGIN/wordpress" "$BASE_WORDPRESS/wp-content/plugins/$FOLDER"
    else
        echo "stop first!"
    fi
fi

if [[ ( -n "$1" ) && ( $1 == "stop" ) ]]; then
    if [ -d "$BASE_WORDPRESS/wp-content/plugins/gtbabel_tmp" ]; then
        echo "stopping..."
        unlink "$BASE_WORDPRESS/wp-content/plugins/$FOLDER"

        mv "$BASE_WORDPRESS/wp-content/plugins/gtbabel_tmp" "$BASE_WORDPRESS/wp-content/plugins/$FOLDER"
    else
        echo "start first!"
    fi
fi

