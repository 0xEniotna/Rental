%lang starknet

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_tx_info,
    deploy,
)

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_check

from src.interfaces.IRental import IRental
from src.interfaces.INFT_contract import INFT_contract
from src.interfaces.ITest_token import IERC20


from protostar.asserts import (
    assert_eq,
    assert_not_eq,
    assert_signed_lt,
    assert_signed_le,
    assert_signed_gt,
    assert_unsigned_lt,
    assert_unsigned_le,
    assert_unsigned_gt,
    assert_signed_ge,
    assert_unsigned_ge,
)


@external
func __setup__() {
    %{
        context.owner = 1266358246091241006754730822548716186777513181751750203897062157238022205850
        context.renter = 1083931606303149357723215688111620967982665379743418814880297521363082835333
        context.public_key = 2775954746159100240394835917573393993756840506754192982217539669037606939924
        context.renter_pubKey = 958151819035831656979943818277157281501666943699661247016564235167534340803

        print("Deploy Contract") 
        context.erc20_address = deploy_contract("./src/libraries/token.cairo", { "name": 1952805748, "symbol": 7631732, "decimals": 2, "initial_supply": {"low": 100000, "high": 0}, "recipient": context.renter, "owner": context.owner }).contract_address

        context.rental_address = deploy_contract("./src/libraries/rental.cairo", { "owner": context.owner, "public_key": context.public_key, "token_address": context.erc20_address}).contract_address
        print("rental address >>> " + str(context.rental_address))
        context.nft_address = deploy_contract("./src/libraries/nft_contract.cairo", { "name": 7235188, "symbol": 7235188, "owner": context.owner}).contract_address
    %}
    return ();
}

// @external
// func test_initialization{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     tempvar contract_address;
//     tempvar owner_address;
//     tempvar public_key;

//     %{ 
//         ids.contract_address = context.rental_address
//         ids.owner_address = context.owner
//         ids.public_key = context.public_key
//     %}

//     let (res) = IRental.getAdmin(contract_address=contract_address);
//     with_attr error_message("Admin is not configured or is incorrect") {
//         assert res = owner_address;
//     }
//     %{ 
//         print("Owner is " + str(ids.res))
//     %}

//     let (res2) = IRental.isListed(contract_address=contract_address);
//     with_attr error_message("Should not be any listing") {
//         assert res2 = FALSE;
//     }

//     let (res3) = IRental.isRented(contract_address=contract_address);
//     with_attr error_message("Should not be rented") {
//         assert res3 = FALSE;
//     }

//     let (res4) = IRental.getPublicKey(contract_address=contract_address);
//     with_attr error_message("public_key is not configured or is incorrect") {
//         assert res4 = public_key;
//     }
//     return ();
// }

// @external
// func setup_deposit_withdraw_nft{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     tempvar nft_address;
//     tempvar owner_address;

//     %{
//         stop_prank_callable = start_prank(context.owner, target_contract_address=context.nft_address)
//         ids.nft_address = context.nft_address
//         ids.owner_address = context.owner
//     %}
//     INFT_contract.mint(contract_address=nft_address, to=owner_address, tokenId=Uint256(1,0));
//     let (balance : Uint256 ) = INFT_contract.balanceOf(contract_address=nft_address, owner=owner_address);
//     assert balance.low = 1;
//     assert balance.high = 0;

//      %{
//         stop_prank_callable()
//     %}
//     return ();
// }

// @external
// func test_deposit_withdraw_nft{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     tempvar rental_address;
//     tempvar owner_address;
//     tempvar nft_address;

//     %{  
//         ids.rental_address = context.rental_address
//         ids.owner_address = context.owner
//         ids.nft_address = context.nft_address
//         expect_events({"name": "TokenDeposit", "from_address": ids.rental_address})
//         stop_prank_callable = start_prank(context.owner, target_contract_address=context.nft_address)
//     %}
//     INFT_contract.approve(contract_address=nft_address, to=rental_address, tokenId= Uint256(1,0));
//     %{ stop_prank_callable() %}
//     %{ stop_prank_callable = start_prank(context.owner, target_contract_address=context.rental_address) %}
//     IRental.depositNft(contract_address=rental_address, nft_id= Uint256(1,0), nft_address= nft_address);
//     %{ stop_prank_callable() %}

//     // DEPOSIT
//     let (balance : Uint256 ) = INFT_contract.balanceOf(contract_address=nft_address, owner=owner_address);
//     with_attr error_message("Owner balance should be 0 after deposit") {
//         assert balance.low = 0;
//         assert balance.high = 0;
//     }
//     let (balance2 : Uint256 ) = INFT_contract.balanceOf(contract_address=nft_address, owner=rental_address);
//     with_attr error_message("Rental contract balance should be 1 after deposit") {
//         assert balance2.low = 1;
//         assert balance2.high = 0;
//     }

