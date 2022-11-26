// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_tx_info,
    deploy,
)
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin, EcOpBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.account.library import Account, AccountCallArray

// /////////////////////////////////////////////////
// Events
// /////////////////////////////////////////////////

@event
func rental_contract_deployed(contract_address: felt, admin_address: felt) {
}

// /////////////////////////////////////////////////
// constructor / initializer
// /////////////////////////////////////////////////

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _owner: felt, _rental_class_hash: felt
) {
    Ownable.initializer(_owner);

    rental_class_hash.write(value=_rental_class_hash);
    salt.write(0);

    return ();
}

// /////////////////////////////////////////////////
// storage & structs
// /////////////////////////////////////////////////

@storage_var
func rental_class_hash() -> (value: felt) {
}

@storage_var
func salt() -> (value: felt) {
}

// /////////////////////////////////////////////////
// Getters
// /////////////////////////////////////////////////

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func getClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    value: felt
) {
    return rental_class_hash.read();
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}
// /////////////////////////////////////////////////
// Functions
// /////////////////////////////////////////////////

@external
func setClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _rental_class_hash: felt
) {
    rental_class_hash.write(value=_rental_class_hash);
    return ();
}

// ACCESS CONTROL WILL BE MODIFIED, ANYONE SHOULD BE ABLE TO CREATE A PLAYLIST
@external
func deployRentalContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    admin_address: felt, public_key : felt, token_addr : felt
) -> (contract_address : felt) {
    Ownable.assert_only_owner();
    let (current_salt) = salt.read();
    let (class_hash) = rental_class_hash.read();
    let (contract_address : felt) = deploy(
        class_hash=class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=3,
        constructor_calldata=cast(new (admin_address, public_key, token_addr), felt*),
        deploy_from_zero=FALSE,
    );
    salt.write(value=current_salt + 1);

    rental_contract_deployed.emit(contract_address=contract_address, admin_address=admin_address);
    return (contract_address=contract_address);
}
