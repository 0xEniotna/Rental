// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_tx_info
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_equal, assert_not_zero
from starkware.cairo.common.bool import TRUE, FALSE

from utils.library import (
    DEFAULT_ADMIN_ROLE,
    DEFAULT_RENTER_ROLE,
    IERC721_RECEIVER_ID,
    IACCESSCONTROL_ID,
)

from openzeppelin.access.accesscontrol.library import AccessControl
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.account.library import Account, AccountCallArray, Call, Account_public_key
// /////
// Vars
// /////

const ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
const RENTER_ROLE = DEFAULT_RENTER_ROLE;

const APPROVE_SELECTOR = 'approve';

// /////////////////////////////////////////////////
// Events
// /////////////////////////////////////////////////

@event
func TokenDeposit(nft_address: felt, nft_id: Uint256) {
}

@event
func TokenWithdrawal(nft_address: felt, nft_id: Uint256) {
}

// /////////////////////////////////////////////////
// constructor / initializer
// /////////////////////////////////////////////////

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, public_key: felt
) {
    ERC165.register_interface(IERC721_RECEIVER_ID);
    ERC165.register_interface(IACCESSCONTROL_ID);

    AccessControl.initializer();
    AccessControl._grant_role(ADMIN_ROLE, owner);

    Account.initializer(public_key);
    renter_account.write(public_key);
    is_listed.write(0);
    is_rented.write(0);
    return ();
}

// /////////////////////////////////////////////////
// storage & structs
// /////////////////////////////////////////////////

// by combining nft_amount and nft_list we can get our list of NFTs. A storage_var cant return a list directly
// for i=0 to i=nft_amount : get NFTs
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

// /////////////////////////////////////////////////
// Getters
// /////////////////////////////////////////////////

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return Account.supports_interface(interfaceId);
}

@view
func getPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    public_key: felt
) {
    let (publicKey: felt) = Account.get_public_key();
    return (public_key=publicKey);
}

@view
func getWhitelistedToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    token_address: felt
) {
    let (token_addr: felt) = whitelisted_token.read();
    return (token_address=token_addr);
}

@view
func isValidSignature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(hash: felt, signature_len: felt, signature: felt*) -> (isValid: felt) {
    alloc_locals;
    let (local public_key: felt) = Account_public_key.read();
    let (isValid: felt) = custom_is_valid_signature(public_key, hash, signature_len, signature);
    let (local public_key_renter: felt) = renter_account.read();
    let (isValidRenter: felt) = custom_is_valid_signature(
        public_key_renter, hash, signature_len, signature
    );
    // If sig is either admin or renter Then OK
    local res = (1 - isValid) * (1 - isValidRenter);
    local ans = FALSE;
    if (res == 0) {
        ans = TRUE;
    }
    return (isValid=ans);
}
// ////////////////////////////////////////////////
// Setters
// ////////////////////////////////////////////////

@external
func setPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newPublicKey: felt
) {
    Account.set_public_key(newPublicKey);
    return ();
}

// /////////////////////////////////////////////////
// Functions
// /////////////////////////////////////////////////

// / ACCOUNT ///

func custom_is_valid_signature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(_public_key: felt, hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
    // This interface expects a signature pointer and length to make
    // no assumption about signature validation schemes.
    // But this implementation does, and it expects a (sig_r, sig_s) pair.
    let sig_r = signature[0];
    let sig_s = signature[1];

    verify_ecdsa_signature(
        message=hash, public_key=_public_key, signature_r=sig_r, signature_s=sig_s
    );

    return (is_valid=TRUE);
}

// JUST A REMINDER
// struct Call {
//     to: felt,
//     selector: felt,
//     calldata_len: felt,
//     calldata: felt*,
// }

// struct AccountCallArray {
//     to: felt
//     selector: felt
//     data_offset: felt
//     data_len: felt
// }

