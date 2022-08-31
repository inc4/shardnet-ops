# Challenge - 013
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)

## Setup Backup Node

Continuing the previous groups of challenges, the following sequence of tasks was written on Ansible and used for setup backup node.

sources: [ansible/roles/shardnet/tasks/near-setup-backup.yml](https://github.com/inc4/shardnet-ops/blob/main/ansible/roles/shardnet/tasks/near-setup-backup.yml)

``.near-setup-backup.yml``
```
---
- name: Create backup directory if not exist
  file:
    path: "{{ backup_dir }}"
    state: directory
    mode: 0755

- name: Create directory for validator keys
  file:
    path: "{{ backup_dir }}/validator/keys"
    state: directory
    mode: 0755

- name: Save validator keys
  copy:
    src: /root/.near/{{ item }}
    dest: "{{ backup_dir }}/validator/keys/{{ item }}"
    mode: 0755
    remote_src: yes
  with_items:
    ["node_key.json","validator_key.json"]

- name: Fetch a github repository
  git:
    repo: 'https://github.com/nearprotocol/nearcore.git'
    dest: "{{ backup_dir }}/repository"
    version: "{{ version_tag }}"
    force: true
  register: git_backup

- name: Install/Upgrade nearcore
  block:

    - name: Execute cargo build --release
      shell: "{{ item }}"
      with_items:
        - export PATH="$HOME/.cargo/bin:$PATH" && make shardnet-release
      args:
        chdir: "{{ backup_dir }}/repository"

    - name: Initialize nearcore
      shell: "{{ item }}"
      with_items:
        - ./target/release/neard --home {{ backup_dir }} init --chain-id shardnet --download-genesis
      args:
        chdir: "{{ backup_dir }}/repository"
      register: init

    - name: Check near version
      command: "{{ backup_dir }}/repository/target/release/neard --version"
      register: version

    - debug: var=version.stdout_lines

    # - name: Download config
    #   get_url: 
    #     url: "{{ config_url }}"
    #     dest: "{{ blockchain_data_dir }}/config.json"
    #     force: yes

    - name: Extract neard binaries into /usr/bin
      copy:
        src: "{{ backup_dir }}/repository/target/release/neard"
        dest: /usr/bin/neard_backup
        mode: 0755
        remote_src: true

  when: git_backup.changed

- name: Create temporary files
  template:
    src: "{{ item.file_src }}"
    dest: "{{ item.file_dest }}"
    mode: 0755
  with_items:
    - { file_src: node_key.j2, file_dest: "{{ backup_dir }}/node_key.json" }
    - { file_src: validator_key.j2, file_dest: "{{ backup_dir }}/validator_key.json" }
    - { file_src: config.j2, file_dest: "{{ backup_dir }}/config.json" }
  vars:
    node_id: "{{ node_backup_account_id }}"
    node_public: "{{ node_backup_public_key }}"
    node_secret: "{{ node_backup_secret_key }}"
    validator_id: "{{ validator_backup_account_id }}"
    validator_public: "{{ validator_backup_public_key }}"
    validator_secret: "{{ validator_backup_secret_key }}"
    config_key: "{{ node_backup_public_key }}"

- name: Copy backup service template
  template:
    src: neard_backup.j2
    dest: /etc/systemd/system/neard_backup.service

- name: Enable backup node
  block:

    - name: Disable validator node
      systemd:
        name: neard
        state: stopped

    - name: Enable backup node in check mode
      systemd:
        name: neard_backup
        state: started
        daemon_reload: yes

    - name: Enable backup node in validator mode
      block:
      
        - name: Copy validator configs
          template:
            src: "{{ item.file_src }}"
            dest: "{{ item.file_dest }}"
            mode: 0755
          with_items:
            - { file_src: node_key.j2, file_dest: "{{ backup_dir }}/node_key.json" }
            - { file_src: validator_key.j2, file_dest: "{{ backup_dir }}/validator_key.json" }
            - { file_src: config.j2, file_dest: "{{ backup_dir }}/config.json" }
          vars:
            node_id: "{{ node_account_id }}"
            node_public: "{{ node_public_key }}"
            node_secret: "{{ node_secret_key }}"
            validator_id: "{{ validator_account_id }}"
            validator_public: "{{ validator_public_key }}"
            validator_secret: "{{ validator_secret_key }}"
            config_key: "{{ node_public_key }}"

        - name: Enable backup node
          systemd:
            name: neard_backup
            state: restarted
            daemon_reload: yes

      when: not node_backup_check_mode

  when: node_backup_enable
```

Additional preparation:

```node_key``` and ```validator_key``` for backup node were previously created and saved. Their values are substituted into templates ([shardnet/templates/](https://github.com/inc4/shardnet-ops/tree/main/ansible/roles/shardnet/templates)) and stored in vault ([env/dev/group_vars/all](https://github.com/inc4/shardnet-ops/tree/main/ansible/env/dev/group_vars/all)).

Running algorithm for this challenge

 1. Create backup directory
 2. Backup keys from validator node
 3. Fetch nearcore repo
 4. Project build
 5. Initialize nearcore
 6. Extract neard binaries into /usr/bin
 7. Copy keys and config for the backup node
 8. Create backup service
 9. Enable backup node
    - Disable validator node
    - Enable backup node in check mode
    - Enable backup node in validator mode
         - Copy validator config and keys
         - Enable backup node with validator keys

AWX is used to run playbooks, screenshots of successful execution:

![img15](https://github.com/inc4/shardnet-ops/blob/eb884b7e09a2f920c33b5668af356b0644930a98/challenges/img/img15.png)

![img16](https://github.com/inc4/shardnet-ops/blob/eb884b7e09a2f920c33b5668af356b0644930a98/challenges/img/img16.png)

## Challenge submission

To match the acceptance criteria, screenshot of timestamp and keys:

![img17](https://github.com/inc4/shardnet-ops/blob/eb884b7e09a2f920c33b5668af356b0644930a98/challenges/img/img17.png)

Logs from loki are also available for viewing in Grafana => [Challenge - 005#Monitoring](https://github.com/inc4/shardnet-ops/blob/main/challenges/Challenge-005.md#monitoring)
