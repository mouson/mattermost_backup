Mattermost BackUp Srcipt
===
modify from https://github.com/KsenZ/redmine_backup

# Usage

1) git clone git@github.com:mouson/mattermost_backup.git

2) Copy conf.sh.sample to conf.sh

~~~sh
cp conf.sh.sample conf.sh
~~~

3) modify config file "conf.sh"

4) testing

~~~sh
cd mattermost_backup
./mattermost_backup.sh
./mattermost_backup.sh d
~~~

5) add cron job

~~~sh
5 3 * * * /home/backup/mattermost_backup/mattermost_backup.cron > /dev/null 2>&1
~~~

