// SPDX-License-Identifier: MIT

%lang starknet

@event
func rental_contract_deployed(contract_address: felt, admin_address: felt) {
}

@storage_var
func rental_class_hash() -> (value: felt) {
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

    func deployRentalContract(admin_address: felt, public_key : felt) -> (contract_address : felt){
    }

}
