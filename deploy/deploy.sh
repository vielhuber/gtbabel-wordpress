#!/bin/bash

set -Eeuo pipefail

SLUG="gtbabel"
NAME="Gtbabel"
SVN_USERNAME="gtbabel"

# parse command line arguments
RELEASE=false
DEBUG=false
VERSION=""
while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        # --release
        --release)
        RELEASE=true
        ;;
        # --debug
        --debug)
        DEBUG=true
        ;;
        # --version
        --version)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Missing value for --version"
            exit 1
        fi
        VERSION="$1"
        ;;
        *)
        echo "Unknown option '$key'"
        exit 1
        ;;
    esac
    shift
done

if [[ "$DEBUG" == true ]]; then
    echo "Press CTRL+C to proceed."
    trap "pkill -f 'sleep 1h'" INT
    trap "set +x ; sleep 1h ; set -x" DEBUG
fi

# output commands
set -x

# save parent folder
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR="$( dirname "$SCRIPT_DIR" )"

# remove obsolete files
cd "$SCRIPT_DIR"
rm -rf ./deploy/build/ ./deploy/scoped/
rm -f ./deploy/_"$SLUG".zip

# determine next version
if [[ "$RELEASE" == true ]]; then
    cd "$SCRIPT_DIR"
    if [[ -n "$VERSION" ]]; then
        v_new="$VERSION"
    else
        v=$(git describe --abbrev=0 --tags 2>/dev/null)
        n=(${v//./ })
        n1=${n[0]}
        n2=${n[1]}
        n3=${n[2]}
        if [ -z "$n1" ] && [ -z "$n2" ] && [ -z "$n3" ]; then n1=1; n2=0; n3=0;else n3=$((n3+1)); fi
        if [ "$n3" == "10" ]; then n3=0; n2=$((n2+1)); fi
        if [ "$n2" == "10" ]; then n2=0; n1=$((n1+1)); fi
        v_new="$n1.$n2.$n3"
    fi
    if [[ ! "$v_new" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid version '$v_new'"
        exit 1
    fi
    echo "$v_new"
fi

# increase version number in readme.txt and main php
if [[ "$RELEASE" == true ]]; then
    sed -i -e "s/Stable tag: [0-9]\.[0-9]\.[0-9]/Stable tag: $v_new/" ./readme.txt
    sed -i -e "s/ \* Version: [0-9]\.[0-9]\.[0-9]/ * Version: $v_new/" ./"$SLUG".php
fi

# copy all assets
cd "$SCRIPT_DIR"
mkdir ./deploy/build
rsync -av --quiet --progress . ./deploy/build --exclude deploy --exclude .git --exclude node_modules --exclude vendor

# copy composer files to current folder (one level up) and run composer install
cd "$SCRIPT_DIR"
cp ./../gtbabel-core/composer.json ./deploy/build/composer.json
cp -r ./../gtbabel-core/src ./deploy/build/src
cp -r ./../gtbabel-core/components/. ./deploy/build/components/
cp ./../gtbabel-core/helpers.php ./deploy/build/helpers.php
cd ./deploy/build/
composer update --no-dev --no-autoloader --prefer-dist --no-interaction

# remove hotloaded functions by stringhelper (since in projects with gtbabel+stringhelper this fails!)
sed -i -e '/"src\/functions.php"/d' ./vendor/composer/installed.json
composer dump-autoload --no-dev --classmap-authoritative

# do the prefixing with php-scoper
cd "$SCRIPT_DIR"
cd ./deploy/build
wget --quiet --show-progress --output-document php-scoper.phar https://github.com/humbug/php-scoper/releases/download/0.18.19/php-scoper.phar
php ./php-scoper.phar add-prefix --config scoper.inc.php --output-dir ../scoped --force
composer dump-autoload --working-dir=../scoped --no-dev --classmap-authoritative

# rename and cleanup the build directory
cd "$SCRIPT_DIR"
cd ./deploy/build
mv ./../scoped/ ./"$SLUG"/
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
cd "$SCRIPT_DIR"
cd ./deploy/build
zip --quiet -r ./../_"$SLUG".zip ./"$SLUG"

# make release for plugin: add to subversion
if [[ $RELEASE == true ]]; then
    cd "$SCRIPT_DIR"
    cd ./deploy/build
    mkdir svn
    cd ./svn
    svn co https://plugins.svn.wordpress.org/"$SLUG" . --quiet
    sleep 2
    svn cleanup --quiet
    svn update --quiet
    sleep 2

    find ./trunk -mindepth 1 -maxdepth 1 -exec svn rm --force --quiet {} +
    cp -r ./../"$SLUG"/. ./trunk/
    svn add --force ./trunk/* --quiet

    find ./assets -mindepth 1 -maxdepth 1 -exec svn rm --force --quiet {} +
    cp -r ./../"$SLUG"/assets/plugin/. ./assets/
    svn add --force ./assets/* --quiet

    find ./tags -mindepth 1 -maxdepth 1 -exec svn rm --force --quiet {} + # delete ALL old versions
    #svn cp ./trunk ./tags/$v_new --quiet
    cp -r ./../"$SLUG"/. ./tags/"$v_new"
    svn add --force ./tags/* --quiet

    svn ci -m "$v_new" --username "$SVN_USERNAME"
fi

# remove obsolete files
cd "$SCRIPT_DIR"
rm -rf ./deploy/build/

# git commit + push + tag
if [[ "$RELEASE" == true ]]; then
    echo "Run the following command to commit, push and tag version $v_new:"
    printf 'cd "%s" && git add %s.php readme.txt deploy/deploy.sh && git commit -m "%s" -- %s.php readme.txt deploy/deploy.sh && git push origin HEAD && git tag -a "%s" -m "%s" && git push origin "%s"\n' \
        "$SCRIPT_DIR" "$SLUG" "$v_new" "$SLUG" "$v_new" "$v_new" "$v_new"
fi

# debug
#rm -rf ./deploy/build
#exit
