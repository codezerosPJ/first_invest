// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface IinvesToken {
    function mint(address, uint256) external;

    function allowance(address, address) external returns (uint256);

    function transferFrom(address, address, uint256) external;

    function burnFrom(address, uint256) external;
}

// Assumption
// Investor can redeem only one time
// NFT SBT

contract Funding is ERC721 {
    IERC20 private _usdt;
    IinvesToken private _invesToken;
    uint256 private _nextPropId;
    mapping(address => mapping(uint256 => uint256)) public ownerToIdToAmount;
    mapping(address => mapping(uint256 => uint256)) public investorToIdToAmount;
    mapping(uint256 => uint256) public idToEarnings;
    mapping(uint256 => bool) public idToSubmit;
    mapping(address => mapping(uint256 => bool)) public isReedemedForToken;

    constructor(address usdtAdd, address addr) ERC721("Property Token", "PTK") {
        _usdt = IERC20(usdtAdd);
        _invesToken = IinvesToken(addr);
    }

    function seekFunds(uint256 funds) external {
        address owner = msg.sender;
        uint256 propId = _nextPropId++;
        ownerToIdToAmount[owner][propId] = funds;
        _invesToken.mint(owner, funds);
        _safeMint(owner, propId);
    }

    function giveFunds(uint256 propId, uint256 amount) external {
        address sc = address(this);
        address investor = _msgSender();
        address owner = ownerOf(propId);
        require(
            _invesToken.allowance(owner, sc) >= amount,
            "Owner haven't allowed investor tokens yet!"
        );
        require(
            _usdt.allowance(investor, sc) >= amount,
            "USDT not allowed by investor"
        );
        require(
            ownerToIdToAmount[owner][propId] >= amount,
            "Can't invest more than the limit"
        );
        investorToIdToAmount[investor][propId] =
            investorToIdToAmount[investor][propId] +
            amount;
        _usdt.transferFrom(investor, owner, amount);
        _invesToken.transferFrom(owner, investor, amount);
    }

    function submitEarnings(uint256 earnings, uint256 propId) external {
        address sc = address(this);
        address owner = _msgSender();
        require(
            ownerOf(propId) == owner,
            "Can't submit earnings for this property"
        );
        require(
            _usdt.allowance(owner, sc) >= earnings,
            "USDT not allowed by owner"
        );
        idToEarnings[propId] = idToEarnings[propId] + earnings;
        idToSubmit[propId] = true;
        _usdt.transferFrom(owner, sc, earnings);
    }

    function redeemEarnings(uint256 propId) external {
        address investor = _msgSender();
        address sc = address(this);
        address owner = ownerOf(propId);
        uint256 investment = investorToIdToAmount[investor][propId];
        uint256 returnAmount = (investment * idToEarnings[propId]) /
            ownerToIdToAmount[owner][propId];
        require(idToSubmit[propId], "Earnings not submitted till now");
        require(returnAmount > 0, "Never invested");
        require(
            !isReedemedForToken[investor][propId],
            "Can only redeem one time"
        );
        require(
            _invesToken.allowance(investor, sc) >= investment,
            "Investor token allowance is required"
        );
        isReedemedForToken[investor][propId] = true;
        _invesToken.burnFrom(investor, investment);
        _usdt.transfer(investor, returnAmount);
    }
}
