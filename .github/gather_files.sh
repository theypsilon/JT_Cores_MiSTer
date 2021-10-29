#!/usr/bin/env bash
# Copyright (c) 2021 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

curl -o /tmp/update_distribution.source "https://raw.githubusercontent.com/MiSTer-devel/Distribution_MiSTer/main/.github/update_distribution.sh"

source /tmp/update_distribution.source
rm /tmp/update_distribution.source

update_distribution() {
    local TMP_FOLDER="${1}"
    local REGISTRY="$(pwd)/${2}"


    local REPOSITORY_URL="${REPOSITORY_URL:-'https://github.com/JTFPGA/JTSTABLE'}"

    echo "fetch_core_urls"
    fetch_core_urls "${REPOSITORY_URL}"

    echo "download_repository"
    rm -rf "${TMP_FOLDER}" || true
    mkdir -p "${TMP_FOLDER}"
    download_repository "${TMP_FOLDER}" "${REPOSITORY_URL}.git" "master"

    rm "${REGISTRY}" || true

    for folder in $(echo "${CORE_URLS[@]}" | sed -n -e 's%^.*tree/master/%%p') ; do

        for bin in $(files_with_stripped_date "${TMP_FOLDER}/${folder}/releases" | uniq) ; do
            get_latest_release "${TMP_FOLDER}/${folder}" "${bin}"
            local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

            if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
                continue
            fi

            echo "_Arcade/cores/$(basename ${LAST_RELEASE_FILE}):${folder}/releases/${LAST_RELEASE_FILE}" >> "${REGISTRY}"
        done
    done

    local IFS=$'\n'

    pushd ${TMP_FOLDER}

    for mra in $(find mra -type f -iname '*.mra' -not -path "*/_alternatives/*") ; do
        echo "_Arcade/$(basename ${mra}):${mra}" >> "${REGISTRY}"
    done

    pushd mra

    for alts in $(find _alternatives/ -type f -iname '*.mra') ; do
        echo "_Arcade/${alts}:mra/${alts}" >> "${REGISTRY}"
    done

    popd
    popd

    cat "${REGISTRY}"
}

CORE_URLS=
fetch_core_urls() {
    CORE_URLS=$(curl -sSLf "$1/wiki"| awk '/wiki-body/,/wiki-rightbar/' | grep -ioE "$1/[a-zA-Z0-9./_-]*")
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" "${2}"
fi
