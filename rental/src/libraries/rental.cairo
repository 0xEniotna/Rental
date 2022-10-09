%lang starknet

from openzeppelin.access.accesscontrol.library import AccessControl
from starkware.cairo.common.cairo_builtins import HashBuiltin
from utils.library import DEFAULT_OWNER_ROLE, DEFAULT_RENTER_ROLE

#
# Vars
# 

const OWNER_ROLE = DEFAULT_OWNER_ROLE
const RENTER_ROLE = DEFAULT_RENTER_ROLE


#
# constructor / initializer
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    felt : owner
) {
    AccessControl.initializer();
    AccessControl._grant_role(MINTER_ROLE, minter);
    return()
}

#
# storage & structs
# 

struct Nft {
    nft_address: felt,
    nft_id: felt
}
@storage_var
func nft_list() -> (nfts : Nft*, nft_len : felt) {
}

#
# Functions
# 

