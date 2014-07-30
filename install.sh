#/bin/bash

set -e

DIR=$PWD
EXTENSIONS="ParserFunctions Cite Scribunto wikihiero SyntaxHighlight_GeSHi"
unset MW_INSTALL_PATH

checkout() {
	REPO=$1

	DEST=$2
	if [ -z "$DEST" ] ; then
		DEST=`echo $REPO | grep -Po "\w*$"`
	fi

	if [ ! -d $DEST ] ; then
		git clone "https://git.wikimedia.org/git/$REPO.git" $DEST
	else
		echo "Updating $REPO..."
		pushd "$DEST" > /dev/null
		git checkout master
		git pull
		popd > /dev/null
	fi
}

extension() {
	checkout "mediawiki/extensions/$1" "mediawiki/extensions/$1"
}

checkout mediawiki/core mediawiki

for EXT in $EXTENSIONS ; do
	extension $EXT
done

if [ ! -e mediawiki/LocalSettings.php ] ; then
	php mediawiki/maintenance/install.php --dbtype=sqlite --dbname=wiki --dbpath=$DIR \
		--confpath=mediawiki --pass=123 Wikipedia WikiSysop

	for EXT in $EXTENSIONS ; do
		echo "require_once \"\$IP/extensions/$EXT/$EXT.php\";" >> mediawiki/LocalSettings.php
	done
fi

php mediawiki/maintenance/update.php --quick

if [ ! -e dump.xml ] ; then
	echo Main_Page | php mediawiki/maintenance/deleteBatch.php
	wget -O dump.xml 'https://en.wikipedia.org/wiki/Special:Export?pages=Barack_Obama%0a%0dMain_Page&curonly=1&templates=1'
	php mediawiki/maintenance/importDump.php dump.xml
fi