//     // WITHDRAW
//     %{ stop_prank_callable = start_prank(context.rental_address, target_contract_address=context.nft_address) %}

//     INFT_contract.approve(contract_address=nft_address, to=owner_address, tokenId= Uint256(1,0));
//     %{ stop_prank_callable() %}
//     %{ stop_prank_callable = start_prank(context.owner, target_contract_address=context.rental_address) %}
//     IRental.withdrawNft(contract_address=rental_address, nft_id= Uint256(1,0), nft_address= nft_address);
//     %{ stop_prank_callable() %}

//     let (balance3 : Uint256 ) = INFT_contract.balanceOf(contract_address=nft_address, owner=owner_address);
//     with_attr error_message("Owner balance should be 1 after withdrawal") {
//         assert balance3.low = 1;
//         assert balance3.high = 0;
//     }
//     let (balance4 : Uint256 ) = INFT_contract.balanceOf(contract_address=nft_address, owner=rental_address);
//     with_attr error_message("Rental contract balance should be 0 after withdrawal") {
//         assert balance4.low = 0;
//         assert balance4.high = 0;
//     }

//     return ();
// }

// @external
// func setup_listing_unlisting{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     tempvar nft_address;
//     tempvar owner_address;
//     tempvar rental_address;

//     %{
//         stop_prank_callable = start_prank(context.owner, target_contract_address=context.nft_address)
//         ids.nft_address = context.nft_address
//         ids.owner_address = context.owner
//         ids.rental_address = context.rental_address
//     %}
//     INFT_contract.mint(contract_address=nft_address, to=rental_address, tokenId=Uint256(1,0));
//     let (balance : Uint256 ) = INFT_contract.balanceOf(contract_address=nft_address, owner=rental_address);
//     assert balance.low = 1;
//     assert balance.high = 0;

//      %{
//         stop_prank_callable()
//     %}
//     return ();
// }

// @external
// func test_listing_unlisting{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     tempvar rental_address;
//     tempvar owner_address;
//     tempvar nft_address;

//     %{  
//         ids.rental_address = context.rental_address
//         ids.owner_address = context.owner
//         ids.nft_address = context.nft_address
//         stop_prank_callable = start_prank(context.owner, target_contract_address=context.rental_address)
//     %}
//     let (listed) = IRental.isListed(contract_address=rental_address);
//     with_attr error_message("NFT should not be listed before listing") {
//         assert listed = 0;
//     }

//     let (price) = IRental.getPriceToPay(contract_address=rental_address);
//     with_attr error_message("Price should be 0 before listing") {
//         assert price.low = 0;
//         assert price.high = 0;
//     }

//     IRental.createTokenSetListing(contract_address=rental_address, new_price= Uint256(10,0) );
//     %{ stop_prank_callable() %}
    
//     let (listed2) = IRental.isListed(contract_address=rental_address);
//     with_attr error_message("NFT should be listed") {
//         assert listed2 = 1;
//     }
//     let (price1 : Uint256) = IRental.getPriceToPay(contract_address=rental_address);
    
    
//     with_attr error_message("Price should be 10 after listing") {
//         assert price1.low = 10;
//         assert price1.high = 00;
//     }

//     return ();
// }

// @external
// func setup_rent_cancel_rugpull{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     tempvar rental_address;
//     tempvar owner_address;
//     tempvar renter_address;
//     tempvar nft_address;
//     tempvar erc20_address;

//     %{  
//         ids.rental_address = context.rental_address
//         ids.owner_address = context.owner
//         ids.renter_address = context.renter
//         ids.nft_address = context.nft_address
//         ids.erc20_address = context.erc20_address
//     %}
//     // CHECK ERC20 BALANCE
//     let (initial_balance_renter) = IERC20.balanceOf(contract_address=erc20_address, account=renter_address);
//     with_attr error_message("Balance is incorrect, should be 100000 tokens") {
//         assert initial_balance_renter.low = 100000;
//         assert initial_balance_renter.high = 0;
//     }
//     // CHECK NFT BALANCE
//     %{  
//         stop_prank_callable = start_prank(context.owner, target_contract_address=context.nft_address)
//     %}
//     INFT_contract.mint(contract_address=nft_address, to=owner_address, tokenId=Uint256(1,0));
//     let (check_nft_minting) = INFT_contract.balanceOf(contract_address=nft_address, owner=owner_address);
//     with_attr error_message("Balance is incorrect, should be 1 nft") {
//         assert check_nft_minting.low = 1;
//         assert check_nft_minting.high = 0;
//     }
//     INFT_contract.approve(contract_address=nft_address, to=rental_address, tokenId=Uint256(1,0));

