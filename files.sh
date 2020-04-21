#!/bin/bash

##
## moodle_debugger
##
## files.sh
##
## This program outputs files in current directory in many patterns from default storage of Moodle.
##
## Version 0.1.9
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
FILES_DIR="files"
DIR_OUTPUT="${OUTPUTDIR_BASE}/${FILES_DIR}/"

## set host here
HOST="localhost"
## set user here
USER="root"
## set password here
PASSWORD=""
## set database name here
DATABASE="moodle"

####
VIEW_COLUMNS="f.component, x.contextlevel, x.instanceid, u.username, c.fullname, c.shortname, f.timecreated, f.timemodified, sum(f.filesize) as size_in_bytes, sum(f.filesize/1024) as size_in_kbytes, sum(f.filesize/1048576) as size_in_mbytes, sum(f.filesize/1073741824) as size_in_gbytes, sum(case when (f.filesize > 0) then 1 else 0 end) as number_of_files"
FROM_TABLES="FROM mdl_files f, mdl_course c, mdl_context x, mdl_user u"
BIND1="f.contextid = x.id"
BIND2="c.id = x.instanceid"
BIND3="u.id = f.userid"
GROUP_BY="GROUP BY f.contextid, x.instanceid"
ORDER_FILESIZE="sum(f.filesize)"
ORDER_TIMECREATED="f.timecreated"
ORDER_MODIFIED="f.timemodified"
DESC="DESC"
ASC="ASC"
FORMAT_NORMAL=";"
FORMAT_ROW="\G"
FORMAT="${FORMAT_ROW}"
COMPONENT_BACKUP="f.component = \"backup\""
COMPONENT_QUESTION="f.component = \"question\""
COMPONENT_COURSE="f.component = \"course\""
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
        OUTPUTFILE="${DIR_OUTPUT}/${DATABASE}_component_${COMPONENT_STRING}_contextlevel_${CONTEXTLEVEL_STRING}.log"

        ## sql (you can tweek order with above variable)
        MYSQL_SQL="SELECT ${VIEW_COLUMNS} ${FROM_TABLES} WHERE ${BIND1} and ${COMPONENT} and ${CONTEXTLEVEL} and ${BIND2} and ${BIND3} ${GROUP_BY} ORDER BY ${ORDER_TIMECREATED} ${DESC}, ${ORDER_FILESIZE} ${DESC} ${FORMAT}"

        ## execute sql 
        eval "mysql -h ${HOST} -u ${USER} --password='${PASSWORD}' ${DATABASE} -e '${MYSQL_SQL}'" > "${OUTPUTFILE}" 2>&1

        ## remove unneeded strings 
        sed -i 's/<[^>]*>//g' "${OUTPUTFILE}" >/dev/null 2>&1

        # Uncomment if you want to echo date string  
        #FORMAT="${FORMAT_NORMAL}"

        if [ "${FORMAT}" = "${FORMAT_NORMAL}" ]; then
            OUTPUTFILE_DATE_FILESIZE_PRE="${OUTPUTFILE}"
            OUTPUTFILE_DATE_FILESIZE_PRE=${OUTPUTFILE_DATE_FILESIZE_PRE//.log/}
            OUTPUTFILE_DATE_FILESIZE="${DIR_OUTPUT}/${OUTPUTFILE_DATE_FILESIZE_PRE}_date_filesize.log"
            sed -i 's/\t/:/g' "${OUTPUTFILE}" >/dev/null 2>&1
            TIMECREATED_DATE=0
            TIMECREATED_DATE_PRE=0
            SIZE_IN_BYTES=0
            SIZE_IN_BYTES_ALL=0
            SIZE_IN_BYTES_DAY=0
            FIRSTLINE=$(sed -n '1p' "${OUTPUTFILE}")
            sed -i "\$a${FIRSTLINE}" "${OUTPUTFILE}" >/dev/null 2>&1
            while read line
            do
               if [ "${line}" = "EOF" ]; then
                   break
               fi
               TIMECREATED=$(echo "${line}" | awk -F":" '{ print $(NF-6) }')
               SIZE_IN_BYTES=$(echo "${line}" | awk -F":" '{ print $(NF-4) }')
               SIZE_IN_BYTES_ALL=$((SIZE_IN_BYTES_ALL + SIZE_IN_BYTES))
               SIZE_IN_BYTES_DAY=$((SIZE_IN_BYTES_DAY + SIZE_IN_BYTES))
               TIMECREATED_DATE=$(echo "${TIMECREATED}" | awk '{print strftime("%Y-%m-%d %H:%M",$1)}')
               if [ "${TIMECREATED_DATE}" != "${TIMECREATED_DATE_PRE}" ]; then
                   TIMECREATED_DATE_PRE="${TIMECREATED_DATE}"
                   SIZE_IN_BYTES_DAY_TOP="${SIZE_IN_BYTES}"
                   SIZE_IN_BYTES_DAY=$((SIZE_IN_BYTES_DAY - SIZE_IN_BYTES))
                   SIZE_IN_KBYTES_DAY=$((SIZE_IN_BYTES_DAY / 1024))
                   SIZE_IN_MBYTES_DAY=$((SIZE_IN_BYTES_DAY / 1024 / 1024))
                   SIZE_IN_GBYTES_DAY=$((SIZE_IN_BYTES_DAY / 1024 / 1024 /1024))
                   if [ "${SIZE_IN_BYTES_DAY}" -gt 0 ]; then
                       echo "${SIZE_IN_BYTES_DAY}Bytes"
                   fi
                   if [ "${SIZE_IN_KBYTES_DAY}" -gt 0 ]; then
                       echo "${SIZE_IN_KBYTES_DAY}KBytes"
                   fi
                   if [ "${SIZE_IN_MBYTES_DAY}" -gt 0 ]; then
                       echo "${SIZE_IN_MBYTES_DAY}MBytes"
                   fi
                   if [ "${SIZE_IN_GBYTES_DAY}" -gt 0 ]; then
                       echo "${SIZE_IN_GBYTES_DAY}GBytes"
                   fi
                   SIZE_IN_BYTES_DAY=0
                   SIZE_IN_KBYTES_DAY=0
                   SIZE_IN_BYTES_DAY_TOP=0
                   echo "==== ${TIMECREATED_DATE} ===="
                   SIZE_IN_BYTES_DAY=$((SIZE_IN_BYTES_DAY + SIZE_IN_BYTES))
               fi
               echo "${line}"
            done < "${OUTPUTFILE}" > "${OUTPUTFILE_DATE_FILESIZE}"
            sed -i 1d "${OUTPUTFILE_DATE_FILESIZE}" 
            SIZE_IN_KBYTES_ALL=$((SIZE_IN_BYTES_ALL/1024))
            SIZE_IN_MBYTES_ALL=$((SIZE_IN_BYTES_ALL/1024/1024))
            SIZE_IN_GBYTES_ALL=$((SIZE_IN_BYTES_ALL/1024/1024/1024))
            SIZE_IN_BYTES_ALL_STR="${SIZE_IN_BYTES_ALL}Bytes"
            SIZE_IN_KBYTES_ALL_STR="${SIZE_IN_KBYTES_ALL}KBytes"
            SIZE_IN_MBYTES_ALL_STR="${SIZE_IN_MBYTES_ALL}MBytes"
            SIZE_IN_GBYTES_ALL_STR="${SIZE_IN_GBYTES_ALL}GBytes"
            if [ "${SIZE_IN_GBYTES_ALL}" -gt 0 ]; then
                sed -i 1a\"${SIZE_IN_GBYTES_ALL_STR}\" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            fi
            if [ "${SIZE_IN_MBYTES_ALL}" -gt 0 ]; then
                sed -i 1a\"${SIZE_IN_MBYTES_ALL_STR}\" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            fi
            if [ "${SIZE_IN_KBYTES_ALL}" -gt 0 ]; then
                sed -i 1a\"${SIZE_IN_KBYTES_ALL_STR}\" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            fi
            if [ "${SIZE_IN_BYTES_ALL}" -gt 0 ]; then
                sed -i 1a\"${SIZE_IN_BYTES_ALL_STR}\" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            fi
            sed -i 1a\"Filesize_All\" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            sed -i \$d "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null 2>&1
            sed -i \$d "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null 2>&1
            sed -i "\$a========" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            sed -i "\$aFilesize_All" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            if [ "${SIZE_IN_BYTES_ALL}" -gt 0 ]; then
                sed -i "\$a${SIZE_IN_BYTES_ALL_STR}" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            fi
            if [ "${SIZE_IN_KBYTES_ALL}" -gt 0 ]; then
                sed -i "\$a${SIZE_IN_KBYTES_ALL_STR}" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            fi
            if [ "${SIZE_IN_MBYTES_ALL}" -gt 0 ]; then
                sed -i "\$a${SIZE_IN_MBYTES_ALL_STR}" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            fi
            if [ "${SIZE_IN_GBYTES_ALL}" -gt 0 ]; then
                sed -i "\$a${SIZE_IN_GBYTES_ALL_STR}" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            fi
            sed -i "\$a========" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null
            sed -i "\$a${FIRSTLINE}" "${OUTPUTFILE_DATE_FILESIZE}" >/dev/null 2>&1
        fi
    done
done

exit 0
