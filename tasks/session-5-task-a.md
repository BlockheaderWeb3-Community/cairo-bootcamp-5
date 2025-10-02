# Session 5a Assignment: sncast Deployment 

In this session, you’ll extend your understanding of Starknet contracts and practice using **sncast** to interact with the deployed version of your [HelloStarknet contract](../starknet_contracts/src/contracts/HelloStarknet.cairo)  

---

## 📝 Tasks

### 1. Add `set_balance` Function  
- Create a function named `set_balance`  
- It should accept an argument (`new_balance`)  
- Update the stored balance to this new value  

---

### 2. Add `reset_balance` Function  
- Create a function named `reset_balance`  
- It should set the balance back to **zero**  

---

### 3. Use `sncast` to Send STRK Tokens  
You will practice using **sncast** to transfer STRK tokens to one of your peers.  

Run the following command (replace with your peer’s wallet address):  

```bash
sncast invoke \
  --contract-address <TOKEN_ADDR> \
  --url <YOUR_RPC_URL> \
  --function "transfer" \
  --arguments '<PEER_WALLET_ADDRESS>, <AMOUNT>'
```

In this session, you’ll extend your understanding of Starknet contracts and practice using **sncast** to interact with live contracts.  

---

## 📝 Tasks

### 1. Add `set_balance` Function  
- Create a function named `set_balance`  
- It should accept an argument (`new_balance`)  
- Update the stored balance to this new value  

---

### 2. Add `reset_balance` Function  
- Create a function named `reset_balance`  
- It should set the balance back to **zero**  

---

### 3. Use `sncast` to Send STRK Tokens  
You will practice using **sncast** to transfer STRK tokens to one of your peers.  

Run the following command (replace with your peer’s wallet address):  

```bash
sncast invoke \
  --contract-address 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d \
  --url  <YOUR_RPC_URL> \
  --function "transfer" \
  --arguments '<PEER_WALLET_ADDRESS>, 10000000000000000000'
```

#### MY TRANSACTION HASH
https://sepolia.starkscan.co/tx/0x04178df11f3e300623d54366db9afe7b5c10cdd1f739a64529fe710251c59ca0


##### Submission

- Push your updated Counter contract to your GitHub repo.
- Share your sncast transaction hash as proof of STRK token transfer.
- Create a PR