//     %{ stop_prank_callable() %}
//     // PERFORM LISTING (we dont do assert as the feature is checked by the previous test)
//     // ALSO WHITELIST TOKEN
//     %{  
//         stop_prank_callable = start_prank(context.owner, target_contract_address=context.rental_address)
//     %}
//     IRental.depositNft(contract_address=rental_address, nft_id= Uint256(1,0), nft_address= nft_address);
//     IRental.createTokenSetListing(contract_address=rental_address, new_price= Uint256(1000,0) );
//     %{ stop_prank_callable() %}

//     return ();
// }

// @external
// func test_rent_cancel_rugpull{
//     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// }() {
//     tempvar rental_address;
//     tempvar owner_address;
//     tempvar renter_address;
//     tempvar nft_address;
//     tempvar erc20_address;
//     tempvar public_key;
//     tempvar renter_pubKey;

//     %{  
//         ids.rental_address = context.rental_address
//         ids.owner_address = context.owner
//         ids.renter_address = context.renter
//         ids.nft_address = context.nft_address
//         ids.erc20_address = context.erc20_address
//         ids.public_key = context.public_key
//         ids.renter_pubKey = context.renter_pubKey
//         stop_prank_callable = start_prank(context.renter, target_contract_address=context.erc20_address)
//     %}
//     //APPROVE TOKEN SPENDING
//     IERC20.approve(contract_address=erc20_address, spender=rental_address, amount= Uint256(1000,0));
//     let (allowance) = IERC20.allowance(contract_address=erc20_address, owner= renter_address, spender=rental_address);
//     with_attr error_message("Allowance is incorrect, should be 1000 tokens") {
//         assert allowance.low = 1000;
//         assert allowance.high = 0;
//     }
//     %{ 
//         stop_prank_callable()
//     %}

//     //RENT
//     %{ stop_prank_callable = start_prank(context.renter, target_contract_address=context.rental_address) %}

//     IRental.rentTokenSet(contract_address=rental_address, public_key=renter_pubKey);
//     %{ stop_prank_callable() %}

//     let (end_balance_renter) = IERC20.balanceOf(contract_address=erc20_address, account=renter_address);
//     with_attr error_message("Balance is incorrect, should be 99000 tokens") {
//         assert end_balance_renter.low = 99000;
//         assert end_balance_renter.high = 0;
//     }
//     let (balance_rental_contract) = IERC20.balanceOf(contract_address=erc20_address, account=rental_address);
//     with_attr error_message("Balance is incorrect, should be 1000 tokens") {
//         assert balance_rental_contract.low = 1000;
//         assert balance_rental_contract.high = 0;
//     }
//     let (listed) = IRental.isListed(contract_address=rental_address);
//     with_attr error_message("Should not be listed anymore") {
//         assert listed = 0;
//     }
//     let (rented) = IRental.isRented(contract_address=rental_address);
//     with_attr error_message("Should be rented") {
//         assert rented = 1;
//     }
//     let (renter_key) = IRental.getRenterPubKey(contract_address=rental_address);
//     with_attr error_message("Renter pubKey should be configured") {
//         assert renter_key = renter_pubKey;
//     }
//     // CANCEL RENTAL
//     %{ stop_prank_callable = start_prank(context.owner, target_contract_address=context.rental_address) %}

//     IRental.cancelRental(contract_address=rental_address);

//     %{ stop_prank_callable() %}

//     let (listed1) = IRental.isListed(contract_address=rental_address);
//     with_attr error_message("Should not be listed") {
//         assert listed1 = 0;
//     }
//     let (rented1) = IRental.isRented(contract_address=rental_address);
//     with_attr error_message("Should not be rented") {
//         assert rented1 = 0;
//     }
//     let (renter_key2) = IRental.getRenterPubKey(contract_address=rental_address);
//     with_attr error_message("Renter pubKey should be configured") {
//         assert renter_key2 = public_key;
//     }

//     ////////// RUGPULL ///////////
//     // approve spending
//     %{ stop_prank_callable = start_prank(context.rental_address, target_contract_address=context.erc20_address) %}
//     IERC20.approve(contract_address=erc20_address, spender=owner_address, amount= Uint256(10000,0));
//     %{ stop_prank_callable() %}

//     %{ stop_prank_callable = start_prank(context.owner, target_contract_address=context.rental_address) %}

//     IRental.withdrawFunds(contract_address=rental_address);
//     %{ stop_prank_callable() %}

//     let (end_balance_owner) = IERC20.balanceOf(contract_address=erc20_address, account=owner_address);
//     with_attr error_message("Balance is incorrect, should be 1000 tokens") {
//         assert end_balance_owner.low = 1000;
//         assert end_balance_owner.high = 0;
//     }
//     let (balance_rental_contract1) = IERC20.balanceOf(contract_address=erc20_address, account=rental_address);
//     with_attr error_message("Balance is incorrect, should be 0 tokens") {
//         assert balance_rental_contract1.low = 0;
//         assert balance_rental_contract1.high = 0;
//     }
//     return ();
// }

