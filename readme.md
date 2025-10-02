Starknet Foundry is the command line tool used to build and deploy Starknet contracts, sncast being used to perform Starknet RPC calls.

**Creating and Deploying Accounts**
The first step i nusing sncast is creating and deploying an account using the command *sncast account create --name --network*. This will spin up an account with an address, to which STRK tokens should then be sent, test tokens if using Sepolia, real tokens if on mainnet. The account should then be deployed using *sncast account deploy --name --network*.  Accounts can also be imported from Ready or Braavos wallets.

**Declaring and Deploying Contract**
Starknet contracts havetoo be declared before deployment to be available to the network. Contracts are declared using *sncast account declare --network --contract-name*. This generates a class hash and transaction hash for the contract..The class hash is then used to deploy the contract using the command *sncast account deploy --network --class-hash*.

**Invoking and calling contracts**
When a contract is declared and deployed it's possible to interact with it i.e. manipulating it's read and write functions, which are referred to as calling and invoking respectively. Invoking or calling a contract requires the contract address, the function name and the required function arguments.

**Conclusion**
Starknet Foundry and sncast provide a robust set of tools that make working with and manipulating Starknet contracts easy and simple and their usefulness can't be overestimated in the building process.