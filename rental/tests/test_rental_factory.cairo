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
from starkware.cairo.common.uint256 import Uint256


from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.account.library import Account, AccountCallArray

from src.interfaces.IRental_factory import IRental_factory

@external
func __setup__() {
    %{
        context.owner = 1193046
        print("Deploy test factory") 
        # RENTAL
        class_hash_rental  = declare("./src/libraries/rental.cairo").class_hash
        print("rental class hash >>> " + str(class_hash_rental))
        context.class_hash_rental= class_hash_rental
        # FACTORY
        class_hash_factory  = declare("./src/libraries/rental_factory.cairo").class_hash
        print("Factory class hash >>> " + str(class_hash_factory))
        context.class_hash_factory= class_hash_factory
        
        context.factory_address = deploy_contract("./src/libraries/rental_factory.cairo", {"proxy_admin": 1193046, "_owner": 1193046, "_rental_class_hash": class_hash_rental}).contract_address
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
        ids.class_hash = context.class_hash_rental
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

// @external
// func test_contract_deployment{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     tempvar contract_address;
//     tempvar owner_address;
//     tempvar class_hash;

//     %{  
//         ids.contract_address = context.factory_address
//         ids.owner_address = context.owner
//         ids.class_hash = context.class_hash
//         stop_prank_callable = start_prank(context.owner)
//     %}
//     let (caller_addr : felt) = get_caller_address();
//     %{ 
//         print("Caller is " + str(ids.caller_addr))
//     %}
//     with_attr error_message("caller should be owner") {
//         assert caller_addr = owner_address;
//     }
//     %{ 
//         stop_prank_callable() 
//         stop_prank_callable = start_prank(context.owner, target_contract_address=ids.contract_address)
//         expect_events({"name": "rental_contract_deployed", "from_address": ids.contract_address})
//     %}

//     let (address : felt) = IRental_factory.deployRentalContract(contract_address=contract_address, admin_address=owner_address, public_key=123);
//     %{ 
//         stop_prank_callable()
//         print("address >>> " + str(ids.address))
//     %}

//     return ();
// }

@external
func test_user_balance{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar contract_address;
    tempvar owner_address;
    tempvar class_hash;

    %{  
        ids.contract_address = context.factory_address
        ids.owner_address = context.owner
        ids.class_hash = context.class_hash_rental
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
    let (balance : Uint256 ) = IRental_factory.getUserBalance(contract_address=contract_address, owner=owner_address);
    
    with_attr error_message("Balance should be 0") {
        assert balance.low = 0;
        assert balance.high = 0;     
    }
    
    let ( len : felt, rentalsOwned : felt*) = IRental_factory.rentalsOwned(contract_address=contract_address, owner=owner_address);
    
    with_attr error_message("Len should be 0") {
        assert len = 0;
    }
    
    let (address : felt) = IRental_factory.deployRentalContract(contract_address=contract_address, owner=owner_address, public_key=123, token_address=234567890);
    let (address2 : felt) = IRental_factory.deployRentalContract(contract_address=contract_address, owner=owner_address, public_key=123, token_address=23456789);
    
    %{ 
        stop_prank_callable()
        print("address >>> " + str(ids.address))
    %}
    
    let (balance : Uint256 ) = IRental_factory.getUserBalance(contract_address=contract_address, owner=owner_address);
    
    with_attr error_message("Balance should be 2") {
        assert balance.low = 2;
        assert balance.high = 0;
        
    }
    
    let ( len : felt, rentalsOwned : felt*) = IRental_factory.rentalsOwned(contract_address=contract_address, owner=owner_address);
    
    with_attr error_message("Len should be 2") {
        assert len = 2;
    }
    with_attr error_message("rentals[0] should be contract address") {
        assert address = rentalsOwned[0];
    }

    return ();
}