@external
func setup_signature{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    tempvar rental_address;
    tempvar owner_address;
    tempvar renter_address;
    tempvar nft_address;
    tempvar erc20_address;
    tempvar renter_pubKey;

    %{  
        ids.rental_address = context.rental_address
        ids.owner_address = context.owner
        ids.renter_address = context.renter
        ids.nft_address = context.nft_address
        ids.erc20_address = context.erc20_address
        ids.renter_pubKey = context.renter_pubKey
    %}

    // CHECK NFT BALANCE
    %{  
        stop_prank_callable = start_prank(context.owner, target_contract_address=context.nft_address)
    %}
    // MINT AND DEPOSIT
    INFT_contract.mint(contract_address=nft_address, to=owner_address, tokenId=Uint256(1,0));
    INFT_contract.approve(contract_address=nft_address, to=rental_address, tokenId= Uint256(1,0));
    %{ stop_prank_callable() %}
    %{ stop_prank_callable = start_prank(context.owner, target_contract_address=context.rental_address) %}
    IRental.depositNft(contract_address=rental_address, nft_id= Uint256(1,0), nft_address= nft_address);
    %{ stop_prank_callable() %}
    let (check_nft_transfer) = INFT_contract.balanceOf(contract_address=nft_address, owner=rental_address);
    with_attr error_message("Balance is incorrect, should be 1 nft") {
        assert check_nft_transfer.low = 1;
        assert check_nft_transfer.high = 0;
    }
    // PERFORM LISTING (we dont do assert as the feature is checked by the previous test)
    // ALSO WHITELIST TOKEN
    %{  
        stop_prank_callable = start_prank(context.owner, target_contract_address=context.rental_address)
    %}
    IRental.createTokenSetListing(contract_address=rental_address, new_price= Uint256(1000,0) );
    %{ 
        stop_prank_callable()
        stop_prank_callable = start_prank(context.renter, target_contract_address=context.erc20_address)
    %}
    // APPROVE TOKEN SPENDING
    IERC20.approve(contract_address=erc20_address, spender=rental_address, amount= Uint256(1000,0));
    let (allowance) = IERC20.allowance(contract_address=erc20_address, owner= renter_address, spender=rental_address);
    with_attr error_message("Allowance is incorrect, should be 1000 tokens") {
        assert allowance.low = 1000;
        assert allowance.high = 0;
    }
    %{ 
        stop_prank_callable()
    %}
    // RENT
    %{ stop_prank_callable = start_prank(context.renter, target_contract_address=context.rental_address) %}

    IRental.rentTokenSet(contract_address=rental_address, public_key=renter_pubKey);
    %{ stop_prank_callable() %}
    let (balance) = IERC20.balanceOf(contract_address=erc20_address, account=rental_address);
    with_attr error_message("Balance is incorrect, rental should have 1000 tokens") {
        assert balance.low = 1000;
        assert balance.high = 0;
    }
    return ();
}


@external
func test_signature{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    alloc_locals;

    tempvar rental_address;
    tempvar owner_address;
    tempvar renter_address;
    tempvar nft_address;
    tempvar erc20_address;
    tempvar public_key;
    tempvar renter_pubKey;

    %{  
        ids.rental_address = context.rental_address
        ids.owner_address = context.owner
        ids.renter_address = context.renter
        ids.nft_address = context.nft_address
        ids.erc20_address = context.erc20_address
        ids.public_key = context.public_key
        ids.renter_pubKey = context.renter_pubKey
    %}
    //CALL ISVALIDSIGNATURE - SHOULD ACCEPT IF EITHER OWNER OR RENTER IS VALID
    }(hash: felt, signature_len: felt, signature: felt*) -> (isValid: felt) {
    let (sig : felt*) = alloc();
    assert [sig] = 269225779142972199651109725217653211240817421983935685067059684377612126841;
    assert [sig + 1] = 2727210720074434869312178847607596970051270985045269522078566959544842631762;
    let (isValid) = IRental.isValidSignature(contract_address=rental_address, hash=2998291051478732176216285888829199804423409368779164696841252870820966589441, signature_len=2, signature=sig);
    with_attr error_message("Signature not valid") {
        assert isValid = 1;
    }
    
    // TEST TX FROM RENTAL, SHOULD NOT PASS
    // %{ stop_prank_callable = start_prank(context.rental_address, target_contract_address=context.nft_address) %}

    // INFT_contract.approve(contract_address=nft_address, to=owner_address, tokenId= Uint256(1,0));
    // %{ stop_prank_callable() %}


    return ();
}