#!/bin/bash

SLUG_FREE="gtbabel"
NAME_FREE="Gtbabel"
SLUG_PRO="gtbabelpro"
NAME_PRO="Gtbabel Pro"
SVN_USERNAME="gtbabel"
API_URL="https://gtbabel.com/wp-json/v1/release"
API_USERNAME="api"
API_PASSWORD="wZJoc%d@GsfUpIGOw*j*M01O"

# parse command line arguments
FREE=false
PRO=false
RELEASE=false
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # --free
        --free)
        FREE=true
        ;;
        # --pro
        --pro)
        PRO=true
        ;;
        # --release
        --release)
        RELEASE=true
        ;;
        *)
        echo "Unknown option '$key'"
        ;;
    esac
    shift
done
if [[ "$FREE" == false && "$PRO" == false ]]; then
  FREE=true
  PRO=true
fi

# output commands
set -x

# switch to composer 1 (https://github.com/humbug/php-scoper/issues/452)
composer self-update --1

# save parent folder
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR="$( dirname "$SCRIPT_DIR" )"

# determine next version
if [ $RELEASE == true ]; then
    cd $SCRIPT_DIR
    v=`git describe --abbrev=0 --tags 2>/dev/null`
    n=(${v//./ })
    n1=${n[0]}
    n2=${n[1]}
    n3=${n[2]}
    if [ -z "$n1" ] && [ -z "$n2" ] && [ -z "$n3" ]; then n1=1; n2=0; n3=0;else n3=$((n3+1)); fi
    if [ "$n3" == "10" ]; then n3=0; n2=$((n2+1)); fi
    if [ "$n2" == "10" ]; then n2=0; n1=$((n1+1)); fi
    v_new="$n1.$n2.$n3"
    echo $v_new
fi

# increase version number in readme.txt and main php
if [ $RELEASE == true ]; then
    sed -i -e "s/Stable tag: [0-9]\.[0-9]\.[0-9]/Stable tag: $v_new/" ./readme.txt
    sed -i -e "s/ \* Version: [0-9]\.[0-9]\.[0-9]/ * Version: $v_new/" ./"$SLUG_FREE".php
fi


for TYPE in "FREE" "PRO" ;
do

    if [[ "$TYPE" == "FREE" && "$FREE" == false ]]; then
      continue
    fi
    if [[ "$TYPE" == "PRO" && "$PRO" == false ]]; then
      continue
    fi

    # determine names
    if [ "$TYPE" == "FREE" ]; then
        SLUG="$SLUG_FREE"
        NAME="$NAME_FREE"
    fi
    if [ "$TYPE" == "PRO" ]; then
        SLUG="$SLUG_PRO"
        NAME="$NAME_PRO"
    fi

    # copy all assets
    cd $SCRIPT_DIR
    mkdir ./deploy/build
    rsync -av --quiet --progress . ./deploy/build --exclude deploy

    # delete symlink that has been created when developing locally
    cd $SCRIPT_DIR
    cd ./deploy/build
    unlink vendor

    # copy composer files to current folder (one level up) and run composer install
    cd $SCRIPT_DIR
    cp ./../core/composer.json ./deploy/build/composer.json
    cp -r ./../core/src ./deploy/build/src
    cp -r ./../core/components ./deploy/build/components
    cp ./../core/helpers.php ./deploy/build/helpers.php
    cd ./deploy/build/
    composer install --no-dev
    composer update --no-dev

    # replace name
    if [ "$TYPE" == "PRO" ]; then
        cd $SCRIPT_DIR
        cd ./deploy/build

        # careful
        mv ./"$SLUG_FREE".php ./"$SLUG_PRO".php
        find . -type f -name "*" -print0 | xargs -0 sed -i -e "s/Plugin Name: $NAME_FREE/Plugin Name: $NAME_PRO/g"
        find . -type f -name "*" -print0 | xargs -0 sed -i -e "s/\$name = '$NAME_FREE'/\$name = '$NAME_PRO'/g"
        find . -type f -name "*" -print0 | xargs -0 sed -i -e "s/'prefix' => 'Scoped""$NAME_FREE""'/'prefix' => 'Scoped""$NAME_FREE""Pro'/g"
        msgfmt ./languages/"$SLUG_FREE"-plugin-de_DE.po -o ./languages/"$SLUG_FREE"-plugin-de_DE.mo
    fi

    # strip out pro code
    if [ "$TYPE" == "FREE" ]; then
        cd $SCRIPT_DIR
        cd ./deploy/build
        find . -type f -name "*.php" -print0 | xargs -0 sed -i -e '/\/\* @BEGINPRO \*\//,/\/\* @ENDPRO \*\//d'
    fi

    # do the prefixing with php-scoper
    cd $SCRIPT_DIR
    cd ./deploy/build
    wget https://github.com/humbug/php-scoper/releases/download/0.15.0/php-scoper.phar
    php ./php-scoper.phar add-prefix --config scoper.inc.php
    cd ./build
    composer dump-autoload
    sleep 3

    # rename and cleanup the build directory
    cd $SCRIPT_DIR
    cd ./deploy/build
    mv ./build/ ./"$SLUG"/
    rm -f ./"$SLUG"/composer.json
    rm -f ./"$SLUG"/composer.lock
    rm -f ./"$SLUG"/package.json
    rm -f ./"$SLUG"/package-lock.json
    rm -f ./"$SLUG"/README.MD
    rm -f ./"$SLUG"/php-scoper.phar
    rm -f ./"$SLUG"/deploy-plugin.sh
    rm -f ./"$SLUG"/deploy-zip.sh
    rm -f ./"$SLUG"/scoper.inc.php
    rm -rf ./"$SLUG"/locales/
    rm -rf ./"$SLUG"/logs/
    rm -rf ./"$SLUG"/node_modules/

    # make a zip
    cd $SCRIPT_DIR
    cd ./deploy/build
    zip --quiet -r ./../_"$SLUG".zip ./"$SLUG"

    # make release for free plugin: add to subversion
    if [[ "$TYPE" == "FREE" && $RELEASE == true ]]; then
        cd $SCRIPT_DIR
        cd ./deploy/build
        mkdir svn
        cd ./svn
        svn co https://plugins.svn.wordpress.org/"$SLUG_FREE" . --quiet
        sleep 2
        svn cleanup --quiet
        svn update --quiet
        sleep 2

        svn rm ./trunk/* --quiet
        cp -r ./../"$SLUG_FREE"/. ./trunk/
        svn add ./trunk/* --quiet

        svn rm ./assets/* --quiet
        cp -r ./../"$SLUG_FREE"/assets/plugin/. ./assets/
        svn add ./assets/* --quiet

        svn rm ./tags/* --quiet # delete ALL old versions
        #svn cp ./trunk ./tags/$v_new --quiet
        cp -r ./../"$SLUG_FREE"/. ./tags/"$v_new"
        svn add ./tags/* --quiet

        svn ci -m "$v_new" --username "$SVN_USERNAME"
    fi

    # make release for pro plugin: call api
    if [[ "$TYPE" == "PRO" && $RELEASE == true ]]; then
        cd $SCRIPT_DIR
        echo -n '{
            "name": "'"$(grep "^ *\* Plugin Name:" ./deploy/build/"$SLUG_PRO".php | cut -d":" -f2- | xargs)"'",
            "version": "'"$(grep "^Stable tag:" ./deploy/build/readme.txt | cut -d":" -f2- | xargs)"'",
            "requires": "'"$(grep "^Requires at least:" ./deploy/build/readme.txt | cut -d":" -f2- | xargs)"'",
            "tested": "'"$(grep "^Tested up to:" ./deploy/build/readme.txt | cut -d":" -f2- | xargs)"'",
            "file": "'"$(base64 -w 0 ./deploy/_"$SLUG_PRO".zip)"'",
            "icon": "'"$(base64 -w 0 ./deploy/build/assets/plugin/icon-128x128.png)"'"
        }' > ./deploy/release.log
        cat ./deploy/release.log | curl\
            -L\
            --insecure\
            -H "Content-Type: application/json"\
            -u "$API_USERNAME":"$API_PASSWORD"\
            -X POST\
            -d @-\
            "$API_URL"
    fi

    # remove obsolete files
    cd $SCRIPT_DIR
    rm -rf ./deploy/build/

done


# git push + tag
if [ $RELEASE == true ]; then
    cd $SCRIPT_DIR
    git add -A . && git commit -m "$v_new" && git push origin HEAD && git tag -a $v_new -m "$v_new" && git push --tags
fi

# switch back to composer 2
composer self-update --2

# debug
#rm -rf ./deploy/build
#exit