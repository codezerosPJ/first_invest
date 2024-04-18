// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import "../src/InvestorToken.sol";

contract TestIT is Test{
    InvesToken public invesToken;
    address public owner = address(12345);
    address public funding = address(23456);
    address public badguy = address(0x0bad);

    function setUp() public {
        invesToken = new InvesToken(owner);
    }

    function testonlyOwner() public {
        vm.prank(owner);
        invesToken.setFunding(funding);
        assertEq(invesToken.funding(), funding, "expect address getting stored");
    }

    function testFailonlyOwner() public {
        vm.prank(badguy);
        invesToken.setFunding(funding);
    }

    function testonlyFunding() public {
        vm.prank(owner);
        invesToken.setFunding(funding);
        vm.prank(funding);
        invesToken.mint(funding, 1000);
        assertEq(invesToken.balanceOf(funding), 1000, "expect exact tokens minted");
    }

    function testFailonlyFunding() public {
        vm.prank(badguy);
        invesToken.mint(badguy, 10000);
    }
  
}