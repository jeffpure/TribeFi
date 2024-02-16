// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Slot is Ownable(msg.sender) {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;

    event Trade(address trader, address subject, bool isBuy, uint256 slotAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 supply);

    // SlotSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public slotsBalance;

    // SlotsSubject => Supply
    mapping(address => uint256) public slotsSupply;

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
    }

    function isUserHasSlot( address slotsSubject, address user) public view returns (bool) {
        return (slotsBalance[slotsSubject][user] > 0);
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    function getBuyPrice(address slotsSubject, uint256 amount) public view returns (uint256) {
        return getPrice(slotsSupply[slotsSubject], amount);
    }

    function getSellPrice(address slotsSubject, uint256 amount) public view returns (uint256) {
        return getPrice(slotsSupply[slotsSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(address slotsSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(slotsSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(address slotsSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(slotsSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        return price - protocolFee - subjectFee;
    }

    function buySlots(address slotsSubject, uint256 amount) public payable {
        uint256 supply = slotsSupply[slotsSubject];
        require(supply > 0 || slotsSubject == msg.sender, "Only the slots' subject can buy the first slot");
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee, "Insufficient payment");
        slotsBalance[slotsSubject][msg.sender] = slotsBalance[slotsSubject][msg.sender] + amount;
        slotsSupply[slotsSubject] = supply + amount;
        emit Trade(msg.sender, slotsSubject, true, amount, price, protocolFee, subjectFee, supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = slotsSubject.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function sellSlots(address slotsSubject, uint256 amount) public payable {
        uint256 supply = slotsSupply[slotsSubject];
        require(supply > amount, "Cannot sell the last slot");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        require(slotsBalance[slotsSubject][msg.sender] >= amount, "Insufficient slots");
        slotsBalance[slotsSubject][msg.sender] = slotsBalance[slotsSubject][msg.sender] - amount;
        slotsSupply[slotsSubject] = supply - amount;
        emit Trade(msg.sender, slotsSubject, false, amount, price, protocolFee, subjectFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = slotsSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }
}