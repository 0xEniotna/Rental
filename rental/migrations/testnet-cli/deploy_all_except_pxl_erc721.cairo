%lang starknet

@external
func up() {
    %{
        import json
        from starkware.starknet.public.abi import get_selector_from_name

        testnet_admin = 0x02cCbBbDF4293338e776A69f25D02D78ccC16C24296f8335db46D42650cc719A
        testnet_eth_erc20 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        pxl_erc721_address = 0x00b9bd3bd3e23f17c809699a816f242e23cd0bc5ac830dbd38fd06f0bdd631f0
        auction_bid_increment = 100000000000 # On testnet, lower bid increment
        rtwrk_drawer_proxy_address=0x00a187db5eec1ef435b60ddab8afd2ec126e5c2682142c8d726989b09cc7b28d # rtwrk_drawer_address_value
        color=0x00a187db5eec1ef435b60ddab8afd2ec126e5c2682142c8d726989b09cc7b28d

        
        # Let's deploy the rtwrk auction contract with proxy pattern
        invoke(
            color,
            "colorizePixels",
            {  
                "pxlId": 1, 
                "pixel_colorizations":
                [{
                    "pixel_index":1,
                    "color_index": 23
                }],
            },
            config={
                "wait_for_acceptance": True,
                "max_fee": "auto",
            }
        )
    %}
    return ();
}

@external
func down() {
    %{ assert False, "Not implemented" %}
    return ();
}
