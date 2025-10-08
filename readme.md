# Declare
sncast declare --contract-name StakingContract --network sepolia

# Deploy
sncast deploy --class-hash 0xABC... --constructor-calldata arg1 arg2 --network sepolia

# Call (read)
sncast call --contract-address 0x... --function get_counter --arguments 0x123

# Invoke (write)
sncast invoke --contract-address 0x... --function transfer --arguments 0x456 1000


screenshot for the terminal actions for deploying and interacting with contract{
cairo-bootcamp-5\my_contract.png
cairo-bootcamp-5\my_contract_1.png}

Transaction hash = 0x04b1476289183b9940d504060e2d37e81553fc64e0ec0ddf66ccddcef70579f5
