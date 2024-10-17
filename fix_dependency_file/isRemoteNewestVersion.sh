#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2024 Simon Gene Gottlieb
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

name=${1:-}
url=${2:-}
ignores=${3:-}

if [ -z "${name}" ] ||                      # no name given
   [ -z "${url}" ]                          # no url given
then
   exit 0
fi

newestVersion=$(git ls-remote --tags "${url}" \
    | cut -d '/' -f 3 \
    | grep -v "[\^]{}$" \
    | grep -P -v "^${ignores}$" \
    | sed 's/^\([a-Z-]*-\?\)\(.*\)$/\2 \1\2/' \
    | grep [0-9] \
    | grep -v .rc[0-9]* \
    | grep -v -- "-pre$" \
    | sort --version-sort -k 1 \
    | cut -f 2 -d ' ' \
    | tail --lines=1)

echo ${newestVersion}
