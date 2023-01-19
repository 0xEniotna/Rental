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

Class hash for contract "rental": 0x1ff06790b799add7d3c89bfc51b77fb2ad3861f98a06af79cd1f36c1121920b
Class hash for contract "factory": 0x156defaa3b82d38bb748f74319e5231ea2eebded4814a2cf2d7157d4b9a08a0
Class hash for contract "nft": 0x5e83c4aa4cf8ae94441a7ac4fd4c624888f5eee2357cc5da0392f1e20479362
Class hash for contract "token": 0x69b31c76b74bf0512bb98161ca781fc441c9aace2603185a2f80a4d351eb6bb
Class hash for contract "proxy": 0xeafb0413e759430def79539db681f8a4eb98cf4196fe457077d694c6aeeb82

