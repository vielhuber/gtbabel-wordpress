#!/bin/bash

BASE_PLUGIN="/var/www/gtbabel"
BASE_WORDPRESS="/var/www/close2"

FOLDER=false
if [ -d "$BASE_WORDPRESS/wp-content/plugins/gtbabel" ]; then
    FOLDER="gtbabel_tmp"
fi
if [ -d "$BASE_WORDPRESS/wp-content/plugins/gtbabelpro" ]; then
    FOLDER="gtbabelpro"
fi
if [[ "$FOLDER" == false ]]; then
    echo "folder missing"
    exit
fi

if [[ ( -n "$1" ) && ( $1 == "start" ) ]]; then
    if [ ! -d "$BASE_WORDPRESS/wp-content/plugins/gtbabel_tmp" ]; then
        echo "starting..."
        mv "$BASE_WORDPRESS/wp-content/plugins/$FOLDER" "$BASE_WORDPRESS/wp-content/plugins/gtbabel_tmp"

        if [[ "$FOLDER" == "gtbabelpro" ]]; then
            sed -i -e "s/private \$name = 'Gtbabel'/private \$name = 'Gtbabel Pro'/g" "$BASE_PLUGIN/wordpress/gtbabel.php"
            mv "$BASE_PLUGIN/wordpress/gtbabel.php" "$BASE_PLUGIN/wordpress/gtbabelpro.php"
        fi

        ln -s "$BASE_PLUGIN/wordpress" "$BASE_WORDPRESS/wp-content/plugins/$FOLDER"
    else
        echo "stop first!"
    fi
fi

if [[ ( -n "$1" ) && ( $1 == "stop" ) ]]; then
    if [ -d "$BASE_WORDPRESS/wp-content/plugins/gtbabel_tmp" ]; then
        echo "stopping..."
        unlink "$BASE_WORDPRESS/wp-content/plugins/$FOLDER"

        if [[ "$FOLDER" == "gtbabelpro" ]]; then
            sed -i -e "s/private \$name = 'Gtbabel Pro'/private \$name = 'Gtbabel'/g" "$BASE_PLUGIN/wordpress/gtbabelpro.php"
            mv "$BASE_PLUGIN/wordpress/gtbabelpro.php" "$BASE_PLUGIN/wordpress/gtbabel.php"
        fi

        mv "$BASE_WORDPRESS/wp-content/plugins/gtbabel_tmp" "$BASE_WORDPRESS/wp-content/plugins/$FOLDER"
    else
        echo "start first!"
    fi
fi

