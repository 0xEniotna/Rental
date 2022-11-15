// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_check

from openzeppelin.account.library import Account, AccountCallArray, Call


@event
func TokenDeposit(nft_address: felt, nft_id: Uint256) {
}

@event
func TokenWithdrawal(nft_address: felt, nft_id: Uint256) {
}

@storage_var
func admin() -> (address: felt) {
}

@storage_var
func nft_list(id: felt) -> (res: (nft_address: felt, nft_id: felt)) {
}
@storage_var
func nft_amount() -> (nft_len: felt) {
}

@storage_var
func nft_address() -> (nft_address: felt) {
}

@storage_var
func rental_price() -> (price: Uint256) {
}

@storage_var
func is_listed() -> (ans: felt) {
}

@storage_var
func is_rented() -> (ans: felt) {
}

@storage_var
func renter_account() -> (public_key: felt) {
}

@storage_var
func whitelisted_token() -> (token_address: felt) {
}

@contract_interface
namespace IRental {

    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }

    func getPublicKey() -> (public_key: felt) {
    }

    func getRenterPubKey() -> (public_key: felt) {
    }

    func getAdmin() -> (admin_address : felt){
    }

    func isListed() -> (value : felt){
    }

    func getPriceToPay() -> (value : Uint256){
    }

    func isRented() -> (value : felt){
    }

    func getWhitelistedToken() -> (token_address: felt) {
    }

    func isValidSignature(hash: felt, signature_len: felt, signature: felt*) -> (isValid: felt) {
    }

    func setPublicKey(newPublicKey: felt) {
    }
    
    func setWhitelistedToken(token_address: felt) {
    }
    
    func __validate__(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) {
    }
    
    func __validate_declare__(cls_hash: felt) {
    }

    func __execute__(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) -> (response_len: felt, response: felt*) {
    }

    func depositNft(nft_id: Uint256, nft_address: felt) {
    }

    func withdrawNft(nft_id: Uint256, nft_address: felt) {
    }
    
    func createTokenSetListing(new_price: Uint256) {
    }

    func unlistTokenSet() {
    }

    func rentTokenSet(public_key: felt) {
    }

    func cancelRental() {
    }

    func withdrawFunds() {
    }

    func onERC721Received(operator: felt, from_: felt, tokenId: Uint256, data_len: felt, data: felt*) -> (selector: felt) {
    }

}
