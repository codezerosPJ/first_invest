// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Funding.sol";
import "../src/InvestorToken.sol";

contract MainnetScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ownerAddr =  vm.addr(deployerPrivateKey);
        address usdtAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        address iTokenAddr;
        address fundingAddr;
        vm.startBroadcast(deployerPrivateKey);

        InvesToken invesToken = new InvesToken(ownerAddr);
        iTokenAddr = address(invesToken);
        Funding funding = new Funding(usdtAddr,iTokenAddr);
        fundingAddr = address(funding);
        invesToken.setFunding(fundingAddr);

        vm.stopBroadcast();
    }
}