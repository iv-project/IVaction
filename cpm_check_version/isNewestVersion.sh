#!/usr/bin/env bash

name=${1:-}
path=${2:-}
version=${3:-}

if [ -z "${name}" ] ||                      # no name given
   [ -z "${path}" ] ||                      # no path given
   [ -z "${version}" ] ||                   # no version given
   [ "${version}" == "0" ] ||               # version 0, means no version
   [ $(echo "${version}" | wc -c) -eq 40 ]; # full hash
then
   exit 0
fi

cd $path
git fetch origin 'refs/tags/*:refs/tags/*'
newestVersion=$(git tag | cat - <(echo ${version}) | sed "s/^[vV]//" | sort -V -r | head -n 1)

if [ "${newestVersion}" == "${version}" ] \
    || [ v"${newsetVersion}" == "${version}" ]; then
    exit 0;
fi

# does newest Version has a leading "v"?, then add it
if [ $(git tag | grep v${newestVersion} | wc -l) -eq 1 ]; then
    newestVersion=v${newestVersion}
fi

echo "ERROR: Newer version of \"${name}\" (${version} -> ${newestVersion}) available"
exit 1
