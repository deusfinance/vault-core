//Be name khoda

pragma solidity >=0.6.0 <0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/math/SafeMath.sol";

interface IUniswapV2Router01{
	function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
	function totalSupply() external view returns (uint256);
}

// DAI Time controller
 contract TimeController{
 	using SafeMath for uint256;

 	function calculateTime(address from, uint256 amount) public view returns (uint256){
 		return amount.div(10);
 	}
 }
