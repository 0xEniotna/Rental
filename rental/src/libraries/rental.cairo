// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_tx_info

from utils.library import DEFAULT_ADMIN_ROLE, DEFAULT_RENTER_ROLE, IERC721_RECEIVER_ID, IACCESSCONTROL_ID
from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.introspection.erc165.library import 
from openzeppelin.account.library import Account, AccountCallArray
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
    owner : felt
) {
    ERC165.register_interface(IERC721_RECEIVER_ID);
    ERC165.register_interface(IACCESSCONTROL_ID);

    AccessControl.initializer();
    AccessControl._grant_role(ADMIN_ROLE, owner);
    return()
}

###################################################
# storage & structs
###################################################

struct Nft {
    nft_address: felt,
    nft_id: felt
}

struct Subscription {
    sub_address : felt,
    duration : felt
}

@storage_var
func nft_list() -> (nfts : Nft*, nft_len : felt) {
}



###################################################
# Getters
###################################################

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

###################################################
# Functions
###################################################

#### ATTENTION ####
# IERC721 requires Uint256. A good conversion func has to be used before calling that function.

@external
func depositNft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nft_id : Uint256, nft_address : felt)
) {
    let (this_address) = get_contract_address();
    let (caller :felt) = get_caller_address()
    AccessControl.assert_only_role(ADMIN_ROLE)
    let (token_owner :felt) = IERC721.owner_of(contract_address=nft_address, tokenId = nft_id)
    with_attr error_message("ERC721: caller is not token owner") {
        assert caller =  token_owner
    }
    IERC721.transferFrom(contract_address=nft_address, caller, this_address, nft_id)  
    TokenDeposit.emit(current_balance=res, amount=amount);  
    return()
}

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        operator: felt, from_: felt, tokenId: Uint256, data_len: felt, data: felt*
    ) -> (selector: felt) {

    # we might want to configure this
    
    return (selector= IERC721_RECEIVER_ID)
}
