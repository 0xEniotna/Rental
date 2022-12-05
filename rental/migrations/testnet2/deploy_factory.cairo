%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        testnet_admin = 0x02cCbBbDF4293338e776A69f25D02D78ccC16C24296f8335db46D42650cc719A

        # Let's deploy the factory contract
        # rental_hash = declare("./build/rental.json", config={"max_fee":"auto"}).class_hash
        rental_hash = 0x3e4726581368725cc7c50eea574a10116d2a986f55e058328e037aacd0145d7
        rental_factory = deploy_contract("./build/factory.json", {
            "_owner": testnet_admin,
            "_rental_class_hash": rental_hash,
        }).contract_address
        
        print(json.dumps({
            "rental_hash": hex(rental_hash),
            "rental_factory": hex(rental_factory),
        }, indent=4))
    %}
    return ();
}

@external
func down() {
    %{ assert False, "Not implemented" %}
    return ();
}
