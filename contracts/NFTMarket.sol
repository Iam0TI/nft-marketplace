// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {NftMarketError, NftMarketEvent} from "./NFTMarketUtils.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftMarket {
    struct Listing {
        address sellerAddress;
        uint256 nftPrice;
        uint256 salesDeadline;
        bool listingStatus;
    }

    // token  => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) nftListings;
    // seller's  address  => amountavailable to withdraw
    mapping(address => uint256) public sellerLists;

    address owner;

    uint256 withdrawAblebyOwner;

    constructor() {
        owner = msg.sender;
    }

    function getNftListing(address nftTokenAddress, uint256 tokenId) external view returns (Listing memory) {
        return nftListings[nftTokenAddress][tokenId];
    }

    function SellerWithdrawable(address sellerAddress) external view returns (uint256) {
        return sellerLists[sellerAddress];
    }

    function ownerWithdraw(uint256 _amount) external {
        require(msg.sender == owner, NftMarketError.NotOwner(msg.sender));
        require(_amount <= withdrawAblebyOwner, NftMarketError.InsufficientBalanc(_amount));
        withdrawAblebyOwner = withdrawAblebyOwner - _amount;
        (bool success,) = payable(owner).call{value: _amount}("");
        require(success, NftMarketError.WithdrawFailed(msg.sender, _amount));

        emit NftMarketEvent.OwnerWithdraw(msg.sender, _amount);
    }

    function listNftForSale(address _nftAddress, uint256 _tokenId, uint256 _nftPrice, uint256 _salesDeadline)
        external
    {
        require(_nftPrice > 0, NftMarketError.InvalidPrice());

        require(_salesDeadline > block.timestamp + 10 minutes, NftMarketError.InvalidPrice());

        require(_nftAddress != address(0), NftMarketError.InvalidTokenAddress());

        require(nftListings[_nftAddress][_tokenId].listingStatus == false, NftMarketError.ListingExsit());

        require(IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender, NftMarketError.NotNftOwner());

        require(
            IERC721(_nftAddress).getApproved(_tokenId) == address(this), NftMarketError.MarketPlaceNotApprovedToSpend()
        );

        nftListings[_nftAddress][_tokenId] = Listing(msg.sender, _nftPrice, _salesDeadline, true);

        emit NftMarketEvent.ListingCreated(msg.sender, _nftAddress, _nftPrice, _tokenId, _salesDeadline);
    }

    function updateListingForSale(address _nftAddress, uint256 _tokenId, uint256 _nftPrice, uint256 _salesDealine)
        external
    {
        require(nftListings[_nftAddress][_tokenId].sellerAddress == msg.sender, NftMarketError.NotListingOwner());

        require(nftListings[_nftAddress][_tokenId].listingStatus == true, NftMarketError.ListingNotActive());

        require(_nftPrice > 0, NftMarketError.InvalidPrice());

        nftListings[_nftAddress][_tokenId].salesDeadline += _salesDealine;

        nftListings[_nftAddress][_tokenId].nftPrice = _nftPrice;

        emit NftMarketEvent.UpdatedListing(_nftAddress, _tokenId, _nftPrice, _salesDealine);
    }

    function cancelListingForSale(address _nftAddress, uint256 _tokenId) external {
        require(nftListings[_nftAddress][_tokenId].sellerAddress == msg.sender, NftMarketError.NotListingOwner());

        require(nftListings[_nftAddress][_tokenId].listingStatus == true, NftMarketError.ListingNotActive());

        delete (nftListings[_nftAddress][_tokenId]);
        emit NftMarketEvent.CancelListing(_nftAddress, _tokenId);
    }

    function buyNft(address _nftAddress, uint256 _tokenId) external payable {
        require(nftListings[_nftAddress][_tokenId].listingStatus == true, NftMarketError.ListingNotActive());

        require(nftListings[_nftAddress][_tokenId].salesDeadline < block.timestamp, NftMarketError.ListingNotActive());

        require(nftListings[_nftAddress][_tokenId].nftPrice >= msg.value, NftMarketError.InvalidPrice());

        address sellerAddress = nftListings[_nftAddress][_tokenId].sellerAddress;

        //  3% price fee for market place
        uint256 nftPricewithFee = (msg.value * 97) / 100;

        uint256 fee = msg.value - nftPricewithFee;

        sellerLists[sellerAddress] += nftPricewithFee;
        withdrawAblebyOwner = withdrawAblebyOwner + fee;

        delete (nftListings[_nftAddress][_tokenId]);

        IERC721(_nftAddress).safeTransferFrom(sellerAddress, msg.sender, _tokenId);

        emit NftMarketEvent.BoughtNft(msg.sender, msg.value, _nftAddress, _tokenId);
    }

    function sellerWithdraw() external {
        require(sellerLists[msg.sender] > 0, NftMarketError.NotFundsToWithdraw());

        uint256 amount = sellerLists[msg.sender];

        sellerLists[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        require(success, NftMarketError.WithdrawFailed(msg.sender, amount));

        emit NftMarketEvent.SellerWithdraw(msg.sender, amount);
    }
}
