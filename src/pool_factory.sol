// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./pool.sol";

contract PoolFactory {
    address[] public pools;
    mapping(address => address[]) private ownerPools;

    event PoolAdded(address indexed _poolOwner, address indexed _stakeTokenAddr, address indexed _rewardTokenAddr, uint256 _rewardPerMin);

    function getAllPools() public view returns (address[] memory) {
        return pools;
    }

    function getOwnerPools(address _owner) public view returns (address[] memory) {
        return ownerPools[_owner];
    }

    function addPool(string calldata _poolName, address _stakeTokenAddr, address _rewardTokenAddr, uint256 _rewardPerMin, address _slotContractAddress) public {
        Pool pool = new Pool(msg.sender, _poolName, _stakeTokenAddr, _rewardTokenAddr, _rewardPerMin, _slotContractAddress);
        pools.push(address(pool));
        ownerPools[msg.sender].push(address(pool));

        emit PoolAdded(msg.sender, _stakeTokenAddr, _rewardTokenAddr, _rewardPerMin);
    }
}
