// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0 (token/erc721/IERC721.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace INFT_contract {

    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }

    func name() -> (name: felt) {
    }

    func owner() -> (owner: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func tokenURI(tokenId: Uint256) -> (tokenURI: felt) {
    }

    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }

    func safeTransferFrom(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
    }

    func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }

    func approve(to: felt, tokenId: Uint256) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func getApproved(tokenId: Uint256) -> (approved: felt) {
    }

    func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt) {
    }

    func mint(to: felt, tokenId: Uint256) {
    }

    func burn(tokenId: Uint256) {
    }

    func setTokenURI(tokenId: Uint256, tokenURI: felt) {
    }

    func transferOwnership(newOwner: felt) {
    }

    func renounceOwnership() {
    }
}
