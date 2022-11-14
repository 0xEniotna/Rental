%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_check

from src.interfaces.ITest_token import IERC20

@external
func __setup__() {
    %{
        context.owner = 1193046
        print("Deploy test erc20") 
        context.erc20_address = deploy_contract("./src/libraries/token.cairo", { "name": 1952805748, "symbol": 7631732, "decimals": 2, "initial_supply": {"low": 1000, "high": 0}, "recipient": 1193046, "owner": 1193046 }).contract_address
    %}
    return ();
}

@external
func test_total_supply_and_balance_of{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar contract_address;
    %{ ids.contract_address = context.erc20_address %}

    let (res) = IERC20.totalSupply(contract_address=contract_address);
    with_attr error_message("Total supply incorrect") {
        assert res.low = 1000;
        assert res.high = 0;
    }
    tempvar owner_address;
    %{ ids.owner_address = context.owner %}
    let (res2) = IERC20.balanceOf(contract_address=contract_address, account=owner_address);
    with_attr error_message("Total supply incorrect") {
        assert res2.low = 1000;
        assert res2.high = 0;
    }
    return ();
}
