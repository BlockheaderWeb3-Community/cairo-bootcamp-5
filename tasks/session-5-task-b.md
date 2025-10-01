# Session 5b Assignment: sncast Deployment

In this session, you will **extend a [Counter contract](../starknet_contracts/src/contracts/counter.cairo)** and practice using **sncast** to send transactions.

---

Deploy or use the given Counter contract, then use sncast to:

- Call `get_count` to check the initial value.
- Invoke `increment` twice.
- Call `get_count` again to verify it increased.
- Invoke `decrement` once.
- Call `get_count` again to verify it decreased.

## Submission for this task

I have completed the above steps and verified the Counter contract's functionality using sncast. The final count after the operations is as expected, demonstrating successful interaction with the contract.

Here's the deployed contract address: `0x03e141db08c1ca3003ad7f5f2adc7473db0e60db052a684505a7a45fb687b75f`

Here are the sncast commands I used:

```bash
sncast call --url https://2fa39eeec817.ngrok-free.app --contract-address=0x03e141db08c1ca3003ad7f5f2adc7473db0e60db052a684505a7a45fb687b75f --function "get_count"
command: call
response: 0_u32
response_raw: [0x0]
```

```bash
sncast invoke --url https://2fa39eeec817.ngrok-free.app --contract-address=0x03e141db08c1ca3003ad7f5f2adc7473db0e60db052a684505a7a45fb687b75f --function "increment"
command: invoke
transaction_hash: 0x071223726e95728f000d0bbfbdc96aea7012a9f16ed61a4d41e082adc67b12d4

To see invocation details, visit:
transaction: https://sepolia.starkscan.co/tx/0x071223726e95728f000d0bbfbdc96aea7012a9f16ed61a4d41e082adc67b12d4
```

```bash
sncast invoke --url https://2fa39eeec817.ngrok-free.app --contract-address=0x03e141db08c1ca3003ad7f5f2adc7473db0e60db052a684505a7a45fb687b75f --function "decrement"
command: invoke
transaction_hash: 0x011c8a17f1620765e4f90a912f4446671a91409c89b3bda01ae65ce9ab620688

To see invocation details, visit:
transaction: https://sepolia.starkscan.co/tx/0x011c8a17f1620765e4f90a912f4446671a91409c89b3bda01ae65ce9ab620688
```

```bash
sncast call --url https://2fa39eeec817.ngrok-free.app --contract-address=0x03e141db08c1ca3003ad7f5f2adc7473db0e60db052a684505a7a45fb687b75f --function "get_count"
command: call
response: 1_u32
response_raw: [0x1]
```
