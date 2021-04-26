#!/bin/bash

if [[ ( -n "$1" ) && ( $1 == "start" ) ]]; then
    if [ ! -d "./../../plugins/gtbabel_tmp" ]; then
        echo "starting..."
        mv ./../../plugins/gtbabel ./../../plugins/gtbabel_tmp
        ln -s /var/www/gtbabel/gtbabel-old/wordpress ./../../plugins/gtbabel
    else
        echo "stop first!"
    fi
fi

if [[ ( -n "$1" ) && ( $1 == "stop" ) ]]; then
    if [ -d "./../../plugins/gtbabel_tmp" ]; then
        echo "stopping..."
        unlink ./../../plugins/gtbabel
        mv ./../../plugins/gtbabel_tmp ./../../plugins/gtbabel
    else
        echo "start first!"
    fi
fi

