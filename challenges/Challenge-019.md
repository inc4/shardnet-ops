# Challenge - 019
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)

## Dashboards

Grafana and Prometheus were connected to the project during [Challenge #004](https://github.com/inc4/shardnet-ops/blob/main/challenges/Challenge-005.md#monitoring). More details can be found at the link to that report.

Final playbook for monitoring and logging:

[.monitor.yml](https://github.com/inc4/shardnet-ops/blob/main/ansible/monitor.yml)

```
---
- name: Deploy node-exporter
  hosts: all
  roles:
  - cloudalchemy.node_exporter
  tags: node

- name: Deploy prometheus
  hosts: monitoring-shardnet-dev
  roles:
  - cloudalchemy.prometheus
  vars:
    prometheus_version: 2.37.0
    prometheus_targets:
      node:
      - targets:
        - "{{ hostvars['validator-shardnet-dev']['ansible_facts']['all_ipv4_addresses'] | first }}:9100"
        labels:
          app: shardnet
          env: dev
          job: node
      near:
      - targets:
        - "{{ hostvars['validator-shardnet-dev']['ansible_facts']['all_ipv4_addresses'] | first }}:3030"
        labels:
          app: shardnet
          env: dev
          job: near
    prometheus_scrape_configs:
    - job_name: "node"
      file_sd_configs:
      - files:
        - "/etc/prometheus/file_sd/node.yml"
    - job_name: "near"
      file_sd_configs:
      - files:
        - "/etc/prometheus/file_sd/near.yml"
  tags: prometheus

- name: Deploy promtail
  hosts: validator-shardnet-dev
  become: yes
  roles:
    - promtail
  vars:
    loki_client_url_host: "{{ hostvars['monitoring-shardnet-dev']['ansible_facts']['all_ipv4_addresses'] | first }}"
  tags: promtail

- name: Deploy loki
  hosts: monitoring-shardnet-dev
  become: yes
  roles:
    - loki
  vars:
    loki_http_listen_address: 0.0.0.0
  tags: loki

- name: Deploy grafana
  hosts: monitoring-shardnet-dev
  become: yes
  tasks:
    - include_vars:
        dir: env/dev/group_vars/all
    - include_role:
        name: cloudalchemy.grafana
      vars:
        grafana_address: 0.0.0.0
        grafana_port: 3000
        grafana_users:
          viewers_can_edit: True
        grafana_security:
          admin_user: admin
          admin_password: "{{ grafana_admin_password }}"
        grafana_datasources:
          - name: "Prometheus"
            type: "prometheus"
            access: "proxy"
            url: "http://localhost:9090"
          - name: "Loki"
            type: "loki"
            access: "proxy"
            url: "http://localhost:3100"
            isDefault: true
  tags: grafana
```

In this place, we point Prometheus to node exportet and near exportet. Which are available on a local network:

<details><summary>targets</summary>

```
prometheus_targets:
  node:
  - targets:
    - "{{ hostvars['validator-shardnet-dev']['ansible_facts']['all_ipv4_addresses'] | first }}:9100"
    labels:
      app: shardnet
      env: dev
      job: node
  near:
  - targets:
    - "{{ hostvars['validator-shardnet-dev']['ansible_facts']['all_ipv4_addresses'] | first }}:3030"
    labels:
      app: shardnet
      env: dev
      job: near
prometheus_scrape_configs:
- job_name: "node"
  file_sd_configs:
  - files:
    - "/etc/prometheus/file_sd/node.yml"
- job_name: "near"
  file_sd_configs:
  - files:
    - "/etc/prometheus/file_sd/near.yml"
```
</details>

Two dashboards have been created for near exporter.

### NEAR general dashboard

You can find source code here: [challenges/dasboards/near_general.yml](https://github.com/inc4/shardnet-ops/blob/main/challenges/dashboards/near-general.json)

It consists of such parts:


- Block Height  - ```near_block_height_head```
- Total Transactions - ```near_transaction_processed_successfully_total```
- Block Processed - ``` rate(near_block_processed_total[$__rate_interval])```
- Blocks Per Minute - ```near_blocks_per_minute```
- Validators - near_is_validator - ```near_validator_active_total```
- Chunk - ```histogram_quantile(0.95, sum(rate(near_chunk_tgas_used_hist_bucket- [$__rate_interval])) by (le))```
- Block Processing - ```rate(near_block_processing_time_count[$__rate_interval])```
- Transactions Pool Entries - ```near_transaction_pool_entries```
- Blocks Per Minute - ```near_blocks_per_minute```
- Processed Total Transactions - ```rate(near_transaction_processed_total[$__rate_interval])```
- Processed Successfully Transactions - ```rate(near_transaction_processed_successfully_total- [$__rate_interval])```
- Reachable Peers - ```near_peer_reachable```
- Chunk Tgas Used - ```near_chunk_tgas_used```
- Block Processing Time Count - ```rate(near_block_processing_time_count[$__rate_interval])```
- 

Screenshot:

![img22](https://github.com/inc4/shardnet-ops/blob/b883fd19fac4b7a20090f95f54dba0a4979e40e6/challenges/img/img22.png)

### NEAR validator dashboard

You can find source code here: [challenges/dasboards/near_validator.yml](https://github.com/inc4/shardnet-ops/blob/main/challenges/dashboards/near-validator.json)

It consists of such parts:


- Node is validator - ```near_is_validator```
- Missed blocks - ```near_validators_blocks_expected{account_id="$account_id",job="$job"} - near_validators_blocks_produced{account_id="$account_id",job="$job"}```
- Percent of produced blocks - ```near_validators_blocks_produced{account_id="$account_id",job="$job"} / near_validators_blocks_expected{account_id="$account_id",job="$job"}```
- Missed chunks -  ```near_validators_chunks_expected{account_id="$account_id",job="$job"} - near_validators_chunks_produced{account_id="$account_id",job="$job"}```
- Percent of produced chunks - ```near_validators_chunks_produced{account_id="$account_id",job="$job"} / near_validators_chunks_expected{account_id="$account_id",job="$job"}```
- Connected peers - ```near_peer_connections_total```
- Total validator stake - ```near_validators_stake_total```
- And a few additional charts

Screenshot:

![img23](https://github.com/inc4/shardnet-ops/blob/b883fd19fac4b7a20090f95f54dba0a4979e40e6/challenges/img/img23.png)

![img24](https://github.com/inc4/shardnet-ops/blob/b883fd19fac4b7a20090f95f54dba0a4979e40e6/challenges/img/img24.png)

### Node exporter dashboard

We used a dashboard from the Grafana Dashboards - ID 6126 [Download](https://grafana.com/grafana/dashboards/6126-node-dashboard/).

Screenshot:

![img25](https://github.com/inc4/shardnet-ops/blob/b883fd19fac4b7a20090f95f54dba0a4979e40e6/challenges/img/img24.png)

### Challenge submission

Grafana URL: [18.156.162.14:3000](http://18.156.162.14:3000/)

Prothemeus URL: [18.156.162.14:9090](http://18.156.162.14:9090/)

 UserName: ``demo_user``

UserPassword: ``demo_user``


- near general dashboard -> [url](http://18.156.162.14:3000/d/neargeneraldashboard/near-general-dashboard?orgId=1)
- near validator dashboard -> [url](http://18.156.162.14:3000/d/0JfDOdG4z/near-validator-dasboard?orgId=1)
- node exporter dashboard -> [url](http://18.156.162.14:3000/d/oOSnZg7mz/node-dashboard?orgId=1)
