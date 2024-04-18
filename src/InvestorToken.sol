// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract InvesToken is ERC20, ERC20Burnable, Ownable {
    address public funding;

    constructor(
        address initialOwner
    ) ERC20("Investor Token", "ITK") Ownable(initialOwner) {}

    function setFunding(address fundingAddr) external onlyOwner {
        funding = fundingAddr;
    }

    modifier onlyFunding() {
        require(_msgSender() == funding, "can't mint");
        _;
    }

    function mint(address to, uint256 amount) public onlyFunding {
        _mint(to, amount);
    }
}
