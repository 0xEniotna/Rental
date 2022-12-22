// SPDX-License-Identifier: MIT

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_tx_info
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.cairo.common.signature import verify_ecdsa_signature, check_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin, EcOpBuiltin
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
from openzeppelin.upgrades.library import Proxy

// /////
// Vars
// /////

const ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
const RENTER_ROLE = DEFAULT_RENTER_ROLE;

const APPROVE_SELECTOR = 949021990203918389843157787496164629863144228991510976554585288817234167820;
const ETH_ADDRESS = 2087021424722619777119509474943472645767659996348769578120564519014510906823;
const SEQUENCER_ADDRESS = 1997487415181885029773256152896365819837996792307295206244238286899607166571;

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
    owner: felt, public_key: felt, token_address : felt
) {

    ERC165.register_interface(IERC721_RECEIVER_ID);
    ERC165.register_interface(IACCESSCONTROL_ID);

    AccessControl.initializer();
    AccessControl._grant_role(ADMIN_ROLE, owner);
    admin.write(owner);

    Account.initializer(public_key);
    renter_account.write(public_key);
    is_listed.write(0);
    is_rented.write(0);
    whitelisted_token.write(token_address);
    rental_price.write(Uint256(0, 0));

    return ();
}
// /////////////////////////////////////////////////
// storage & structs
// /////////////////////////////////////////////////

// by combining nft_amount and nft_list we can get our list of NFTs. A storage_var cant return a list directly
// for i=0 to i=nft_amount : get NFTs
@storage_var
func admin() -> (address: felt) {
}

// @storage_var
// func nft_list(id: felt) -> (res: (nft_address: felt, nft_id: felt)) {
// }

// @storage_var
// func nft_amount() -> (nft_len: felt) {
// }

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
func getAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    admin_address : felt 
) {
    let (res: felt) = admin.read();
    return (admin_address=res);
}

@view
func getPublicKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    public_key: felt
) {
    let (publicKey: felt) = Account.get_public_key();
    return (public_key=publicKey);
}

@view
func getRenterPubKey{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    public_key: felt
) {
    let (publicKey: felt) = renter_account.read();
    return (public_key=publicKey);
}

@view
func isListed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    value: felt
) {
    let (res: felt) = is_listed.read();
    return (value=res);
}

@view
func getPriceToPay{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    value: Uint256
) {
    let (res: Uint256) = rental_price.read();
    return (value=res);
}

@view
func isRented{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    value: felt
) {
    let (res: felt) = is_rented.read();
    return (value=res);
}

@view
func getWhitelistedToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    token_address: felt
) {
    let (token_addr: felt) = whitelisted_token.read();
    return (token_address=token_addr);
}

@view
func getNftAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    token_address: felt
) {
    let (token_addr: felt) = nft_address.read();
    return (token_address=token_addr);
}

@view
func isValidSignature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr, ec_op_ptr: EcOpBuiltin*
}(hash: felt, signature_len: felt, signature: felt*) -> (isValid: felt) {
    let (is_valid: felt) = custom_is_valid_signature(hash, signature_len, signature);
    // If sig is either admin or renter Then OK
    return (isValid=is_valid);
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

@external
func setWhitelistedToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_address: felt
) {
    whitelisted_token.write(token_address);
    return ();
}

// /////////////////////////////////////////////////
// Functions
// /////////////////////////////////////////////////

// / ACCOUNT ///

