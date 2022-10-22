// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_tx_info
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_equal, assert_not_zero

from utils.library import DEFAULT_ADMIN_ROLE, DEFAULT_RENTER_ROLE, IERC721_RECEIVER_ID, IACCESSCONTROL_ID

from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.account.library import Account
#
# Vars
# 

const ADMIN_ROLE = DEFAULT_ADMIN_ROLE
const RENTER_ROLE = DEFAULT_RENTER_ROLE

###################################################
# Events
###################################################

@event
func TokenDeposit(nft_address : felt, nft_id : Uint256) {
}

@event
func TokenWithdrawal(nft_address : felt, nft_id : Uint256) {
}

@event
func NewSubscription(sub_address : felt, duration : felt) {
}

###################################################
# constructor / initializer
###################################################

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, public_key: felt
) {
    ERC165.register_interface(IERC721_RECEIVER_ID);
    ERC165.register_interface(IACCESSCONTROL_ID);

    AccessControl.initializer();
    AccessControl._grant_role(ADMIN_ROLE, owner);

    Account.initializer(public_key);

    is_listed.write(0);
    is_rented.write(0);
    return()
}

###################################################
# storage & structs
###################################################

struct Nft {
    nft_address: felt,
    nft_id: felt
}

struct Listing {
    price: felt
}


@storage_var
func nft_list() -> (nfts : Nft*, nft_len : felt) {
}

@storage_var
func rental_price() -> (price : felt) {
}

@storage_var
func is_listed() -> (ans : felt) {
}

@storage_var
func is_rented() -> (ans : felt) {
}



###################################################
# Getters
###################################################

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return Account.supports_interface(interfaceId);
}

@view
func getPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    publicKey: felt
) {
    let (publicKey: felt) = Account.get_public_key();
    return (publicKey=publicKey);
}

###################################################
# Setters
###################################################

@external
func setPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newPublicKey: felt
) {
    Account.set_public_key(newPublicKey);
    return ();
}

###################################################
# Functions
###################################################

### ACCOUNT ###

@view
func isValidSignature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(hash: felt, signature_len: felt, signature: felt*) -> (isValid: felt) {
    let (isValid: felt) = Account.is_valid_signature(hash, signature_len, signature);
    return (isValid=isValid);
}

@external
func __validate__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) {
    let (tx_info) = get_tx_info();
    Account.is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    return ();
}

@external
func __validate_declare__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(class_hash: felt) {
    let (tx_info) = get_tx_info();
    Account.is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature);
    return ();
}

@external
func __execute__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
    range_check_ptr,
}(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) -> (
    response_len: felt, response: felt*
) {
    let (response_len, response) = Account.execute(
        call_array_len, call_array, calldata_len, calldata
    );
    return (response_len, response);
}


#### ATTENTION ####
# IERC721 requires Uint256. A good conversion func has to be used before calling that function.

@external
func depositNft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nft_id : Uint256, nft_address : felt)
) {
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (this_address) = get_contract_address();
    let (caller :felt) = get_caller_address();
    let (token_owner :felt) = IERC721.owner_of(contract_address=nft_address, tokenId = nft_id);
    with_attr error_message("ERC721: caller is not token owner") {
        assert caller =  token_owner
    }
    IERC721.transferFrom(contract_address=nft_address, caller, this_address, nft_id)  
    TokenDeposit.emit(nft_address=nft_address, nft_id=nft_id);  
    return()
}


### should check approval
@external
func withdrawNft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nft_id : Uint256, nft_address : felt)
) {
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (this_address) = get_contract_address();
    let (caller :felt) = get_caller_address();
    let (token_owner :felt) = IERC721.owner_of(contract_address=nft_address, tokenId = nft_id);
    with_attr error_message("ERC721: caller is not token owner") {
        assert this_address =  token_owner
    }
    IERC721.transferFrom(contract_address=nft_address, this_address, caller, nft_id)  
    TokenWithdrawal.emit(nft_address=nft_address, nft_id=nft_id);   
    return()
}

@external
func createTokenSetListing{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    price : felt
) {
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (listed : felt) = is_listed.read()
    let (rented : felt) = is_rented.read()
    with_attr error_message("Already listed") {
        assert_not_equal(listed, 1);
    }
    with_attr error_message("Already rented") {
        assert_not_equal(rented, 1);
    }
    _setRentalPrice(price);
    is_listed.write(1);
    return()
}

@external
func unlistTokenSet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (listed : felt) = is_listed.read()
    let (rented : felt) = is_rented.read()
    with_attr error_message("Not listed") {
        assert_not_zero(listed);
    }
    with_attr error_message("Not rented") {
        assert_not_zero(rented);
    }
    is_listed.write(0);
    _setRentalPrice(0);
    return()
}

@external
func rentTokenSet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (listed : felt) = is_listed.read()
    let (rented : felt) = is_rented.read()
    with_attr error_message("Not listed") {
        assert_not_zero(listed);
    }
    with_attr error_message("Not rented") {
        assert_not_zero(rented);
    }
    is_listed.write(0);
    _setRentalPrice(0);
    return()
}

func _setRentalPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_price : felt
) {
    rental_price.write(new_price);
    return()
}



@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        operator: felt, from_: felt, tokenId: Uint256, data_len: felt, data: felt*
    ) -> (selector: felt) {

    # we might want to configure this
    
    return (selector= IERC721_RECEIVER_ID)
}
