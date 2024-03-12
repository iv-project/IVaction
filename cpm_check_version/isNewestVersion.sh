#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2006-2023, Knut Reinert & Freie Universität Berlin
# SPDX-FileCopyrightText: 2016-2023, Knut Reinert & MPI für molekulare Genetik
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

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

# Check if git repository
if [ ! -e .git ]; then
    exit 0
fi

git fetch origin 'refs/tags/*:refs/tags/*'
newestVersion=$(git tag | cat - <(echo ${version}) | sed "s/^[vV]//" | grep "^[0-9]" | grep -v '-'  | sort -V -r | head -n 1)

if [ "${newestVersion}" == "${version}" ] \
    || [ v"${newestVersion}" == "${version}" ] \
    || [ V"${newestVersion}" == "${version}" ]; then
    exit 0;
fi

# does newest Version has a leading "v"?, then add it
if [ $(git tag | grep v${newestVersion} | wc -l) -eq 1 ]; then
    newestVersion=v${newestVersion}
fi

echo "ERROR: Newer version of \"${name}\" (${version} -> ${newestVersion}) available"
exit 1
