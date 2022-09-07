# Challenge - 016
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)

## Notifi

To complete this challenge necessary tokens/secrets were obtained from Notifi team.

![img26](https://github.com/inc4/shardnet-ops/blob/aaea9acce7e4b7ef152a771908264d37c0d4d7f5/challenges/img/img26.png)

Automation of the deployment process includes the following tasks in Ansible: 
[.near-notify.yml](https://github.com/inc4/shardnet-ops/blob/main/ansible/roles/shardnet/tasks/near-notifi.yml)

```
---
- name: Create directory for notifi
  file:
    path: "{{ notifi_dir }}"
    state: directory
    mode: 0755

- name: Fetch notifi template source
  git:
    repo: 'https://github.com/OlehBandrivskyi/notifi-near-integration.git'
    dest: "{{ notifi_dir }}"
    version: "{{ notifi_tag }}"
    force: true
  register: notifi

- name: Copy env template 
  template:
    src: "notifi_env.j2"
    dest: "{{ notifi_dir }}/.env"
    mode: 0755

- name: Build notifi
  shell: "{{ item }}"
  with_items:
    - npm i && npm run build
  args:
    chdir: "{{ notifi_dir }}"
  when: notifi.changed

- name: Enable cronjon for notifications
  cron:
    name: "Notifi"
    user: "root"
    weekday: "*"
    minute: "0"
    hour: "*/3"
    job: "cd {{ notifi_dir }} && /usr/bin/node build/index.js /
          && echo 'notifi run time' | ts >> {{ logs_dir }}/notifi.txt"
    state: present
```

``NotifiClient.sendBroadcastMessage`` method was used to send an email.

A fork was made with a template for using this method, authorization and creating logs. 

Repo: [https://github.com/OlehBandrivskyi/notifi-near-integration.git](https://github.com/OlehBandrivskyi/notifi-near-integration.git)

.env template:
```
POOL_ID="{{ validator_account_id }}"
NODE_IP={{ notifi_node_ip }}
SID={{ notifi_sid }}
SECRET='{{ notifi_secret }}'
TOPIC={{ notifi_topic }}
```

The cronjob runs every 3 hours and generates a log with a timestamp.

```
job: "cd {{ notifi_dir }} && /usr/bin/node build/index.js /
      && echo 'notifi run time' | ts >> {{ logs_dir }}/notifi.txt"
```
![img28](https://github.com/inc4/shardnet-ops/blob/6f1da6f382279c21ce87627475bad29d605c4b45/challenges/img/img28.png)

Proof of completion:

![img27](https://github.com/inc4/shardnet-ops/blob/aaea9acce7e4b7ef152a771908264d37c0d4d7f5/challenges/img/img27.png)
