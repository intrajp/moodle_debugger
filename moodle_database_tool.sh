#!/bin/bash

##
## moodle_database_tool.sh
##
## This program output files in current directory in many patterns from default storage of Moodle.
##
## Version 0.1.3
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

## set host here
HOST="localhost"
## set user here
USER="root"
## set password here
PASSWORD=""
## set database name here
DATABASE="moodle"

####
BIND1="f.contextid = x.id"
BIND2="c.id = x.instanceid"
FROM_TABLES="FROM mdl_files f, mdl_course c, mdl_context x"
VIEW_COLUMNS="f.component, x.contextlevel, c.fullname, c.shortname, sum(f.filesize) as size_in_bytes, sum(f.filesize/1024) as size_in_kbytes, sum(f.filesize/1048576) as size_in_mbytes, sum(f.filesize/1073741824) as size_in_gbytes, sum(case when (f.filesize > 0) then 1 else 0 end) as number_of_files"
GROUP_BY="GROUP BY f.contextid, x.instanceid"
ORDER_BY="ORDER BY sum(f.filesize) DESC"
COMPONENT_BACKUP="f.component = \"backup\""
COMPONENT_QUESTION="f.component = \"question\""
COMPONENT_COURSE="f.component = \"course\""
OUTPUTFILE=""
####

#set -x

for ((i=0;i<6;i++))
do
    if [ "${i}" -eq 0 ]; then
        # system
        CONTEXTLEVEL="x.contextlevel = 10"
        CONTEXTLEVEL_STRING="system"
    elif [ "${i}" -eq 1 ]; then
        # user
        CONTEXTLEVEL="x.contextlevel = 30"
        CONTEXTLEVEL_STRING="user"
    elif [ "${i}" -eq 2 ]; then
        # coursecat 
        CONTEXTLEVEL="x.contextlevel = 40"
        CONTEXTLEVEL_STRING="coursecat"
    elif [ "${i}" -eq 3 ]; then
        # course 
        CONTEXTLEVEL="x.contextlevel = 50"
        CONTEXTLEVEL_STRING="course"
    elif [ "${i}" -eq 4 ]; then
        # module 
        CONTEXTLEVEL="x.contextlevel = 70"
        CONTEXTLEVEL_STRING="module"
    elif [ "${i}" -eq 5 ]; then
        # block 
        CONTEXTLEVEL="x.contextlevel = 80"
        CONTEXTLEVEL_STRING="block"
    fi

    for ((j=0;j<3;j++))
    do
        if [ "${j}" -eq 0 ];then
            COMPONENT="f.component = \"backup\""
	    COMPONENT_STRING="backup"
        elif [ "${j}" -eq 1 ];then
            COMPONENT="f.component = \"course\""
	    COMPONENT_STRING="course"
        elif [ "${j}" -eq 2 ];then
            COMPONENT="f.component = \"question\""
	    COMPONENT_STRING="question"
        fi

        ## output file name 
        OUTPUTFILE="${DATABASE}_component_${COMPONENT_STRING}_contextlevel_${CONTEXTLEVEL_STRING}.log"
        ## sql 
        MYSQL_SQL="SELECT ${VIEW_COLUMNS} ${FROM_TABLES} WHERE ${BIND1} and ${COMPONENT} and ${CONTEXTLEVEL} and ${BIND2} ${GROUP_BY} ${ORDER_BY}\G"
        ## execute sql 
        eval "mysql -h ${HOST} -u ${USER} --password='${PASSWORD}' ${DATABASE} -e '${MYSQL_SQL}'" > "${OUTPUTFILE}" 2>&1
        ## remove unneeded strings 
        sed -i 's/<[^>]*>//g' "${OUTPUTFILE}" >/dev/null 2>&1
    done
done

exit 0
