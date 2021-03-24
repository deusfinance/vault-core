//Be name khoda

pragma solidity >=0.6.0 <0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

interface balancerPool {
	function gulp (address token) external;
}

contract TransferController is Ownable{

	address public token;
	address public balancerPool1;
	address public balancerPool2;
	mapping (address => bool) public balancerPools;

	constructor(address _token, address _balancerPool1, address _balancerPool2) public{
		token = _token;
		balancerPools[_balancerPool1] =  true;
		balancerPools[_balancerPool2] = true;
	}

	function setAddressBalancerPoolState(address _address, bool balancerState) public onlyOwner{
		balancerPools[_address] = balancerState;
	}
	
	function afterTokenTransfer(address from, address to, uint256 value) public{
		if (balancerPools[from]){
			balancerPool(from).gulp(token);
		}
		if (balancerPools[to]){
			balancerPool(to).gulp(token);
		}
	}
}

//Dar panah khoda
