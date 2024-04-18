// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Funding.sol";
import "../src/fusdt.sol";
import "../src/InvestorToken.sol";

contract TestnetScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ownerAddr = vm.addr(deployerPrivateKey);
        address usdtAddr;
        address iTokenAddr;
        address fundingAddr;
        vm.startBroadcast(deployerPrivateKey);

        USDT usdt = new USDT();
        usdtAddr = address(usdt);
        InvesToken invesToken = new InvesToken(ownerAddr);
        iTokenAddr = address(invesToken);
        Funding funding = new Funding(usdtAddr, iTokenAddr);
        fundingAddr = address(funding);
        invesToken.setFunding(fundingAddr);

        vm.stopBroadcast();
    }
}
