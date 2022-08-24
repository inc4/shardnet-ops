# Challenge - 008
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)

## Smart Contract

Rust and Cargo required for this challenge were installed in the previous step.

[ansible/roles/shardnet/tasks/near-setup.yml](https://github.com/inc4/shardnet-ops/blob/main/ansible/roles/shardnet/tasks/near-setup.yml)
```
...
- name: Setup rust
  import_role:
    name: hurricanehrndz.rustup
  vars:
    rustup_cargo_crates: ''
...
```

Ansible workflow for compile smart contract:

[shardnet/tasks/near-contract.yml](https://github.com/inc4/shardnet-ops/blob/main/ansible/roles/shardnet/tasks/near-contract.yml)

```
---
- name: Create directory for contract
  file:
    path: "{{ contract_dir }}"
    state: directory
    mode: 0644

- name: Add wasm32 toolchain
  shell: "{{ item }}"
  with_items:
    - export PATH="$HOME/.cargo/bin:$PATH" && rustup target add wasm32-unknown-unknown
  register: rust_target
  changed_when: false

- name: Clone a github repository
  git:
    repo: 'https://github.com/zavodil/near-staking-pool-owner.git'
    dest: "{{ contract_dir }}"
    version: "{{ contract_tag }}"
  register: contract

- name: Build contract
  block:
    - name: Compile smart contract
      shell: "{{ item }}"
      with_items:
        - export PATH="$HOME/.cargo/bin:$PATH" && cargo build --target wasm32-unknown-unknown --release
      args:
        chdir: "{{ contract_dir }}/contract"

  when: contract.changed
```
## Deploy and withdraw

Deploy smart contract: 

```
NEAR_ENV=shardnet near deploy inc4.shardnet.near --wasmFile target/wasm32-unknown-unknown/release/contract.wasm
```

<details><summary>results</summary>

```
Starting deployment. Account id: inc4.shardnet.near, node: https://rpc.shardnet.near.org, helper: https://helper.shardnet.near.org, file: target/wasm32-unknown-unknown/release/contract.wasm
Transaction Id FcgfYWpuvBWoMp5JM9pZdtmowickTZEzkNqiTsag6qQF
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/FcgfYWpuvBWoMp5JM9pZdtmowickTZEzkNqiTsag6qQF
Done deploying to inc4.shardnet.near
root@ip-172-31-9-6:/opt/near/contract/contract# NEAR_ENV=shardnet near call inc4.shardnet.near new '{"staking_pool_account_id": "inc4.factory.shardnet.near", "owner_id":"inc4.shardnet.near", "reward_receivers": [["inc4.shardnet.near", {"numerator": 3, "denominator":10}], ["olehb.shardnet.near", {"numerator": 70, "denominator":100}]]}' --accountId inc4.shardnet.near
Scheduling a call: inc4.shardnet.near.new({"staking_pool_account_id": "inc4.factory.shardnet.near", "owner_id":"inc4.shardnet.near", "reward_receivers": [["inc4.shardnet.near", {"numerator": 3, "denominator":10}], ["olehb.shardnet.near", {"numerator": 70, "denominator":100}]]})
Doing account.functionCall()
Transaction Id 4yVLcM3EDGkyfmDTqMNJpX46UBQsFriuH3zKEupDztFo
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/4yVLcM3EDGkyfmDTqMNJpX46UBQsFriuH3zKEupDztFo
''
```
</details>


Initialize the smart contract picking accounts for splitting revenue:

```
NEAR_ENV=shardnet near call inc4.shardnet.near new '{"staking_pool_account_id": "inc4.factory.shardnet.near", "owner_id":"inc4.shardnet.near", "reward_receivers": [["inc4.shardnet.near", {"numerator": 3, "denominator":10}], ["olehb.shardnet.near", {"numerator": 70, "denominator":100}]]}' --accountId inc4.shardnet.near
```
- 30% **=>** inc4.shardnet.near
- 70% **=>** olehb.shardnet.near

<details><summary>results</summary>

```
Scheduling a call: inc4.shardnet.near.new({"staking_pool_account_id": "inc4.factory.shardnet.near", "owner_id":"inc4.shardnet.near", "reward_receivers": [["inc4.shardnet.near", {"numerator": 3, "denominator":10}], ["olehb.shardnet.near", {"numerator": 70, "denominator":100}]]})
Doing account.functionCall()
Transaction Id 4yVLcM3EDGkyfmDTqMNJpX46UBQsFriuH3zKEupDztFo
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/4yVLcM3EDGkyfmDTqMNJpX46UBQsFriuH3zKEupDztFo
''
```
</details>

***Two or three epochs later***

Checking the possibility of withdrawal:
```
near view inc4.factory.shardnet.near is_account_unstaked_balance_available '{"account_id": "inc4.shardnet.near"}'
```
results:
```
View call: inc4.factory.shardnet.near.is_account_unstaked_balance_available({"account_id": "inc4.shardnet.near"})
true
```
Checking balance for withdrawal:
```
near view inc4.factory.shardnet.near get_accounts '{"from_index": 0, "limit": 10}' --accountId inc4.shardnet.near
```
![img13](https://github.com/inc4/shardnet-ops/blob/596181382898b9ec16b1fcc4f3f8bdb8045480e7/challenges/img/img13.png)

Withdraw transaction:

```
NEAR_ENV=shardnet near call inc4.shardnet.near withdraw '{}' --accountId inc4.shardnet.near --gas 200000000000000
```
<details><summary>results</summary>

```
Scheduling a call: inc4.shardnet.near.withdraw({})
Doing account.functionCall()
Retrying request to broadcast_tx_commit as it has timed out [
  'EgAAAGluYzQuc2hhcmRuZXQubmVhcgBqc1vj8q/6Flvjbq39mJiLqWcVukXktcJ6038I2h+sgK5AB0bHAQAAEgAAAGluYzQuc2hhcmRuZXQubmVhcvKkVrhSJYSfXP9pr1TxeBSRb9aQ43FedtJs6AknS0UoAQAAAAIIAAAAd2l0aGRyYXcCAAAAe30AgPQg5rUAAAAAAAAAAAAAAAAAAAAAAAAAgCGGNBc1NYh+VMjgRraigFNJhSmqRiV7RsQ8UjSY2eBi/Rsluwp40MZ0+ZlwgNrr9sTjjUxo+s7+jEQnL0J3CQ=='
]
Receipts: 61P1axWyaGUogjPMZseaCFkm86WvHwjuM5WQg35UFH3N, 5RQKKUbehn5dh8xXgDV9TW5wnxTyZj4GVjxZEEwteuwK, J9kKh4yhWrWbf6f4GmRdHaiMHc7R6VuipPMGgUfdx6Ak
        Log [inc4.shardnet.near]: Epoch 106: Contract received total rewards of 1842064540642000000000 tokens. New total staked balance is 2622066991610676607977125359. Total number of shares 2621784834768539746962797354
        Log [inc4.shardnet.near]: Total rewards fee is 64465321155799202737 and burn is 552559895621136023466 stake shares.
Receipts: 3BJTmuMVPmTuCufuiDLY2F8hESfbrGT3Z4zGJYZk6sjE, 9c6shyTE3CDGSRpf9oFh1n6XTCDmEvpGLPTLZmE4LBjb, F3DapFDb18KMuG7gZ5FYgKHP577drPPnDKm6LUpHiRzJ
        Log [inc4.shardnet.near]: Withdrawing from staking pool: 50007535682588276632765298
Receipts: FQULebawvUPcuSTZZfZyUzmVSYjiUkuSfCNq4NJ9jUXz, 9YQ2UaRFLfwMRYPtJAWiVLrguvFeoQDhwMQ1hqiPonrK
        Log [inc4.shardnet.near]: @inc4.shardnet.near withdrawing 50007535682588276632765298. New unstaked balance is 0
Receipts: 3s7XE6N7QBtidw1jDwXGCUMJDEaxGrbAMzT3mQgE2UiS, 4EbF3abFuNqgCZQeSqSZ8NMCPgw6EQxzyFUXRq4yzbq3, BuiTCuGRtp3KCUvqVruybmUehzZVE7b27Pn6yJeDLKBS, DrhRyY2oLJBAMxeYjGapci7hcbyju2FYNBAapCv8tguC
        Log [inc4.shardnet.near]: Withdraw success! Received unstaked rewards: 50007535682588276632765298
        Log [inc4.shardnet.near]: Sending 15002260704776482989829589 to inc4.shardnet.near
        Log [inc4.shardnet.near]: Sending 35005274977811793642935708 to olehb.shardnet.near
        Log [inc4.shardnet.near]: Unstaking all from staking pool
Receipts: 4G9K9sbeayJswESkTnCTPdZYQtDveM2pocsbMZb1BLvb, GQPTBcCbyCq15qgmkpetCFVv3MVAMSGjPFX7daWW4eeW, 7sFLg2ta2kGaNK4en4KNGqWnWR8AbpJ155jkCtJBsDs6
        Log [inc4.shardnet.near]: @inc4.shardnet.near unstaking 333114569012379329237. Spent 333078723034697203682 staking shares. Total 333114569012379329237 unstaked balance and 0 staking shares
        Log [inc4.shardnet.near]: Contract total staked balance is 2622066658496107595597796123. Total number of shares 2621784501689816712265593672
Transaction Id C9NrbsYEjSKNMZt2NPBUtQUf57vB8pts6HFtRZU1hUjk
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/C9NrbsYEjSKNMZt2NPBUtQUf57vB8pts6HFtRZU1hUjk
''
```
</details>

**Challenge URL**: 

[https://explorer.shardnet.near.org/transactions/C9NrbsYEjSKNMZt2NPBUtQUf57vB8pts6HFtRZU1hUjk](https://explorer.shardnet.near.org/transactions/C9NrbsYEjSKNMZt2NPBUtQUf57vB8pts6HFtRZU1hUjk)

**Challenge image**:
![img14](https://github.com/inc4/shardnet-ops/blob/596181382898b9ec16b1fcc4f3f8bdb8045480e7/challenges/img/img14.png)
