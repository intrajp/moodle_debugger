# moodle_debugger

```
##
How to use

./moodle_debugger.sh <Moodle directory>

How to use

## Example

calling cron 
# /usr/bin/php /var/www/html/moodle_debug/admin/cli/cron.php
calling flatfile sync 
# /usr/bin/php /var/www/html/moodle_debug/enrol/flatfile/cli/sync.php --verbose
calling schedule flatfile_sync_task
# /usr/bin/php /var/www/html/moodle_debug/admin/tool/task/cli/schedule_task.php --execute=\\enrol_flatfile\\task\\flatfile_sync_task
For options, execute --help for each command.
```
