// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    // from forge-std
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 10e18;
    uint256 constant STARTING_BALANCE = 50e18;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // give the test user a starting balance in order to test the transaction
        vm.deal(USER, STARTING_BALANCE);
    }
    // Testing works  by calling setup(), then the test, setup(),
    // then the next test... gets reset every time.

    function testMinimumDollarisFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMesgSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);

        // The above does not work as the process works like us (start) -> FundMeTest -> FundME
        // Should be us -> FunMe to work
        // Instead need to use the address from the function
        // assertEq(fundMe.i_owner(),address(this)); -- If not using the deployFundMe() method
        // This makes sense as the object was created in test not the original FundMe contract
        // When using deployFundMe, you return the objet created by FundMe contract to use in test
    }

    function testPriceFeedVersionisAccurate() public view {
        // How would we test for differenr price feed versions?

        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
        // This fails as foundry is spinning up anvil chain different from the one in FundMe
        // make sure to submit to RPC-URL in test?? YES with --fork-url

        // put the sepolia RPC URL in .env , source .env , then pass --fork-url $SEPOLIA_RPC_URL
    }

    function testFundFailsWithoutEnoughEth() public {
        // go to the cheatcode of foundry
        vm.expectRevert(); // The next line should revert
        // same as assert(This txn fails)...
        fundMe.fund();
        // the above failsas the amount is less than MINIMUM_USD.
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next Txn will be sent by USER

        fundMe.fund{value: SEND_VALUE}();
        // uint256 amountFunded  = fundMe.getAddressToAmountFunded(msg.sender);
        // The above does not work as its not the correct address
        // uint256 amountFunded  = fundMe.getAddressToAmountFunded(address(this));
        // The above does work as its the addresss calling the FundedMe contract.

        // Need a better way to keep track of who is calling what function / contract
        // and when... use the prank cheat code (only works with Foundry / Only in Tests)
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assert(funder == USER);
    }

    modifier funded() {
        // have to fund the contract first with money
        // wrapper to modify the code without repeating
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // try to have USER withdraw money
        vm.prank(USER);
        vm.expectRevert(); // The next line should revert - not owner!
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //Arrange -setup the test
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint256 gasStart = gasleft(); // gasleft() built in SOL
        // vm.txGasPrice(GAS_PRICE);
        // vm.startPrank(fundMe.getOwner());
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart-gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);

        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        // if you want to use numbers to gen addresses,
        // need to use uin160
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // but forge has a built in for this - hoax (does both)
            hoax(address(i), SEND_VALUE); // usin idx 1 as 0 in address()
            // sometimes reverts

            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Act

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        // if you want to use numbers to gen addresses,
        // need to use uin160
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // but forge has a built in for this - hoax (does both)
            hoax(address(i), SEND_VALUE); // usin idx 1 as 0 in address()
            // sometimes reverts

            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        //Act

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}
