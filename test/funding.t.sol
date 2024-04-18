// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/forge-std/src/Test.sol";
import "../src/InvestorToken.sol";
import "../src/Funding.sol";
import "../src/fusdt.sol";

contract TestFunding is Test {
    InvesToken public invesToken;
    Funding public funding;
    USDT public usdt;
    address public iTokenOwner = address(11111);
    address public propOwner = address(12345);
    address public investor1 = address(23456);
    address public investor2 = address(34567);
    address public fundingAddr;
    address public itokenAddr;
    address public usdtAddr;
    uint256 ask = 1000;
    uint256 investment = 100;
    uint256 earnings = 1000;

    function setUp() public {
        usdt = new USDT();
        usdtAddr = address(usdt);
        invesToken = new InvesToken(iTokenOwner);
        itokenAddr = address(invesToken);
        funding = new Funding(usdtAddr, itokenAddr);
        fundingAddr = address(funding);
        vm.prank(iTokenOwner);
        invesToken.setFunding(fundingAddr);
        usdt.mint(investor1, 10000);
        usdt.mint(investor2, 10000);
    }

    function testlisting() public {
        vm.prank(propOwner);
        funding.seekFunds(ask);
        assertEq(
            invesToken.balanceOf(propOwner),
            ask,
            "expect exact amount minted"
        );
        assertEq(funding.balanceOf(propOwner), 1, "expect 1 NFT minted");
    }

    function testgiveFunds() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        uint256 prevbalance = usdt.balanceOf(investor1);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        assertEq(
            usdt.balanceOf(investor1),
            prevbalance - investment,
            "expect usdt gets deducted from investor"
        );
        assertEq(
            invesToken.balanceOf(investor1),
            investment,
            "expect investor gets exact Itoken"
        );
        assertEq(
            usdt.balanceOf(propOwner),
            investment,
            "expect owner gets exact usdt"
        );
        assertEq(
            invesToken.balanceOf(propOwner),
            ask - investment,
            "expect exact Itokens gets deducted from owner's account"
        );
    }

    function testFailgiveFundsITokenNotApproved() public {
        vm.prank(propOwner);
        funding.seekFunds(ask);
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
    }

    function testFailgiveFundsUsdtNotApproved() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.prank(investor1);
        funding.giveFunds(0, investment);
    }

    function testFailgiveFundsInvestGTLimit() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, ask + 1);
        funding.giveFunds(0, ask + 1);
        vm.stopPrank();
    }

    function testSubmitEarnings() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        uint256 prevBalance = usdt.balanceOf(propOwner);
        usdt.mint(propOwner, earnings);
        vm.startPrank(propOwner);
        usdt.approve(fundingAddr, earnings);
        funding.submitEarnings(earnings, 0);
        assertEq(usdt.balanceOf(propOwner), prevBalance);
    }

    function testFailSubmitEarningsNotOwner() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        usdt.mint(propOwner, earnings);
        vm.startPrank(propOwner);
        usdt.approve(fundingAddr, earnings);
        vm.stopPrank();
        funding.submitEarnings(earnings, 0);
    }

    function testFailSubmitEarningsNotApproved() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        usdt.mint(propOwner, earnings);
        vm.startPrank(propOwner);
        funding.submitEarnings(earnings, 0);
    }

    function testRedeemEarnings() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        uint256 prevBalance = usdt.balanceOf(investor1);
        vm.stopPrank();
        usdt.mint(propOwner, earnings);
        vm.startPrank(propOwner);
        usdt.approve(fundingAddr, earnings);
        funding.submitEarnings(earnings, 0);
        vm.stopPrank();
        vm.startPrank(investor1);
        invesToken.approve(fundingAddr, investment);
        funding.redeemEarnings(0);
        assertEq(
            usdt.balanceOf(investor1),
            prevBalance + ((investment * earnings) / ask)
        );
    }

    function testRedeemEarningNotSubmitted() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        invesToken.approve(fundingAddr, investment);
        vm.expectRevert(bytes("Earnings not submitted till now"));
        funding.redeemEarnings(0);
    }

    function testRedeemNeverInvested() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        usdt.mint(propOwner, earnings);
        vm.startPrank(propOwner);
        usdt.approve(fundingAddr, earnings);
        funding.submitEarnings(earnings, 0);
        vm.stopPrank();
        vm.startPrank(investor2);
        invesToken.approve(fundingAddr, investment);
        vm.expectRevert(bytes("Never invested"));
        funding.redeemEarnings(0);
    }

    function testRedeemAlreadyRedeemed() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        usdt.mint(propOwner, earnings);
        vm.startPrank(propOwner);
        usdt.approve(fundingAddr, earnings);
        funding.submitEarnings(earnings, 0);
        vm.stopPrank();
        vm.startPrank(investor1);
        invesToken.approve(fundingAddr, investment);
        funding.redeemEarnings(0);
        vm.expectRevert(bytes("Can only redeem one time"));
        funding.redeemEarnings(0);
    }

    function testRedeemItokenNotAllowed() public {
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        usdt.mint(propOwner, earnings);
        vm.startPrank(propOwner);
        usdt.approve(fundingAddr, earnings);
        funding.submitEarnings(earnings, 0);
        vm.stopPrank();
        vm.startPrank(investor1);
        vm.expectRevert(bytes("Investor token allowance is required"));
        funding.redeemEarnings(0);
    }

    function testDoubleInvestAndRedeem() public {
        uint256 investment2 = 400;
        vm.startPrank(propOwner);
        funding.seekFunds(ask);
        invesToken.approve(fundingAddr, ask);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        vm.startPrank(investor2);
        usdt.approve(fundingAddr, investment);
        funding.giveFunds(0, investment);
        vm.stopPrank();
        vm.startPrank(investor1);
        usdt.approve(fundingAddr, investment2);
        funding.giveFunds(0, investment2);
        vm.stopPrank();
        uint256 prevBalance = usdt.balanceOf(investor1);
        usdt.mint(propOwner, earnings);
        vm.startPrank(propOwner);
        usdt.approve(fundingAddr, earnings);
        funding.submitEarnings(earnings, 0);
        vm.stopPrank();
        vm.startPrank(investor1);
        invesToken.approve(fundingAddr, investment + investment2);
        uint256 totalInvestment = investment + investment2;
        funding.redeemEarnings(0);
        assertEq(
            usdt.balanceOf(investor1) - prevBalance,
            (totalInvestment * earnings) / ask
        );
    }
}
