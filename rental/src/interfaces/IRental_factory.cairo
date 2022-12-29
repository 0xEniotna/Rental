// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256


@event
func rental_contract_deployed(contract_address: felt, admin_address: felt) {
}

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

@contract_interface
namespace IRental_factory {

    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }

    func getClassHash() -> (value: felt) {
    }

    func owner() -> (owner: felt) {
    }

    func deployRentalContract(owner: felt, public_key: felt, token_address : felt) -> (contract_address : felt){
    }
    
    func rentalsOwned(owner: felt) -> (rentals_len: felt, rentals: felt*){
    }
    
    func getUserBalance(owner: felt) -> (value: Uint256){
    }
    
    func upgradeImplementation(new_implementation: felt) {
    }

    func setProxyAdmin(address: felt) {
    }

}
