#!/bin/bash

# output commands
#set -x

# determine mode
if [[ ( -n "$1" ) && ( $1 != "--release" ) ]]; then
    echo "wrong arguments provided"
    exit
fi
if [[ ( -z "$1" ) || ( $1 != "--release" ) ]]; then
    RELEASE=false
fi
if [[ ( -n "$1" ) && ( $1 == "--release" ) ]]; then
    RELEASE=true
fi

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
    sed -i -e "s/ \* Version: [0-9]\.[0-9]\.[0-9]/ * Version: $v_new/" ./gtbabel.php
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
cp ./../gtbabel-core/composer.json ./deploy/build/composer.json
cp -r ./../gtbabel-core/src ./deploy/build/src
cp -r ./../gtbabel-core/components ./deploy/build/components
cp ./../gtbabel-core/helpers.php ./deploy/build/helpers.php
cd ./deploy/build/
composer install --no-dev
composer update --no-dev

# do the prefixing with php-scoper
cd $SCRIPT_DIR
cd ./deploy/build
wget https://github.com/humbug/php-scoper/releases/download/0.13.1/php-scoper.phar
php ./php-scoper.phar add-prefix --config scoper.inc.php
cd ./build
composer dump-autoload
sleep 3

# rename and cleanup the build directory
cd $SCRIPT_DIR
cd ./deploy/build
mv ./build/ ./gtbabel/
rm -f ./gtbabel/composer.json
rm -f ./gtbabel/composer.lock
rm -f ./gtbabel/package.json
rm -f ./gtbabel/package-lock.json
rm -f ./gtbabel/README.MD
rm -f ./gtbabel/php-scoper.phar
rm -f ./gtbabel/deploy-plugin.sh
rm -f ./gtbabel/deploy-zip.sh
rm -f ./gtbabel/scoper.inc.php
rm -rf ./gtbabel/locales/
rm -rf ./gtbabel/logs/
rm -rf ./gtbabel/node_modules/

# debug
#rm -rf ./deploy/build
exit










# make an official zip (plugin repo)
zip -r ./gtbabel.zip ./gtbabel

# add to subversion
if [ $RELEASE == true ]; then
    mkdir svn
    cd ./svn
    svn co https://plugins.svn.wordpress.org/gtbabel . --quiet
    sleep 2
    svn cleanup --quiet
    svn update --quiet
    sleep 2
    svn rm ./trunk/* --quiet
    cp -r ./../gtbabel/. ./trunk/
    svn add ./trunk/* --quiet
    svn rm ./assets/* --quiet
    cp -r ./../gtbabel/assets/plugin/. ./assets/
    svn add ./assets/* --quiet
    svn cp ./trunk ./tags/$v_new --quiet
    svn ci -m "$v_new" --username vielhuber --quiet
    cd $SCRIPT_DIR
fi

# remove obsolete files
rm -rf ./svn/
rm -rf ./gtbabel/
rm -f ./php-scoper.phar
rm -rf ./vendor/
rm -rf ./src
rm -rf ./components
rm -f ./helpers.php
rm -f ./composer.json
rm -f ./composer.lock

# reestablish symlink
ln -s ../vendor ./vendor

# git push + tag
if [ $RELEASE == true ]; then
    cd ./../
    git add -A . && git commit -m "$v_new" && git push origin HEAD && git tag -a $v_new -m "$v_new" && git push --tags
fi

# switch back to composer 2
composer self-update --2
