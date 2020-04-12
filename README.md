# moodle_debugger

```
##
How to use

./moodle_debugger.sh <Moodle directory>

It will create a new directory.
Execute command on a new directory.

How to use

## Example

If a new directory is /va/www/tml/moodle_debug, which is default,

calling cron 
# /usr/bin/php /var/www/html/moodle_debug/admin/cli/cron.php
calling flatfile sync 
# /usr/bin/php /var/www/html/moodle_debug/enrol/flatfile/cli/sync.php --verbose
calling schedule flatfile_sync_task
# /usr/bin/php /var/www/html/moodle_debug/admin/tool/task/cli/schedule_task.php --execute=\\enrol_flatfile\\task\\flatfile_sync_task

For options, execute --help for each command.

Enjoy!
```
