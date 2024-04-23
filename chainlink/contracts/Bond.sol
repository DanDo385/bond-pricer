// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Bond is ERC721, VRFConsumerBase {
    uint256 public maturity;
    uint256 public dailyRate; // Annual rate, but interest compounds daily
    uint256 public nextPaymentTime;
    uint256 public auctionPrice;
    uint256 public principal = 1000 ether; // Principal amount for the bond in Sepolia ETH
    bytes32 internal keyHash;
    uint256 internal fee;

    // Events to log activities
    event DailyInterestPaid(uint256 interest);
    event NewAuctionPrice(uint256 price);

    constructor(
        uint256 _maturityYears,
        uint256 _dailyRate,
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash
    ) ERC721("SepoliaTestBond", "STB") VRFConsumerBase(_VRFCoordinator, _LinkToken) {
        maturity = block.timestamp + (_maturityYears * 365 days);
        dailyRate = _dailyRate;
        nextPaymentTime = block.timestamp + 1 days;
        keyHash = _keyHash;
        fee = 0.1 * 10 ** 18; // Chainlink VRF fee
    }

    function requestAuctionPrice() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with LINK");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        uint256 minPrice = 9975; // Represents 99.75
        uint256 maxPrice = 10025; // Represents 100.25
        auctionPrice = minPrice + (randomness % (maxPrice - minPrice + 1));
        emit NewAuctionPrice(auctionPrice);
    }

    function payDailyInterest() public {
        require(block.timestamp >= nextPaymentTime, "It's not time for the next payment yet");
        uint256 timeSinceLastPayment = block.timestamp - (nextPaymentTime - 1 days);
        uint256 interest = (principal * dailyRate / 36500) * timeSinceLastPayment / 1 days;
        principal += interest;
        nextPaymentTime += 1 days;
        emit DailyInterestPaid(interest);
    }

    function mint(address to) public {
        uint256 tokenId = totalSupply() + 1;
        _mint(to, tokenId);
    }
}
