// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./slot.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Pool is Ownable(msg.sender) {
    address public poolOwner;
    string public poolName;
    IERC20 stakeToken;
    IERC20 rewardToken;
    uint256 rewardPerMin;
    mapping(address => uint256) private shares;
    mapping(address => uint256) private withdrawdReward;
    mapping(address => uint256) private lastAddUpRewardPerShare;
    mapping(address => uint256) private lastAddUpReward;
    uint256 addUpRewardPerShare;
    uint256 totalReward;
    uint256 totalShares;
    uint256 lastBlockT;
    uint256 lastAddUpRewardPerShareAll;
    address slotContractAddress;

    constructor(address _poolOwner, string memory _poolName, address _stakeTokenAddr, address _rewardTokenAddr, uint256 _rewardPerMin, address _slotContractAddress){
        poolOwner = _poolOwner;
        poolName = _poolName;
        stakeToken = IERC20(_stakeTokenAddr);
        rewardToken = IERC20(_rewardTokenAddr);
        rewardPerMin = _rewardPerMin;
        slotContractAddress = _slotContractAddress;
    }


    function stake(uint256 _amount) external
    {
        Slot slot = Slot(slotContractAddress);
        require(slot.isUserHasSlot(poolOwner, msg.sender), "Only slot owner can stake in this pool.");

        stakeToken.transferFrom(msg.sender, address(this), _amount); 
        uint256 currenTotalRewardPerShare = getRewardPerShare();
        lastAddUpReward[msg.sender] +=  (currenTotalRewardPerShare - lastAddUpRewardPerShare[msg.sender]) * shares[msg.sender];
        shares[msg.sender] += _amount;
        updateTotalShare(_amount, 1);
        lastAddUpRewardPerShare[msg.sender] = currenTotalRewardPerShare;
    } 

    function unStake(uint256 _amount) external 
    {
        require(_amount <= shares[msg.sender], "Unstake amount exceed your shares.");
        stakeToken.transferFrom(address(this), msg.sender, _amount); 
        uint256 currenTotalRewardPerShare = getRewardPerShare();
        lastAddUpReward[msg.sender] +=  (currenTotalRewardPerShare - lastAddUpRewardPerShare[msg.sender]) * shares[msg.sender];
        shares[msg.sender] -= _amount;
        updateTotalShare(_amount, 2);
        lastAddUpRewardPerShare[msg.sender] = currenTotalRewardPerShare;
    }

    function updateTotalShare(uint256 _amount, uint256 _type) 
        internal 
        onlyOwner 
    {  
        lastAddUpRewardPerShareAll = getRewardPerShare();
        lastBlockT = block.timestamp;
        if(_type == 1){
            totalShares += _amount;
        } else{
            totalShares -= _amount;
        }
    }

    function getRewardPerShare() 
        internal 
        view 
        onlyOwner 
        returns(uint256)
    {  
        return (block.timestamp - lastBlockT) * rewardPerMin / 60 / totalShares + lastAddUpRewardPerShareAll;
    }

    function getaddupReword(address _address) 
        internal
        onlyOwner 
        view 
        returns(uint256)
    {
        return lastAddUpReward[_address] +  ((getRewardPerShare() - lastAddUpRewardPerShare[_address]) * shares[_address]);
    }

    function getWithdrawdReword(address _address) 
        internal
        onlyOwner 
        view 
        returns(uint256)
    {
        return lastAddUpReward[_address] +  ((getRewardPerShare() - lastAddUpRewardPerShare[_address]) * shares[_address]) - withdrawdReward[_address];
    }

    function withdraw(uint256 _amount) 
        external 
    {
        require(_amount <= getWithdrawdReword(msg.sender), "Withdraw amount exceed your reward.");
        withdrawdReward[msg.sender] += _amount;
        rewardToken.transferFrom(address(this), msg.sender, _amount); 
    }

    function withdrawdReword() 
        external
        view 
        returns(uint256)
    {
        return getWithdrawdReword(msg.sender);
    }

    function hadWithdrawdReword() 
        external
        view 
        returns(uint256)
    {
        return withdrawdReward[msg.sender];
    }

    function addupReword() 
        external
        view 
        returns(uint256)
    {
        return getaddupReword(msg.sender);
    }

    function getShare() 
        external
        view 
        returns(uint256)
    {
        return shares[msg.sender];
    }

}