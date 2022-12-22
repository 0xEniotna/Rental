# Rental
This repo contains a universal NFT rental system.

We dont need to deposit collateral or minting NFT replicas. Here you just "transfer" ownership to an escrow smart-contract account. 
Every transactions from this escrow account are blocked (apart from `approve`). 

**What is working**:

- Owner can deposit a NFT in an escrow account, escrow becomes NFT owner
- A borrower can subscribe. his pubkey is linked to the escrow. Escrow depends on owner pub key + borrower pub key
- we dont want the borrower to perform tx through escrow (because we dont like scammers). Every tx are blocked. Only approve transactions and ETH transactions are accepted (for the fees).

**What has to be improved is**:

- code quality
- remove useless stuff
- improve payment system
- prevent borrower to transfer ETH
- maybe add time

# ATM INTERACTIONS WITH EVERY SMART-CONTRACTS ARE POSSIBLE. WE NEED TO BLOCK THAT.
# AS WE CAN APPROVE, SOMEONE COULD INTERACT WITH A CONTRACT THAT PERFORMS TRANSFERFROM. WE NEED TO EITHER RESTRICT APPROVAL TO ADMIN OR BLOCK TRANSACTIONS
