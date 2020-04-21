#!/bin/bash

##
## moodle_debugger
##
## user.sh
##
## This program outputs files in current directory in many patterns from default storage of Moodle.
##
## Version 0.1.10
##
## Copyright (C) 2020 Shintaro Fujiwara
##
## Visit 'https://github.com/intrajp/moodle_debugger' for the usage.
##
## Thanks to this page https://www.moodlewiki.com/books/database/page/disk-usage-by-course
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
## directory where output files are stored

OUTPUTDIR_BASE="moodle_debugger_output_files"
USER_DIR="user"
DIR_OUTPUT="${OUTPUTDIR_BASE}/${USER_DIR}/"

## set host here
HOST="localhost"
## set user here
USER="root"
## set password here
PASSWORD=""
## set database name here
DATABASE="moodle"

####
VIEW_COLUMNS="u.*"
FROM_TABLES="FROM mdl_user u"
SUB_QUERY="find_in_set(u.id, (select value from mdl_config c where c.name = \"siteadmins\"))"
BIND1=""
BIND2=""
BIND3=""
GROUP_BY=""
ORDER=""
DESC="DESC"
ASC="ASC"
FORMAT_NORMAL=";"
FORMAT_ROW="\G"
FORMAT="${FORMAT_ROW}"
OUTPUTFILE=""
####

#set -x

function create_output_directory ()
{
    if [ ! -d "${DIR_OUTPUT}" ]; then
       mkdir -p "${DIR_OUTPUT}" 
    fi
}

create_output_directory

## output file name 
OUTPUTFILE="${DIR_OUTPUT}/${DATABASE}_user_siteadmins.log"

## sql (you can tweek with above variable)
MYSQL_SQL="SELECT ${VIEW_COLUMNS} ${FROM_TABLES} WHERE ${SUB_QUERY} ${FORMAT}"

## execute sql 
eval "mysql -h ${HOST} -u ${USER} --password='${PASSWORD}' ${DATABASE} -e '${MYSQL_SQL}'" > "${OUTPUTFILE}" 2>&1

## remove unneeded strings 
sed -i 's/<[^>]*>//g' "${OUTPUTFILE}" >/dev/null 2>&1

exit 0
