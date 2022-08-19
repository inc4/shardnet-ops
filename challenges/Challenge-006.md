# Challenge - 006
![logo](https://clutchco-static.s3.amazonaws.com/s3fs-public/logos/f6c6bbce275df2b17b9f93614e5d4a9a.png?VersionId=UIElRv4d9sdz1zf_yyHVozLKMMU7C.YF)
## Cron task for ping

Ansible workflow for this task:

[shardnet/tasks/near-ping.yml](https://github.com/inc4/shardnet-ops/tree/main/ansible/roles/shardnet)
```
---
- name: Create directory for logs
  file:
    path: "{{ logs_dir }}"
    state: directory
    mode: 0644

- name: Copy cronjob template
  template:
    src: ping.j2
    dest: /opt/near/ping.sh
    mode: 0755

- name: Ping to network automatically
  cron:
    name: "Run near ping"
    user: "root"
    weekday: "*"
    minute: "0"
    hour: "*/2"
    job: "sh /opt/near/ping.sh"
    state: present
```

Cron job template

[/templates/ping.j2](https://github.com/inc4/shardnet-ops/blob/main/ansible/roles/shardnet/templates/ping.j2)
```
#!/bin/sh
# Ping call to renew Proposal added to crontab

export NEAR_ENV={{ NEAR_ENV }}
export LOGS={{ logs_dir }}
export POOLID={{ node_account_id }}
export ACCOUNTID={{ node_account_id }}

echo "---" >> $LOGS/all.log
date >> $LOGS/all.log
near call $POOLID.factory.shardnet.near ping '{}' --accountId $ACCOUNTID.shardnet.near --gas=300000000000000 >> $LOGS/all.log
near proposals | grep $POOLID >> $LOGS/all.log
near validators current | grep $POOLID >> $LOGS/all.log
near validators next | grep $POOLID >> $LOGS/all.log
```

### Results:

List crontab to see it is running:

![img9](https://github.com/inc4/shardnet-ops/blob/b9570ff7cc378e039c6ef3097a825ac3d99c214d/challenges/img/img9.png)

***At the moment, explorer doesn't work and it is impossible to create a screenshot (8/19/22).***

But we can review the details of the transaction to make sure everything is working correctly.

``cat /opt/near/logs/all.log``

<details><summary>all.log</summary>

```
root@ip-172-31-9-6:~# cat /opt/near/logs/all.log
---
Thu Aug 18 16:05:01 UTC 2022
---
Thu Aug 18 16:08:40 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Receipts: 3V8jo8chHbbxh2uTfAqvgqBUcM65sp37noAZ5WSnzFG7, 4qaaMhfaNxiF4pUFrajfH7XVLCoG8Sd3RPNA4RPZExGx, AqJqPqwQzaf5VzzvQMaWV6Cs1HrnBKNJCAEauThezYEV
        Log [inc4.factory.shardnet.near]: Epoch 75: Contract received total rewards of 1556653354251000000000 tokens. New total staked balance is 1172018820216009271000000000. Total number of shares 1171923511298184287000940591
        Log [inc4.factory.shardnet.near]: Total rewards fee is 54478436835860401863 and burn is 466958030021660587403 stake shares.
Transaction Id 5poAmPzs6NMaLuxiqAxvGVbAbCEuULqLMbbwNCntGL1L
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/5poAmPzs6NMaLuxiqAxvGVbAbCEuULqLMbbwNCntGL1L
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Thu Aug 18 18:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Receipts: DW2wSS6tzmYr1QTqNEWg3sXUb37gganWvn1B1FSthEY8, HhwiJs9sA2royUc1YRPFaVMH36SDg6jugZnkDRCEreHx, 9nm26AJGzrZT8bu8uzo4oVdRf2vvauF8XEFFPBkk9yLv
        Log [inc4.factory.shardnet.near]: Epoch 76: Contract received total rewards of 1556659771748000000000 tokens. New total staked balance is 1172020376875781019000000000. Total number of shares 1171924032736340273996894675
        Log [inc4.factory.shardnet.near]: Total rewards fee is 54478613312074204158 and burn is 466959542674921749926 stake shares.
Transaction Id B2LXunanVf3qL79cmaKaoUkVsoZK4hGGBsat2EhXnB41
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/B2LXunanVf3qL79cmaKaoUkVsoZK4hGGBsat2EhXnB41
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Thu Aug 18 20:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Transaction Id 7pax6AuwN1KAp6U52pLpa69PazG2a3nwAECo9j31otFv
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/7pax6AuwN1KAp6U52pLpa69PazG2a3nwAECo9j31otFv
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Thu Aug 18 22:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Receipts: EPqmf5ABTuqNs4q54SMuw8jFqUGF6iTLbGsiGN7xnQrJ, GJFr1aRQd5StM9ePPEmBdUvL2wQ5GDHNYQr9y74yJZQU, 67KEwDqBhFWuvfrGondTWwnXY5zQheM9JPnzHKXQbXgW
        Log [inc4.factory.shardnet.near]: Epoch 77: Contract received total rewards of 1628952633731888635424 tokens. New total staked balance is 1172022005828414750888635424. Total number of shares 1171924578390109886208882487
        Log [inc4.factory.shardnet.near]: Total rewards fee is 57008602795305730069 and burn is 488645166816906257743 stake shares.
Transaction Id 2iCt5p4Xv6kfN8cPCLXVhsN6d1rTSKyaAUzuZ2GYNGeT
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/2iCt5p4Xv6kfN8cPCLXVhsN6d1rTSKyaAUzuZ2GYNGeT
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Fri Aug 19 00:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Transaction Id 6wFDTFxDgcX6ReLG5GN7bq7vaJVGo7VR8eRbbPxvzqzt
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/6wFDTFxDgcX6ReLG5GN7bq7vaJVGo7VR8eRbbPxvzqzt
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Fri Aug 19 02:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Receipts: 3fmy13oV2zZ7uwPXfs3jYpkcNSUwzracCGgztzu37Msx, BC4H3qhrUvCd6mVykKb9SeTtfRVvZnraxC1Qm3jc3rJS, JZFDiSTSeEDjdqUXd9zvjUhqkAQALd5neDbu4K4dCGM
        Log [inc4.factory.shardnet.near]: Epoch 78: Contract received total rewards of 1611968414035000000000 tokens. New total staked balance is 1172023617796828785888635424. Total number of shares 1171925118354145008645524608
        Log [inc4.factory.shardnet.near]: Total rewards fee is 56414152923239649176 and burn is 483549882199196992945 stake shares.
Transaction Id EoV9QWhkzZ43pCeLFykRBBRLxi2HSRUR6e2dqmyWmZXp
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/EoV9QWhkzZ43pCeLFykRBBRLxi2HSRUR6e2dqmyWmZXp
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Fri Aug 19 04:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Transaction Id AqUcBjMnHioQqdjLRUrd197T2fHpNZ6nRjmrnnMNkBjg
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/AqUcBjMnHioQqdjLRUrd197T2fHpNZ6nRjmrnnMNkBjg
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Fri Aug 19 06:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Receipts: H2xH8iMet6WqVAc1G4b8hv5gPodDeV4j8KCbUuxbnDMK, 9hzQDjuVbVDYgMPzQgLXNjAkigLarhNTNMX8EdQaZFjh, 9fTw4v5pQ3AShZfMPNv1yMm96vWQrswNu7pX9obHDZWe
        Log [inc4.factory.shardnet.near]: Epoch 79: Contract received total rewards of 1649344367402502542396 tokens. New total staked balance is 1172025267141196188391177820. Total number of shares 1171925670837555191345063724
        Log [inc4.factory.shardnet.near]: Total rewards fee is 57722147332520847369 and burn is 494761262850178691747 stake shares.
Transaction Id 8JiMaiA17VHAhUdgJfPdxVYHYEkdsypicCNBbuR7So2A
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/8JiMaiA17VHAhUdgJfPdxVYHYEkdsypicCNBbuR7So2A
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Fri Aug 19 08:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Transaction Id QWj7b3d7hnvgFkGuDohWFErmudc3DgWDeVxxwFNUsK1
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/QWj7b3d7hnvgFkGuDohWFErmudc3DgWDeVxxwFNUsK1
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
---
Fri Aug 19 10:00:01 UTC 2022
Scheduling a call: inc4.factory.shardnet.near.ping({})
Doing account.functionCall()
Receipts: HkkQjpsap5kL8CHy1fMJxp5Ec2denXfxiQnQ3DmN9Qec, AzK8mrR4Zo6qSEDz4JMBsyc2m1mFpd74ny1TPhjcoDUG, J33f8CU2ZXsEEmb9tnAoGoqzcfGM4tJkzNm872LLZcug
        Log [inc4.factory.shardnet.near]: Epoch 80: Contract received total rewards of 1612006672188000000000 tokens. New total staked balance is 1172026879147868376391177820. Total number of shares 1171926210813406507235111353
        Log [inc4.factory.shardnet.near]: Total rewards fee is 56415387450913885573 and burn is 483560463864976162056 stake shares.
Transaction Id FpWt8kGAfaGrobHufDVaMJrMicEPC43WDKHZNCJoV9Qt
To see the transaction in the transaction explorer, please open this url in your browser
https://explorer.shardnet.near.org/transactions/FpWt8kGAfaGrobHufDVaMJrMicEPC43WDKHZNCJoV9Qt
''
| Proposal(Accepted) | inc4.factory.shardnet.near                   | 1,172              | 1       |
```
</details>

Viewing the latest transaction (ID: ``FpWt8kGAfaGrobHufDVaMJrMicEPC43WDKHZNCJoV9Qt``)

```
near tx-status FpWt8kGAfaGrobHufDVaMJrMicEPC43WDKHZNCJoV9Qt --accountId inc4.shardnet.near
```
<details><summary>response</summary>

```
Transaction inc4.shardnet.near:FpWt8kGAfaGrobHufDVaMJrMicEPC43WDKHZNCJoV9Qt
{
  receipts_outcome: [
    {
      block_hash: '5xoXGLXh1p7wdZk4CaDzL4GcS5qSXJDXcmDbQh3pbHCq',
      id: 'GF13TifhDSAUpesEBmQf8ZYJfrcoUnruJY1YtM1YUyxW',
      outcome: {
        executor_id: 'inc4.factory.shardnet.near',
        gas_burnt: 6958635454078,
        logs: [
          'Epoch 80: Contract received total rewards of 1612006672188000000000 tokens. New total staked balance is 1172026879147868376391177820. Total number of shares 1171926210813406507235111353',
          'Total rewards fee is 56415387450913885573 and burn is 483560463864976162056 stake shares.'
        ],
        metadata: {
          gas_profile: [
            {
              cost: 'FUNCTION_CALL',
              cost_category: 'ACTION_COST',
              gas_used: '2319895039010'
            },
            {
              cost: 'NEW_RECEIPT',
              cost_category: 'ACTION_COST',
              gas_used: '289092464624'
            },
            {
              cost: 'STAKE',
              cost_category: 'ACTION_COST',
              gas_used: '141715687500'
            },
            {
              cost: 'BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '12973637439'
            },
            {
              cost: 'CONTRACT_LOADING_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '35445963'
            },
            {
              cost: 'CONTRACT_LOADING_BYTES',
              cost_category: 'WASM_HOST_COST',
              gas_used: '74898396000'
            },
            {
              cost: 'LOG_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '7086626100'
            },
            {
              cost: 'LOG_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '3616468734'
            },
            {
              cost: 'READ_CACHED_TRIE_NODE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '353400000000'
            },
            {
              cost: 'READ_MEMORY_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '60026853600'
            },
            {
              cost: 'READ_MEMORY_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '3717703674'
            },
            {
              cost: 'READ_REGISTER_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '30205982232'
            },
            {
              cost: 'READ_REGISTER_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '51942174'
            },
            {
              cost: 'STORAGE_READ_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '450854766000'
            },
            {
              cost: 'STORAGE_READ_KEY_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '6747652194'
            },
            {
              cost: 'STORAGE_READ_VALUE_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '2126570895'
            },
            {
              cost: 'STORAGE_WRITE_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '192590208000'
            },
            {
              cost: 'STORAGE_WRITE_EVICTED_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '10566594003'
            },
            {
              cost: 'STORAGE_WRITE_KEY_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '1762071675'
            },
            {
              cost: 'STORAGE_WRITE_VALUE_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '10205099331'
            },
            {
              cost: 'TOUCHING_TRIE_NODE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '273733250742'
            },
            {
              cost: 'UTF8_DECODING_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '12447116244'
            },
            {
              cost: 'UTF8_DECODING_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '95055236154'
            },
            {
              cost: 'WASM_INSTRUCTION',
              cost_category: 'WASM_HOST_COST',
              gas_used: '91284778200'
            },
            {
              cost: 'WRITE_MEMORY_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '44860717776'
            },
            {
              cost: 'WRITE_MEMORY_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '1609749252'
            },
            {
              cost: 'WRITE_REGISTER_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '37251792318'
            },
            {
              cost: 'WRITE_REGISTER_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '2889188640'
            }
          ],
          version: 1
        },
        receipt_ids: [
          'HkkQjpsap5kL8CHy1fMJxp5Ec2denXfxiQnQ3DmN9Qec',
          'AzK8mrR4Zo6qSEDz4JMBsyc2m1mFpd74ny1TPhjcoDUG',
          'J33f8CU2ZXsEEmb9tnAoGoqzcfGM4tJkzNm872LLZcug'
        ],
        status: { SuccessValue: '' },
        tokens_burnt: '6958635454078000000000'
      },
      proof: [
        {
          direction: 'Left',
          hash: 'EeJgniTH4rQk1wpuecnoG8NtwP3KiiA4JgwsC6ut3cuJ'
        },
        {
          direction: 'Right',
          hash: 'GjbakfrqPDiDbw9vFxs2k9PJ4r9XYgUaSPhCKKyim3Zk'
        },
        {
          direction: 'Right',
          hash: 'BFNmVYRKky95FuHTcXY3EgZKwoSzGcSsJ1xhJYYe46YE'
        },
        {
          direction: 'Right',
          hash: 'Ec2achvZwxrek2M469TBVEHRVGmgXnWSHLMmpZqPtwk5'
        },
        {
          direction: 'Right',
          hash: '7zC6qqWHQ6H3enLFTw7gWS9ombgZS9D4LTsLHwxffbfG'
        },
        {
          direction: 'Right',
          hash: '9yEBV1yvzhQ8Wm27nznKn8bSPRwpV7jYPiSvEpxu9C4r'
        },
        {
          direction: 'Left',
          hash: 'XCY7rHmYgkPrraNzDRL9bW8WQXnNKxccR3WRXHhmvjm'
        },
        {
          direction: 'Left',
          hash: 'EVjvjnfSqEvQgq9P7Kov12tQSVJdHpgJJwSvRLt2WFMs'
        }
      ]
    },
    {
      block_hash: '4oF7smfmMR7C2bH7mExPm7Q7UNgd9HcLw5xkHvYSnykh',
      id: 'HkkQjpsap5kL8CHy1fMJxp5Ec2denXfxiQnQ3DmN9Qec',
      outcome: {
        executor_id: 'inc4.factory.shardnet.near',
        gas_burnt: 210277125000,
        logs: [],
        metadata: { gas_profile: [], version: 1 },
        receipt_ids: [ 'C2PcDV93KsFQKTir54NPGExpsgR3QUFtQ39w17wqsZrC' ],
        status: { SuccessValue: '' },
        tokens_burnt: '210777544815123375000'
      },
      proof: [
        {
          direction: 'Right',
          hash: '9A9FRuwrVpbd4HiPKFREpECj1CNjEHQjoCkmBbGDTH5M'
        },
        {
          direction: 'Left',
          hash: 'F4gsJDWtSNRn7Zj6ok9L1aFo7DU2eLLDcZu9SLm8GFtt'
        },
        {
          direction: 'Right',
          hash: 'GusFKydKiLmi1pvsWMXWUFoSMBnRwfvopHn6ZYBQfRyL'
        },
        {
          direction: 'Left',
          hash: '5Bt224Xs9P67r2n3RYfNjzhd8wYhaBMQjwD2eHcvp4WA'
        },
        {
          direction: 'Right',
          hash: 'Gy974pR7i1qZBHxfKqwZAJEPug32ZPdz9MyCCvebgDyo'
        },
        {
          direction: 'Left',
          hash: 'Foo8PyaGgCE411YQyVsSgSgAb2bfpyTq6sGGrQwD48Gw'
        },
        {
          direction: 'Right',
          hash: 'DEWCsEDc5mFToGZn3paMjA74R3bP7uroqpyryVmjKT3o'
        },
        {
          direction: 'Left',
          hash: '53KPj72QKGpJYZKJGMLFM1iXFanFs5HT8kve3V6K4aoN'
        }
      ]
    },
    {
      block_hash: '4JciujHWrGjtkKc8D5TYwYuNmvYcC8dJfjhohjnRaXoo',
      id: 'C2PcDV93KsFQKTir54NPGExpsgR3QUFtQ39w17wqsZrC',
      outcome: {
        executor_id: 'inc4.shardnet.near',
        gas_burnt: 223182562500,
        logs: [],
        metadata: { gas_profile: [], version: 1 },
        receipt_ids: [],
        status: { SuccessValue: '' },
        tokens_burnt: '0'
      },
      proof: [
        {
          direction: 'Left',
          hash: 'FwrwakbaEerXwZcZmtRSkNsHmtmfi1Cfb26BeXJoiK4x'
        },
        {
          direction: 'Left',
          hash: '125JfwWE5Ej8sSixQxLHmar9DtH8pB8bsXfvBzbvmR7X'
        },
        {
          direction: 'Right',
          hash: '5cnteRhgMfvUmjNNzz3kPZp3ai8p53Gf2Hp7xVZN9TNd'
        },
        {
          direction: 'Left',
          hash: 'HgUhtqUiz4TUeyvhYyfH94KWWXQSXZAConu2xaqkDHfw'
        },
        {
          direction: 'Left',
          hash: '3N55fBtKQnxXF3d5bqCCwkgaz4Tv4uVrZkbeBrbgKvmv'
        },
        {
          direction: 'Right',
          hash: 'GJbLETAJt55Md2Lv7YBJHWaQQfjRxYMecQ9EPJ7UA9Pb'
        },
        {
          direction: 'Left',
          hash: 'BVS7bRaKJ8e38L8qJJDiEbQhh6CpB7AU2AJX3GGKMZbh'
        }
      ]
    },
    {
      block_hash: '4JciujHWrGjtkKc8D5TYwYuNmvYcC8dJfjhohjnRaXoo',
      id: 'AzK8mrR4Zo6qSEDz4JMBsyc2m1mFpd74ny1TPhjcoDUG',
      outcome: {
        executor_id: 'inc4.factory.shardnet.near',
        gas_burnt: 2851126409481,
        logs: [],
        metadata: {
          gas_profile: [
            {
              cost: 'BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '3971521665'
            },
            {
              cost: 'CONTRACT_LOADING_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '35445963'
            },
            {
              cost: 'CONTRACT_LOADING_BYTES',
              cost_category: 'WASM_HOST_COST',
              gas_used: '74898396000'
            },
            {
              cost: 'READ_CACHED_TRIE_NODE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '50160000000'
            },
            {
              cost: 'READ_MEMORY_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '7829589600'
            },
            {
              cost: 'READ_MEMORY_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '923723919'
            },
            {
              cost: 'READ_REGISTER_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '10068660744'
            },
            {
              cost: 'READ_REGISTER_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '28090170'
            },
            {
              cost: 'STORAGE_READ_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '56356845750'
            },
            {
              cost: 'STORAGE_READ_KEY_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '154762665'
            },
            {
              cost: 'STORAGE_READ_VALUE_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '1307364165'
            },
            {
              cost: 'STORAGE_WRITE_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '64196736000'
            },
            {
              cost: 'STORAGE_WRITE_EVICTED_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '7483332531'
            },
            {
              cost: 'STORAGE_WRITE_KEY_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '352414335'
            },
            {
              cost: 'STORAGE_WRITE_VALUE_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '7227319587'
            },
            {
              cost: 'TOUCHING_TRIE_NODE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '80509779630'
            },
            {
              cost: 'WASM_INSTRUCTION',
              cost_category: 'WASM_HOST_COST',
              gas_used: '26532235488'
            },
            {
              cost: 'WRITE_MEMORY_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '14018974305'
            },
            {
              cost: 'WRITE_MEMORY_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '819855372'
            },
            {
              cost: 'WRITE_REGISTER_BASE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '14327612430'
            },
            {
              cost: 'WRITE_REGISTER_BYTE',
              cost_category: 'WASM_HOST_COST',
              gas_used: '1969210152'
            }
          ],
          version: 1
        },
        receipt_ids: [ 'DDLY8FNYk83FtHfAeJawJwhBv4opwz56zaR1F7ecQ1mT' ],
        status: { SuccessValue: '' },
        tokens_burnt: '2857925616079251357864'
      },
      proof: [
        {
          direction: 'Right',
          hash: '6B4wB3By4N2aQVbyG34kyh4eUk8r2KawPBexLaxykAWr'
        },
        {
          direction: 'Right',
          hash: '97K742VxNKHz7DwfQ9adDgEEwudhnr5GCXzQXae2ZgVq'
        },
        {
          direction: 'Left',
          hash: 'CniA3evsJ4rcgM92pjhw3SVmgdva6W8Xbbrpo4oGhZTt'
        },
        {
          direction: 'Left',
          hash: 'HgUhtqUiz4TUeyvhYyfH94KWWXQSXZAConu2xaqkDHfw'
        },
        {
          direction: 'Left',
          hash: '3N55fBtKQnxXF3d5bqCCwkgaz4Tv4uVrZkbeBrbgKvmv'
        },
        {
          direction: 'Right',
          hash: 'GJbLETAJt55Md2Lv7YBJHWaQQfjRxYMecQ9EPJ7UA9Pb'
        },
        {
          direction: 'Left',
          hash: 'BVS7bRaKJ8e38L8qJJDiEbQhh6CpB7AU2AJX3GGKMZbh'
        }
      ]
    },
    {
      block_hash: 'HHQh7bc2CdVL3mkAcj1hydGHY2oaKFdRRkXt2rLdX8ji',
      id: 'DDLY8FNYk83FtHfAeJawJwhBv4opwz56zaR1F7ecQ1mT',
      outcome: {
        executor_id: 'inc4.shardnet.near',
        gas_burnt: 223182562500,
        logs: [],
        metadata: { gas_profile: [], version: 1 },
        receipt_ids: [],
        status: { SuccessValue: '' },
        tokens_burnt: '0'
      },
      proof: [
        {
          direction: 'Left',
          hash: '3pm2kmNSG8q7uvmhKELCk9wxbKJnQnXoDYcUSxku4EH2'
        },
        {
          direction: 'Left',
          hash: 'kiNTUqeyHeKduxWGHjJS39TAaEtwY6DpTA1vN2yFkDZ'
        },
        {
          direction: 'Left',
          hash: '6wiDkKskLvarmwqfTGNGqdYWqc8xffCfJ2gtyLzkpEMC'
        },
        {
          direction: 'Left',
          hash: 'EgYgRSxjkRWGVpnnPwqfTNzBWxytYYKmfZgrAcrgqWkm'
        }
      ]
    },
    {
      block_hash: '4oF7smfmMR7C2bH7mExPm7Q7UNgd9HcLw5xkHvYSnykh',
      id: 'J33f8CU2ZXsEEmb9tnAoGoqzcfGM4tJkzNm872LLZcug',
      outcome: {
        executor_id: 'inc4.shardnet.near',
        gas_burnt: 223182562500,
        logs: [],
        metadata: { gas_profile: [], version: 1 },
        receipt_ids: [],
        status: { SuccessValue: '' },
        tokens_burnt: '0'
      },
      proof: [
        {
          direction: 'Left',
          hash: 'wT8xgmPoG6VnvFYUshN14vi6ac8JpWLj4rdwp38ADBo'
        },
        {
          direction: 'Left',
          hash: 'F4gsJDWtSNRn7Zj6ok9L1aFo7DU2eLLDcZu9SLm8GFtt'
        },
        {
          direction: 'Right',
          hash: 'GusFKydKiLmi1pvsWMXWUFoSMBnRwfvopHn6ZYBQfRyL'
        },
        {
          direction: 'Left',
          hash: '5Bt224Xs9P67r2n3RYfNjzhd8wYhaBMQjwD2eHcvp4WA'
        },
        {
          direction: 'Right',
          hash: 'Gy974pR7i1qZBHxfKqwZAJEPug32ZPdz9MyCCvebgDyo'
        },
        {
          direction: 'Left',
          hash: 'Foo8PyaGgCE411YQyVsSgSgAb2bfpyTq6sGGrQwD48Gw'
        },
        {
          direction: 'Right',
          hash: 'DEWCsEDc5mFToGZn3paMjA74R3bP7uroqpyryVmjKT3o'
        },
        {
          direction: 'Left',
          hash: '53KPj72QKGpJYZKJGMLFM1iXFanFs5HT8kve3V6K4aoN'
        }
      ]
    }
  ],
  status: { SuccessValue: '' },
  transaction: {
    actions: [
      {
        FunctionCall: {
          args: 'e30=',
          deposit: '0',
          gas: 300000000000000,
          method_name: 'ping'
        }
      }
    ],
    hash: 'FpWt8kGAfaGrobHufDVaMJrMicEPC43WDKHZNCJoV9Qt',
    nonce: 1955385000040,
    public_key: 'ed25519:8AYEvMv74KmYY4LS6y35YMLVni7kxHgpvCi2uCFs6q6w',
    receiver_id: 'inc4.factory.shardnet.near',
    signature: 'ed25519:3Ur8QCp8Asy7U6J1ntVXyefjkR6tRpNxVt2UKJum3wnvagP8WaZuAjLZsghJqWNMZZ33uzU13hE6csaiAAAkDQXA',
    signer_id: 'inc4.shardnet.near'
  },
  transaction_outcome: {
    block_hash: '8bhMoL8wzdKEjZ6aWKqiPevQr9vRac2FZfSDYMkGXxZy',
    id: 'FpWt8kGAfaGrobHufDVaMJrMicEPC43WDKHZNCJoV9Qt',
    outcome: {
      executor_id: 'inc4.shardnet.near',
      gas_burnt: 2427934415604,
      logs: [],
      metadata: { gas_profile: null, version: 1 },
      receipt_ids: [ 'GF13TifhDSAUpesEBmQf8ZYJfrcoUnruJY1YtM1YUyxW' ],
      status: {
        SuccessReceiptId: 'GF13TifhDSAUpesEBmQf8ZYJfrcoUnruJY1YtM1YUyxW'
      },
      tokens_burnt: '2427934415604000000000'
    },
    proof: [
      {
        direction: 'Right',
        hash: '4XaqKqS1uHMvxWCAT5Puod1648r87712TqgXwqiwDLgf'
      },
      {
        direction: 'Left',
        hash: '9TQDuLZBhLf6nZgPbpY46DgEFyarhVKEAd3FLj1ivc6Z'
      },
      {
        direction: 'Left',
        hash: 'Eh5jZ82QgXr51YXWD1zTeKbRBBmDYewm9W7Gk5Pq335v'
      },
      {
        direction: 'Right',
        hash: 'HMWUiPQ5SZeuaAPiZUoUACDkBb4X9Sjeh1MMrLjkZzWi'
      },
      {
        direction: 'Left',
        hash: 'Eqbnnt7943qLEQmpLaDxbwWDB97yem4bzubjDoWnLExy'
      },
      {
        direction: 'Right',
        hash: '4fs69b5SQoXWeBnJpQ2kFtRRP1DiaW1LQittajhNaGF5'
      },
      {
        direction: 'Left',
        hash: 'B1cm7pqGu9tfqKj9z7SoH9ZVsuKM3wg5qxSV8m16xU7Y'
      }
    ]
  }
}
```
</details>
