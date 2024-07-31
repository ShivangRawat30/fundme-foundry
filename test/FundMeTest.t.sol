// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundme.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // next tx will be sent by user
        fundme.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); // next tx will be sent by user
        fundme.fund{value: SEND_VALUE}();

        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerAddress = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        //Act
        vm.prank(fundme.getOwner());
        fundme.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerAddress + startingFundMeBalance
        );
    }
    function testWithdrawFromMultipleFunders() public funded{
      // arrange
      uint160 numberOfFunders = 10;
      uint160 startingFunderIndex = 1;
      for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
        hoax(address(i),SEND_VALUE);
        fundme.fund{value: SEND_VALUE}();
      }
      uint256 startingOwnerBalance = fundme.getOwner().balance;
      uint256 startingFundMeBalance = address(fundme).balance;

      //Act
      vm.startPrank(fundme.getOwner());
      fundme.withdraw();
      vm.stopPrank();

      //Assert
      assert(address(fundme).balance == 0);
      assert(
        startingFundMeBalance + startingOwnerBalance ==
          fundme.getOwner().balance
      );
    }

    function testWithdrawWithASingleFunderCheaper() public funded {
        // Arrange
        uint256 startingOwnerAddress = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        //Act
        vm.prank(fundme.getOwner());
        fundme.cheaperWithDraw();

        //Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerAddress + startingFundMeBalance
        );
    }
    function testWithdrawFromMultipleFundersCheaper() public funded{
      // arrange
      uint160 numberOfFunders = 10;
      uint160 startingFunderIndex = 1;
      for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
        hoax(address(i),SEND_VALUE);
        fundme.fund{value: SEND_VALUE}();
      }
      uint256 startingOwnerBalance = fundme.getOwner().balance;
      uint256 startingFundMeBalance = address(fundme).balance;

      //Act
      vm.startPrank(fundme.getOwner());
      fundme.cheaperWithDraw();
      vm.stopPrank();

      //Assert
      assert(address(fundme).balance == 0);
      assert(
        startingFundMeBalance + startingOwnerBalance ==
          fundme.getOwner().balance
      );
    }
}