func custom_is_valid_signature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr, ec_op_ptr: EcOpBuiltin*
}(hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
    // This interface expects a signature pointer and length to make
    // no assumption about signature validation schemes.
    // But this implementation does, and it expects a (sig_r, sig_s) pair.
    alloc_locals;

    let sig_r = signature[0];
    let sig_s = signature[1];

    let (local public_key: felt) = Account_public_key.read();
    let (local public_key_renter: felt) = renter_account.read();
    
    let (is_valid_owner: felt) = check_ecdsa_signature(
        message=hash, public_key=public_key, signature_r=sig_r, signature_s=sig_s
    );
    let (is_valid_renter: felt) = check_ecdsa_signature(
        message=hash, public_key=public_key_renter, signature_r=sig_r, signature_s=sig_s
    );

    // If sig is either admin or renter Then OK

    local ans = (1 - is_valid_owner) * (1 - is_valid_renter);
    if (ans == 0) {
        return(is_valid=TRUE);
    }
    return (is_valid=FALSE);
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

// ATTENTION, RENTER CAN WITHDRAW ETH. SHOULD BE MODIFIED LATTER
// THIS FUNCTION IS TOOOOOOOO COMPLEX
// IMPORVMENTS NEED TO BE MADE. SUPER IMPORTANT

// We go through call_array, typical cairo recursion
// If we are interacting with ETH, ONLY ACCEPT THE FEES, ELSE BREAK
// IF we are interacting with NFT contract, THEN
//          IF The selector is Approve AND the spender is admin THEN OK (so that no other contract can rug the admin)
            // ELSE BREAK
// ELSE VALIDATE

func _validate_internal{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr, ec_op_ptr: EcOpBuiltin*
}(call_array_len: felt, call_array: AccountCallArray*, calldata_len: felt, calldata: felt*) {
    alloc_locals;

    if (call_array_len == 0) {
        let (tx_info) = get_tx_info();
        let (res : felt) = custom_is_valid_signature(
            tx_info.transaction_hash, tx_info.signature_len, tx_info.signature
        );
        with_attr error_message("Signature not valid") {
            assert_not_zero(res);
        }
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar ecdsa_ptr: SignatureBuiltin* = ecdsa_ptr;
        tempvar ec_op_ptr = ec_op_ptr;
        return ();
    }
    if (call_array[0].to == ETH_ADDRESS) {
        if (calldata[0] == SEQUENCER_ADDRESS){
            _validate_internal(
                call_array_len - 1, call_array + AccountCallArray.SIZE, calldata_len, calldata
            );
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar ec_op_ptr = ec_op_ptr;
            tempvar ecdsa_ptr: SignatureBuiltin* = ecdsa_ptr;
        } else {
            // BREAK
            with_attr error_message("Transaction not accepted, ETH receiver isn't sequencer") {
                assert 0 = 1;
            }
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar ec_op_ptr = ec_op_ptr;
            tempvar ecdsa_ptr: SignatureBuiltin* = ecdsa_ptr;
        }
        
    } else {
        let (nft_addr : felt) = nft_address.read();
        if (call_array[0].to == nft_addr) {
            if (call_array[0].selector == APPROVE_SELECTOR) {
                let (admin_addr : felt) = admin.read();
                if (calldata[0] == admin_addr) {
                    _validate_internal(
                        call_array_len - 1, call_array + AccountCallArray.SIZE, calldata_len, calldata
                    );
                    tempvar syscall_ptr: felt* = syscall_ptr;
                    tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                    tempvar ec_op_ptr = ec_op_ptr;
                    tempvar ecdsa_ptr: SignatureBuiltin* = ecdsa_ptr;
                } else {
                    // BREAK
                    with_attr error_message("Transaction not accepted, spender is not admin") {
                        assert 0 = 1;
                    }
                    tempvar syscall_ptr: felt* = syscall_ptr;
                    tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                    tempvar ec_op_ptr = ec_op_ptr;
                    tempvar ecdsa_ptr: SignatureBuiltin* = ecdsa_ptr;
                }
            } else {
                // BREAK
                with_attr error_message("Transaction not accepted, can't interact with nft contract") {
                    assert 0 = 1;
                }
                tempvar syscall_ptr: felt* = syscall_ptr;
                tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
                tempvar ec_op_ptr = ec_op_ptr;
                tempvar ecdsa_ptr: SignatureBuiltin* = ecdsa_ptr;
            }
        } else {
            _validate_internal(
                call_array_len - 1, call_array + AccountCallArray.SIZE, calldata_len, calldata
            );
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar ec_op_ptr = ec_op_ptr;
            tempvar ecdsa_ptr: SignatureBuiltin* = ecdsa_ptr;
        }
    }
    return ();
}

@external
func __validate__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*, range_check_ptr, ec_op_ptr: EcOpBuiltin*
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
    nft_id: Uint256, _nft_address: felt
) {
    uint256_check(nft_id);
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (this_address) = get_contract_address();
    let (caller: felt) = get_caller_address();
    // IERC721.approve(
    //     contract_address=_nft_address, spender=this_address, tokenId=nft_id
    // );
    IERC721.transferFrom(
        contract_address=_nft_address, from_=caller, to=this_address, tokenId=nft_id
    );
    nft_address.write(_nft_address);
    TokenDeposit.emit(nft_address=_nft_address, nft_id=nft_id);
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
    new_price: Uint256
) {
    uint256_check(new_price);
    AccessControl.assert_only_role(ADMIN_ROLE);
    let (listed: felt) = is_listed.read();
    let (rented: felt) = is_rented.read();
    with_attr error_message("Already listed") {
        assert_not_equal(listed, 1);
    }
    with_attr error_message("Asset rented") {
        assert_not_equal(rented, 1);
    }
    rental_price.write(new_price);
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
    rental_price.write(Uint256(0, 0));
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
    IERC20.transfer(
        contract_address=token_addr, recipient=caller, amount=balance
    );
    return ();
}

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, from_: felt, tokenId: Uint256, data_len: felt, data: felt*
) -> (selector: felt) {
    // we might want to configure this

    return (selector=IERC721_RECEIVER_ID);
}

