#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2024 Simon Gene Gottlieb
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

jsonpath=${1:-}
if [ -z "${jsonpath}" ] # no path to json file given
then
   exit 0
fi

jq -r '
.packages.[]
    | if has("github_repository") then
        (.git_repository = "https://github.com/\(.github_repository).git")
        end
    | if has("git_tag_ignore") then
        .git_tag_ignore |= (. | @tsv | gsub("\t"; "|"; "g"))
      end
    | select(.git_repository != null)
    | [.name, .version, .git_repository, .git_tag_ignore] | @tsv' \
${jsonpath}

