%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        testnet_admin = 0x02cCbBbDF4293338e776A69f25D02D78ccC16C24296f8335db46D42650cc719A
        testnet_eth_erc20 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        testnet_factory = 0x06b5a551430a328d8e78933ae996030e1cf5e73e58ad692e3c5ac90b28b7f79c
        # rental_hash= 0x3e4726581368725cc7c50eea574a10116d2a986f55e058328e037aacd0145d7
        public_key=2775954746159100240394835917573393993756840506754192982217539669037606939924
        rental_hash = declare("./build/rental.json", config={"max_fee":"auto"}).class_hash
        proxy_hash = 0x1067c8f4aa8f7d6380cc1b633551e2a516d69ad3de08af1b3d82e111b4feda4
        # Let's deploy the factory contract
        # proxy_hash: felt, selector : felt, constructor_data_len : felt, constructor_data : felt*

        proxy = deploy_contract("./build/proxy.json", {
            "implementation_hash": rental_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [
                testnet_admin, # proxy_admin
                testnet_admin, # owner
                public_key, # owner pubkey
                testnet_eth_erc20, # 
            ]
        }).contract_address

        print(json.dumps({
            "proxy": proxy,
        }, indent=4))
    %}
    return ();
}

@external
func down() {
    %{ assert False, "Not implemented" %}
    return ();
}
