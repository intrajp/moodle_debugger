#!/bin/bash

##
## moodle_debugger
##
## grade.sh
##
## This program outputs files in current directory in many patterns from default storage of Moodle.
##
## Version 0.1.13
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
GRADE_DIR="grade"
DIR_OUTPUT="${OUTPUTDIR_BASE}/${GRADE_DIR}/"

## set host here
HOST="localhost"
## set user here
USER="root"
## set password here
PASSWORD=""
## set database name here
DATABASE="moodle"

####
VIEW_COLUMNS="m.id as user_enrolments_id, u.id as userid, u.firstname, u.lastname, e.id enrolid, r.shortname as rolename, c.fullname, FROM_UNIXTIME('c.startdate') AS startdate, FROM_UNIXTIME('c.enddate') AS enddate, g.finalgrade, g.rawgrademax"
FROM_TABLES="FROM mdl_user u, mdl_user_enrolments m, mdl_enrol e, mdl_course c, mdl_role_assignments s, mdl_role r , mdl_grade_items i, mdl_grade_grades g"
WHERE=""
SUB_QUERY=""
BIND1="u.id = m.userid"
BIND2="m.enrolid = e.id"
BIND3="c.id = e.courseid"
BIND4="s.userid = u.id"
BIND5="s.roleid = r.id"
BIND6="i.courseid = c.id"
BIND7="g.itemid = i.id"
BIND8="g.userid = u.id"
GROUP_BY="GROUP BY m.id,u.id"
ORDER="ORDER BY u.id, c.startdate, m.id, e.id, c.id" 
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
OUTPUTFILE="${DIR_OUTPUT}/${DATABASE}_grade.log"

## sql (you can tweek with above variable)
MYSQL_SQL="SELECT ${VIEW_COLUMNS} ${FROM_TABLES} WHERE ${BIND1} and ${BIND2} and ${BIND3} and ${BIND4} and ${BIND5} and ${BIND6} and ${BIND7} and ${BIND8} ${GROUP_BY} ${ORDER} ${FORMAT}"

## execute sql 
eval "mysql -h ${HOST} -u ${USER} --password='${PASSWORD}' ${DATABASE} -e '${MYSQL_SQL}'" > "${OUTPUTFILE}" 2>&1

## remove unneeded strings 
sed -i 's/<[^>]*>//g' "${OUTPUTFILE}" >/dev/null 2>&1

exit 0
