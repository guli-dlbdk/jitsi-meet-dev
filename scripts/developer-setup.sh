#!/bin/bash
set -e

path="https://github.com/jitsi/"
JICOFO="jicofo.git"
JITSIMEET="jitsi-meet.git"
LIBJITSIMEET="lib-jitsi-meet.git"
REPOSITORY=(
        "jicofo":$JICOFO
        "jitsi-meet":$JITSIMEET
        "lib-jitsi-meet":$LIBJITSIMEET)

for repo in "${REPOSITORY[@]}"
do
    key="${repo%%:*}"
    value="${repo##*:}"

    if [[ -d $key ]]
    then
        cd $key
        git pull
        cd ..
    else
        echo "$key repository is loading..."
        echo "$path$value"
        git clone $path$value
    fi
done


echo
echo "################################"
echo "# JICOFO #"
echo "################################"
echo

apt install -y maven
if [[ -d jicofo ]]
then
    cd jicofo
    mvn package -DskipTests -Dassembly.skipAssembly=false
    mvn install
    unzip target/jicofo-1.1-SNAPSHOT-archive.zip
    cp jicofo-1.1-SNAPSHOT/jicofo.jar /usr/share/jicofo/
 
    /etc/init.d/jicofo restart && /etc/init.d/jitsi-videobridge2 restart && /etc/init.d/prosody restart
    cd ../
else
    echo "not found jicofo repository"
    exit 1
fi
echo
echo "################################"
echo "# JITSI-MEET #"
echo "################################"
echo

if [[ -d jitsi-meet ]]
then
    cd jitsi-meet
    rm -rf node_modules package-lock.json
    github_url=`grep -i "lib-jitsi-meet" package.json`
    file_url="    \"lib-jitsi-meet\": \"file:../lib-jitsi-meet\","
    echo $github_url
    echo $file_url
    sed -zi "s|$github_url|$file_url|g" package.json
    cd ..
else
    echo "not found jitsi-meet repository"
    exit 1
fi

echo
echo "################################"
echo "# LIB-JITSI-MEET #"
echo "################################"
echo

if [[ -d lib-jitsi-meet ]]
then
    cd lib-jitsi-meet
    rm -rf node_modules package-lock.json
    npm update && npm install
    cd ..
else
    echo "not found lib-jitsi-meet repository"
    exit 1
fi

cd jitsi-meet/
npm update && npm install
npm install lib-jitsi-meet --force && make
