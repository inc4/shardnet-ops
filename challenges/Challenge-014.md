# Challenge - 014
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)

## Auto-backup node script

To automate deployment and running scripts, the following group of tasks was created in Ansible:

[.near-data-auto-backup.yml](https://github.com/inc4/shardnet-ops/blob/main/ansible/roles/shardnet/tasks/near-data-auto-backup.yml)

```
---
- name: Install packages
  apt:
    update_cache: true
    name:
      - moreutils
      - gzip

- name: Create directory for logs if it does exist
  file:
    path: "{{ item }}"
    state: directory
    mode: 0644
  with_items:
    ["{{ logs_dir }}","{{ backup_data_dir }}"]

- name: Copy script templates
  template:
    src: "{{ item }}.j2"
    dest: /opt/near/{{ item }}.sh
    mode: 0755
  with_items:
    ["backup","restore"]

- name: Create schedule for data backup
  cron:
    name: "Create near backup"
    user: "root"
    weekday: "*"
    minute: "*"
    hour: "12"
    job: "sh /opt/near/backup.sh >> {{ logs_dir }}/backup.log"
    state: present

- name: Data recovery
  block:
    - name: Run restore from backup
      shell: "{{ item }}"
      with_items:
        - . restore.sh >> {{ logs_dir }}/restore.log
      changed_when: false
      args:
        chdir: "/opt/near/"
  when: data_recovery
```
Two scripts were created.

=> 1. to create backups
- Save the data folder as an archive
- Check the folder with backups and remove the oldest

=> 2. to restore them
- Write a simple script for quick database restoring

### First bash script 

[.backup.sh](https://github.com/inc4/shardnet-ops/blob/main/ansible/roles/shardnet/templates/backup.j2)
```
#!/bin/bash

DATE=$(date +%Y-%m-%d-%H-%M)
DATA_DIR={{ data_dir }}
BACKUP_DIR_NAME=near_${DATE}
WORKDIR=/opt/near
BACKUP_DIR_PATH={{ backup_data_dir }}

cd $WORKDIR

sudo systemctl stop neard.service

wait

echo "NEAR node was stopped" | ts

if [ -d "$BACKUP_DIR_PATH" ]; then
    echo "Backup started" | ts
    tar -zcvf $BACKUP_DIR_PATH/$BACKUP_DIR_NAME.tar.gz -C $DATA_DIR .
    
    echo "Sending ping to healthchecks" | ts
    curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/{{ healthchecks_token }} | ts
   
    echo "Archive created" | ts
     
    echo "Removing old archives" | ts
    cd {{ backup_data_dir }} && rm -rf `ls -t | awk 'NR>1'` | ts
    echo " Cleaning completed" | ts

else
    echo "$BACKUP_DIR_PATH is not exist. Check your permissions."
    exit 0
fi

sudo systemctl start neard.service

echo "NEAR node was started" | ts
```

Short explanation: 

Check the existence of the directory and start creating an archive with a timestamp.
```
if [ -d "$BACKUP_DIR_PATH" ]; then
    echo "Backup started" | ts
    tar -zcvf $BACKUP_DIR_PATH/$BACKUP_DIR_NAME.tar.gz -C $DATA_DIR .
```
Sending a ping about the successful creation of the archive.

```
curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/{{ healthchecks_token }} | ts
```
This line is used to purge older versions. Delete everything except new archive: 
```
cd {{ backup_data_dir }} && rm -rf `ls -t | awk 'NR>1'` | ts
```

```awk 'NR>1'``` - here we can specify how many previous versions to keep

### Second bash script

[.restore.sh](https://github.com/inc4/shardnet-ops/blob/main/ansible/roles/shardnet/templates/restore.j2)
```
#!/bin/bash

DATA_DIR={{ data_dir }}
BACKUP_DIR={{ backup_data_dir }}

echo "Starting data recovery process" | ts

FILE_NAME=`cd $BACKUP_DIR && ls -At | head -1`

if [ "$(ls -A $DATA_DIR)" ]; then

     echo "$DATA_DIR isn't empty. Start cleaning this directory" | ts
     rm -rf $DATA_DIR/*
     
fi
    echo "$DATA_DIR is Empty" | ts
    echo "Start data extraction" | ts
    tar -xvf $BACKUP_DIR/$FILE_NAME -C $DATA_DIR

```

Backup directory contains one file, its name can be obtained like this:

```
FILE_NAME=`cd $BACKUP_DIR && ls -At | head -1`
```

Clear data directory if it isn't empty:
```
if [ "$(ls -A $DATA_DIR)" ]; then
     echo "$DATA_DIR isn't empty. Start cleaning this directory" | ts
     rm -rf $DATA_DIR/*
fi
```

Extract data from backup archive:
```
tar -xvf $BACKUP_DIR/$FILE_NAME -C $DATA_DIR
```

### Manual run results

``.backup.sh``

![img18](https://github.com/inc4/shardnet-ops/blob/41a5e59879b89804ddd249488819552e000830c1/challenges/img/img18.png)

*One hour later*

![img20](https://github.com/inc4/shardnet-ops/blob/41a5e59879b89804ddd249488819552e000830c1/challenges/img/img20.png)

Report from healthchecks:

![img19](https://github.com/inc4/shardnet-ops/blob/41a5e59879b89804ddd249488819552e000830c1/challenges/img/img19.png)

``.restore.sh``

![img21]()
