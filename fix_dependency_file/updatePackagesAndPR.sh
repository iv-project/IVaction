#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2024 Simon Gene Gottlieb
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

jsonpath=${1:-}
messageEnding=${2:-}

if [ -z "${jsonpath}" ] # no path to json file given
then
   exit 0
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

openPRs=$(gh pr list)
currentBranch=$(git rev-parse --abbrev-ref HEAD)
IFS=$'\n'
update=0
body="Libraries require updating:"
for l in $(${SCRIPT_DIR}/listAllGitRepositories.sh ${jsonpath}); do
    name=$(echo $l | cut -f 1)
    currentVersion=$(echo $l | cut -f 2)
    url=$(echo $l | cut -f 3)
    ignores=$(echo $l | cut -f 4)

    if [ "${currentVersion}" == "" ] ||                   # no version given
       [ $(echo -n "${currentVersion}" | wc -c) -eq 40 ]; # full hash
    then
        continue
    fi

    newestVersion=$(${SCRIPT_DIR}/isRemoteNewestVersion.sh "${name}" "${url}" "${ignores}")
    if [ "${newestVersion}" != "${currentVersion}" ]; then
        jq '.packages.[] |= (if (.name == "'${name}'") then (.version |= "'${newestVersion}'") end)' $jsonpath > $jsonpath.new
        mv $jsonpath.new $jsonpath
        update=1
        body="${body}"$'\n'"- **${name}**: ${currentVersion} → ${newestVersion}"
    fi
done

if [ ${update} -eq 1 ]; then
    shasum=$(echo ${body} | sha256sum | cut -f 1 -d' ')

    branch_name="ci/update_${shasum}"
    title="CI - Update Libraries ${shasum}"
    body="${body}"$'\n'"${messageEnding}"

    alreadyExists=$(echo ${openPRs} | (grep -- "${title}" || true) | wc -l)
    if [ ${alreadyExists} -eq 0 ]; then
        git checkout -b ${branch_name}
        git add ${jsonpath}
        git commit -m "$title"$'\n\n'"${body}"
        git push origin HEAD
        gh pr create -t "${title}" -b "${body}"
        git checkout ${currentBranch}
        git branch -D ${branch_name}
        echo "New PR ${shasum}"
    else
        echo "No new PR, already exists ${shasum}"
    fi
else
    echo "no update required"
fi
