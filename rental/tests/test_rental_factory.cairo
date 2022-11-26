%lang starknet

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_tx_info,
    deploy,
)
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.account.library import Account, AccountCallArray

from src.interfaces.IRental_factory import IRental_factory

from protostar.asserts import (
    assert_eq,
    assert_not_eq,
    assert_signed_lt,
    assert_signed_le,
    assert_signed_gt,
    assert_unsigned_lt,
    assert_unsigned_le,
    assert_unsigned_gt,
    assert_signed_ge,
    assert_unsigned_ge,
)


@external
func __setup__() {
    %{
        context.owner = 1193046
        print("Deploy test factory") 
        class_hash  = declare("./src/libraries/rental.cairo").class_hash
        print("class hash >>> " + str(class_hash))
        context.class_hash= class_hash
        context.factory_address = deploy_contract("./src/libraries/rental_factory.cairo", { "_owner": 1193046, "_rental_class_hash": class_hash}).contract_address
        print("factory address >>> " + str(context.factory_address))
    %}
    return ();
}

@external
func test_initialization_and_rental_class_hash{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar contract_address;
    tempvar owner_address;
    tempvar class_hash;

    %{ 
        ids.contract_address = context.factory_address
        ids.owner_address = context.owner
        ids.class_hash = context.class_hash
    %}

    let (res) = IRental_factory.owner(contract_address=contract_address);
    with_attr error_message("Owner is not configured or is not correct") {
        assert res = owner_address;
    }
    %{ 
        print("Owner is " + str(ids.res))
    %}
    let (res2) = IRental_factory.getClassHash(contract_address=contract_address);
    with_attr error_message("Wrong class hash") {
        assert res2 = class_hash;
    }
    return ();
}

@external
func test_contract_deployment{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar contract_address;
    tempvar owner_address;
    tempvar class_hash;

    %{  
        ids.contract_address = context.factory_address
        ids.owner_address = context.owner
        ids.class_hash = context.class_hash
        stop_prank_callable = start_prank(context.owner)
    %}
    let (caller_addr : felt) = get_caller_address();
    %{ 
        print("Caller is " + str(ids.caller_addr))
    %}
    with_attr error_message("caller should be owner") {
        assert caller_addr = owner_address;
    }
    %{ 
        stop_prank_callable() 
        stop_prank_callable = start_prank(context.owner, target_contract_address=ids.contract_address)
        expect_events({"name": "rental_contract_deployed", "from_address": ids.contract_address})
    %}

    let (address : felt) = IRental_factory.deployRentalContract(contract_address=contract_address, admin_address=owner_address, public_key=123);
    %{ 
        stop_prank_callable()
        print("address >>> " + str(ids.address))
    %}

    return ();
}
