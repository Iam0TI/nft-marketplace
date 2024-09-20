// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

library NftMarketError {
    error NotOwner(address);
    error InsufficientBalanc(uint256 amount);
    error WithdrawFailed(address, uint256);
    error InvalidPrice();
    error InvalidTokenAddress();
    error ListingExsit();
    error NotNftOwner();
    error MarketPlaceNotApprovedToSpend();
    error NotFundsToWithdraw();
    error NotListingOwner();
    error ListingNotActive();
}

library NftMarketEvent {
    event OwnerWithdraw(address indexed owner, uint256 indexed amount);
    event SellerWithdraw(address indexed owner, uint256 indexed amount);
    event ListingCreated(
        address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price, uint256 deadline
    );
    event UpdatedListing(address indexed nftAddress, uint256 indexed tokenId, uint256 price, uint256 deadline);
    event CancelListing(address indexed nftAddress, uint256 indexed tokenId);
    event BoughtNft(address indexed seller, uint256 indexed price, address indexed nftAddress, uint256 tokenId);
}
