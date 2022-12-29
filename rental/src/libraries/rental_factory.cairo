// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_tx_info,
    deploy,
)
from starkware.starknet.core.os.contract_address.contract_address import get_contract_address as gca
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin, EcOpBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_eq, uint256_lt

from openzeppelin.security.safemath.library import SafeUint256
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

// Amount of rentals contract owned by address
@storage_var
func user_balance(address: felt) -> (amount: Uint256) {
}

@storage_var
func rentals_owned(owner: felt, index: Uint256) -> (address: felt) {
}

@storage_var
func rentals_owned_index(address: felt) -> (index: Uint256) {
}

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

func rentals_of_owner_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, index: Uint256
    ) -> (address: felt) {
        alloc_locals;
        uint256_check(index);
        // Ensures index argument is less than owner's balance
        let (len: Uint256) = user_balance.read(owner);
        let (is_lt) = uint256_lt(index, len);
        with_attr error_message("Factory: owner index out of bounds") {
            assert is_lt = TRUE;
        }

        return rentals_owned.read(owner, index);
}

func get_all_rentals_owned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, index: Uint256, balance: Uint256, rentals: felt*
) -> () {
    let (res: felt) = uint256_eq(index, balance);
    if (res == 1) {
        return ();
    }
    let (rental_address: felt) = rentals_of_owner_by_index(
        owner=owner, index=index
    );
    assert rentals[index.low] = rental_address;
    let (next_index : Uint256) = SafeUint256.add(index, Uint256(1, 0));
    return get_all_rentals_owned(owner, next_index, balance, rentals);
}

@view
func rentalsOwned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    rentals_len: felt, rentals: felt*
) {
    alloc_locals;
    let (rentals: felt*) = alloc();
    let (balance: Uint256) = user_balance.read(owner);
    get_all_rentals_owned(owner, Uint256(0,0), balance, rentals);
    return (rentals_len=balance.low, rentals=rentals);
}

@view
func getUserBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    value: Uint256
) {
    let (balance: Uint256) = user_balance.read(owner);
    return (value=balance);
}

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
    let (this_address) = get_contract_address();
    let (caller: felt) = get_caller_address();
    let (current_salt : felt) = salt.read();
    let (rental_hash : felt) = rental_class_hash.read();

    // gca is get_contract_address which is a function that computes a contract address from the parameters.
    // it is different from the other get_contract_address which is a syscall that retrieve the actual contrcat address.
    let (contract_address : felt) = gca{hash_ptr=pedersen_ptr}(current_salt, rental_hash, 3, cast(new (owner,public_key,token_address), felt*), this_address);
    // Rental constructor data is (this is proxy calldata)
    // owner: felt, public_key: felt, token_address : felt
    let (_addr : felt) = deploy(
        class_hash=rental_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=3,
        constructor_calldata=cast(new (owner,public_key,token_address), felt*),
        deploy_from_zero=FALSE,
    );
    
    // Increase receiver balance
    _add_token_to_owner_enumeration(caller, contract_address);
    
    rental_contract_deployed.emit(contract_address=contract_address);
    salt.write(value=current_salt + 1);
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

func _add_token_to_owner_enumeration{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(to: felt, address: felt) {

    let (length: Uint256) = user_balance.read(to);
    rentals_owned.write(to, length, address);
    rentals_owned_index.write(address, length);
    let (new_balance: Uint256) = SafeUint256.add(length, Uint256(1, 0));
    user_balance.write(to, new_balance);
    return ();
}

func _remove_token_from_owner_enumeration{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(from_: felt, address: felt) {
    alloc_locals;

    let (last_token_index: Uint256) = user_balance.read(from_);
    // the index starts at zero therefore the user's last token index is their balance minus one
    let (last_token_index) = SafeUint256.sub_le(last_token_index, Uint256(1, 0));
    let (token_index: Uint256) = rentals_owned_index.read(address);

    // If index is last, we can just set the return values to zero
    let (is_equal) = uint256_eq(token_index, last_token_index);
    if (is_equal == TRUE) {
        rentals_owned_index.write(address, Uint256(0, 0));
        rentals_owned.write(from_, last_token_index, 0);
        return ();
    }

    // If index is not last, reposition owner's last token to the removed token's index
    let (last_address: felt) = rentals_owned.read(from_, last_token_index);
    rentals_owned.write(from_, token_index, last_address);
    rentals_owned_index.write(last_address, token_index);
    return ();
}