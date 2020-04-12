#!/bin/bash

##
## This program adds echo line of file name and function name plus sql to related php file of Moodle.
##
## Version 0.1.0
##
## Copyright (C) 2020 Shintaro Fujiwara
##
##  This program is free software; you can redistribute it and/or
##  modify it under the terms of the GNU Lesser General Public
##  License as published by the Free Software Foundation; either
##  version 2.1 of the License, or (at your option) any later version.
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
##  Lesser General Public License for more details.
##  You should have received a copy of the GNU Lesser General Public
##  License along with this library; if not, write to the Free Software
##  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
##  02110-1301 USA
##


HTML_DIR="/var/www/html"
DIR_ORIG="${HTML_DIR}/moodle"
DEBUG_STR="debug"
USER="apache"
DIR="${HTML_DIR}/moodle_${DEBUG_STR}"
CONSTRUCTOR="__construct"
EXCLUDE_FILE="setuplib.php"
FILELIST_PHP="/tmp/filelist_php"

function confirm_question()
{
    if [ -z "${1}" ]; then
        ANS="${DIR_ORIG}"
    else
        ANS="${1}"
    fi
    if [ ! -d "${ANS}" ]; then
        echo "Directory ${ANS} does not exist"
        ask_question
    fi
    echo -n "Are you shure with this directory? ${ANS} (Y/n)[n]:"
    read ANS2
    if [ "${ANS2}" = "Y" ] || [ "${ANS2}" = "y" ]; then
        DIR="${ANS}_${DEBUG_STR}"
    elif [ "${ANS2}" = "n" ]; then
        ask_question
    else
        ask_question
    fi
}

function ask_question()
{
    echo -n "Please give path to debug [$DIR_ORIG]:"
    read ANS
    confirm_question "${ANS}"
}

ask_question

echo "Start creating directory '${DIR}' in 3 seconds."
sleep 3

if [ -d "${DIR}" ]; then
    rm -rf "${DIR}" 
fi
echo "Create ${DIR}"
mkdir "${DIR}"
if [ ! $? == 0 ]; then
    echo "Create ${DIR} failed."
    exit 1
else
    echo "Created ${DIR}"
fi
trap "echo remove directory ${DIR};rm -rf ${DIR};exit 1" 2
echo "Copying files from ${DIR_ORIG} to ${DIR}"
cp -arp "${DIR_ORIG}"/* "${DIR}" 
chown ${USER}:${USER} "${DIR}"
COMMAND="chown ${USER}:${USER} ${DIR}"
if [ ! $? == 0 ]; then
    echo "'${COMMAND}' error"
    exit 1
else
    echo "'${COMMAND}' was success"
fi
chmod 0770 "${DIR}"
echo "Find php files in ${DIR}"
find "${DIR}" -type f -name "*.php" > "${FILELIST_PHP}"
trap "echo remove directory ${DIR} and ${FILELIST_PHP};rm -rf ${DIR};rm -f ${FILELIST_PHP};exit 1" 2
chmod 660 "${FILELIST_PHP}"
echo "Foud php files and saved as ${FILELIST_PHP}"
sleep 3
echo "Add debug lines to php files in ${DIR}"
sleep 5

while read line
do
    if [[ "${line}" =~ "class" ]]; then
       echo "exclude class file -- ${line}"
    else
        grep -e "${CONSTRUCTOR}" "${line}" >/dev/null 2>&1
        if [ $? == 0 ]; then
            echo "exclude ${line}, because matched with ${CONSTRUCTOR}"
        else
            sed -i -e '/public function [^__].*{/a echo "Called: ".__FILE__." : ".__FUNCTION__."\\n";' "${line}" 2>&1
        fi
        grep -e "${rawsql}" "${line}" >/dev/null 2>&1
        if [ $? == 0 ]; then
            sed -i -e '/ $rawsql/a print_object($rawsql);' "${line}"  >/dev/null 2>&1
        fi
    fi
done < "${FILELIST_PHP}"

rm -f "${FILELIST_PHP}"

echo ""
echo "Now you have ${DIR} to debug your moodle."
echo "Visit 'https://github.com/intrajp/moodle_debugger' for the usage."

exit 0