func _validate_internal{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) {
    alloc_locals;

    if (call_array_len == 0) {
        let (tx_info) = get_tx_info();
        Account.is_valid_signature(
            tx_info.transaction_hash, tx_info.signature_len, tx_info.signature
        );
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;

        return ();
    }
    if (call_array[0].selector != APPROVE_SELECTOR) {
        let (local nft_addr: felt) = nft_address.read();
        with_attr error_message("Can't interact with nft contract") {
            assert_not_equal(call_array[0].to, nft_addr);
        }
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    _validate_internal(
        call_array_len - 1, call_array + AccountCallArray.SIZE, calldata_len, calldata
    );
    return ();
}

@external
func __validate__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr
}(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) {
    _validate_internal(call_array_len, call_array, calldata_len, calldata);
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

@external
func depositNft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nft_id: Uint256, nft_address: felt
) {
    uint256_check(nft_id);
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (this_address) = get_contract_address();
    let (caller: felt) = get_caller_address();
    let (token_owner: felt) = IERC721.ownerOf(contract_address=nft_address, tokenId=nft_id);
    with_attr error_message("ERC721: caller is not token owner") {
        assert caller = token_owner;
    }
    IERC721.transferFrom(
        contract_address=nft_address, from_=caller, to=this_address, tokenId=nft_id
    );
    TokenDeposit.emit(nft_address=nft_address, nft_id=nft_id);
    return ();
}

// / should check approval
@external
func withdrawNft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    nft_id: Uint256, nft_address: felt
) {
    uint256_check(nft_id);
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (this_address) = get_contract_address();
    let (caller: felt) = get_caller_address();
    let (token_owner: felt) = IERC721.ownerOf(contract_address=nft_address, tokenId=nft_id);
    with_attr error_message("ERC721: caller is not token owner") {
        assert this_address = token_owner;
    }
    IERC721.transferFrom(
        contract_address=nft_address, from_=this_address, to=caller, tokenId=nft_id
    );
    TokenWithdrawal.emit(nft_address=nft_address, nft_id=nft_id);
    return ();
}

@external
func createTokenSetListing{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    price: Uint256
) {
    uint256_check(price);
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (listed: felt) = is_listed.read();
    let (rented: felt) = is_rented.read();
    with_attr error_message("Already listed") {
        assert_not_equal(listed, 1);
    }
    with_attr error_message("Asset rented") {
        assert_not_equal(rented, 1);
    }
    _setRentalPrice(price);
    is_listed.write(TRUE);
    return ();
}

@external
func unlistTokenSet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (listed: felt) = is_listed.read();
    let (rented: felt) = is_rented.read();
    with_attr error_message("Not listed") {
        // check that it is listed
        assert_not_zero(listed);
    }
    with_attr error_message("Asset rented") {
        // check that it is not rented
        assert_not_equal(rented, 1);
    }
    is_listed.write(FALSE);
    _setRentalPrice(Uint256(0, 0));
    return ();
}

// prompt pubkey a la mano, not good but it is for a test purpose
@external
func rentTokenSet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    public_key: felt
) {
    let (listed: felt) = is_listed.read();
    let (rented: felt) = is_rented.read();
    with_attr error_message("Not listed") {
        // check that it is listed
        assert_not_zero(listed);
    }
    with_attr error_message("Asset rented") {
        // check that it is not rented
        assert_not_equal(rented, 1);
    }
    let (this_address: felt) = get_contract_address();
    let (caller: felt) = get_caller_address();
    let (price_to_pay: Uint256) = rental_price.read();
    let (token_addr: felt) = whitelisted_token.read();

    IERC20.transferFrom(
        contract_address=token_addr, sender=caller, recipient=this_address, amount=price_to_pay
    );
    is_listed.write(FALSE);
    is_rented.write(TRUE);
    renter_account.write(public_key);
    return ();
}

@external
func cancelRental{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    AccessControl.assert_only_role(ADMIN_ROLE);

    let (rented: felt) = is_rented.read();

    with_attr error_message("Asset not rented") {
        // check that it is not rented
        assert_not_zero(rented);
    }
    let (this_pubKey: felt) = getPublicKey();
    is_listed.write(FALSE);
    is_rented.write(FALSE);
    renter_account.write(this_pubKey);
    return ();
}

@external
func withdrawFunds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (this_address: felt) = get_contract_address();
    let (caller: felt) = get_caller_address();
    let (token_addr: felt) = whitelisted_token.read();
    // fetch balance
    let (balance: Uint256) = IERC20.balanceOf(contract_address=token_addr, account=this_address);
    // rugpull
    IERC20.transferFrom(
        contract_address=token_addr, sender=this_address, recipient=caller, amount=balance
    );
    return ();
}

func _setRentalPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_price: Uint256
) {
    rental_price.write(new_price);
    return ();
}

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, from_: felt, tokenId: Uint256, data_len: felt, data: felt*
) -> (selector: felt) {
    // we might want to configure this

    return (selector=IERC721_RECEIVER_ID);
}
