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

from openzeppelin.upgrades.library import Proxy


// /////////////////////////////////////////////////
// Events
// /////////////////////////////////////////////////

@event
func rental_contract_deployed(contract_address: felt) {
}

// /////////////////////////////////////////////////
// constructor / initializer
// /////////////////////////////////////////////////

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt, _owner: felt, _rental_class_hash: felt
) {
    Proxy.initializer(proxy_admin);

    Ownable.initializer(_owner);

    rental_class_hash.write(value=_rental_class_hash);
    salt.write(0);

    return ();
}

// /////////////////////////////////////////////////
// storage & structs
// /////////////////////////////////////////////////

const INITIALIZER_SELECTOR = 1295919550572838631247819983596733806859788957403169325509326258146877103642;

@storage_var
func rental_class_hash() -> (value: felt) {
}

@storage_var
func proxy_class_hash() -> (value: felt) {
}

@storage_var
func salt() -> (value: felt) {
}

struct Calldata {
    proxy_admin: felt,
    owner: felt,
    public_key: felt,
    token_address: felt,
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
func getProxyHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    value: felt
) {
    return proxy_class_hash.read();
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

// ACCESS CONTROL WILL BE MODIFIED

@external
func deployRentalContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, public_key: felt, token_address : felt
) -> (contract_address : felt) {
    alloc_locals;
    Ownable.assert_only_owner();
    let (current_salt : felt) = salt.read();
    let (rental_hash : felt) = rental_class_hash.read();

    // Rental constructor data is (this is proxy calldata)
    // owner: felt, public_key: felt, token_address : felt
    let (contract_address : felt) = deploy(
        class_hash=rental_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=3,
        constructor_calldata=cast(new (owner,public_key,token_address), felt*),
        deploy_from_zero=FALSE,
    );
    
    salt.write(value=current_salt + 1);

    rental_contract_deployed.emit(contract_address=contract_address);
    return (contract_address=contract_address);
}


// Proxy upgrade

@external
func upgradeImplementation{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

@external
func setProxyAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) {
    Proxy.assert_only_admin();
    Proxy._set_admin(address);
    return ();
}