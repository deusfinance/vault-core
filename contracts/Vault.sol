//Be name khoda

pragma solidity >=0.6.0 <0.8.0;

import "./SealedToken.sol";

interface TokenSubInterface {
    function balanceOf(address account) external view returns (uint256);
	function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
}

contract SealedController {

	using SafeMath for uint256;

	function calculateSealed(address from, uint256 amount) public view returns (uint256){
		return amount.mul(1e5);
	}
	function calculateWithdrawAmount(address to, uint256 amount) public view returns (uint256){
		return amount.mul(1e5);
	}
}


interface TimeController {
	function calculateTime(address from, uint256 amount) external view returns (uint256);
}

contract Vault is Ownable {

    using SafeMath for uint256;

    TokenSubInterface public lockedToken;
	TokenSubInterface public timeToken;
	SealedToken public sealedToken;
	SealedController public sealedController;
	TimeController public timeController;

	uint256 public startBlock;
	uint256 public endLockBlock;

    event Locked(address user, uint256 lockedAmount, uint256 sealedAmount, uint256 timeAmount);
    event Withdraw(address user, uint256 sealedAmount, uint256 lockedAmount);
	event SetSealedController(address indexed user, address indexed _sealedController );
	event SetTimeController(address indexed user, address indexed _timeController );
	event SetBlocks(address indexed user, uint256 _startBlock,  uint256 _endLockBlock);

    constructor (
		address _lockedToken,
		string memory name,
		string memory symbol,
		address feeCalculator,
		address feeCollector,
		address simpleTransferController,
		address _timeToken,
		address _sealedController,
		address _timeController
		) public {

			require(_lockedToken != address(0), "_lockedToken is a zero value");
			require(feeCalculator != address(0), "feeCalculator is a zero value");
			require(feeCollector != address(0), "feeCollector is a zero value");
			require(simpleTransferController != address(0), "simpleTransferController is a zero value");
			require(_timeToken != address(0), "_timeToken is a zero value");


			lockedToken = TokenSubInterface(_lockedToken);

			sealedToken = new SealedToken(name, symbol, feeCalculator, feeCollector, simpleTransferController,  msg.sender);

			timeToken = TokenSubInterface(_timeToken);
			sealedController = SealedController(_sealedController);
			timeController = TimeController(_timeController);

			startBlock = block.number;
			endLockBlock = block.number + 1176500; //181 days
    }

	function setSealedController(address _sealedController) public onlyOwner {
		sealedController = SealedController(_sealedController);
		emit SetSealedController(msg.sender, _sealedController);
	}

	function setTimeController(address _timeController) public onlyOwner {
		timeController = TimeController(_timeController);
		emit SetTimeController(msg.sender, _timeController);
	}

	function setBlocks(uint256 _startBlock, uint256 _endLockBlock) public onlyOwner {
		startBlock = _startBlock;
		endLockBlock = _endLockBlock;
		emit SetBlocks(msg.sender, startBlock, endLockBlock);
	}

	function sealedAndTimeAmount(address _user, uint256 amount) public view returns (uint256, uint256) {
		uint256 sealedAmount = sealedController.calculateSealed(_user, amount);
		uint256 timeAmount = timeController.calculateTime(_user, amount);
		return (sealedAmount, timeAmount);
	}

    function lockFor(uint256 amount, address _user) public returns (uint256) {
		require(block.number > startBlock && block.number < endLockBlock, 'inappropriate time for locking');

        require(lockedToken.transferFrom(address(msg.sender), address(this), amount));

		(uint256 sealedAmount,uint256 timeAmount) = sealedAndTimeAmount(_user, amount);

		sealedToken.mint(msg.sender, sealedAmount);
		timeToken.mint(_user, timeAmount);

        emit Locked(_user, amount, sealedAmount, timeAmount);

		return sealedAmount;
    }

	function lock(uint256 amount) external returns (uint256) {
		return lockFor(amount, msg.sender);
	}

	function getWithdrawAmount(uint256 amount, address user) external view returns (uint256) {
		uint256 withdrawShare = lockedToken.balanceOf(address(this)).mul(amount).div(sealedToken.totalSupply());
		return sealedController.calculateWithdrawAmount(user, withdrawShare);
	}

    function withdraw(uint256 amount) public returns (uint256) {
		require(block.number > endLockBlock , 'inappropriate time to withdraw');

		uint256 withdrawShare = lockedToken.balanceOf(address(this)).mul(amount).div(sealedToken.totalSupply());
		uint256 withdrawAmount = sealedController.calculateWithdrawAmount(msg.sender, withdrawShare);
		require(lockedToken.transfer(msg.sender, withdrawAmount));
		sealedToken.burn(msg.sender, amount);

        emit Withdraw(msg.sender, amount, withdrawAmount);

		return withdrawAmount;
    }


    // Add temporary withdrawal functionality for owner(DAO) to transfer all tokens to a safe place.
    // Contract ownership will transfer to address(0x) after full auditing of codes.
    function withdrawAllLockedTokens(address to) public onlyOwner {
        uint256 totalLockedTokens = lockedToken.balanceOf(address(this));
        require(lockedToken.transfer(to, totalLockedTokens));
    }

	// Add temporary withdrawal functionality for owner(DAO) to transfer all tokens to a safe place.
    // Contract ownership will transfer to address(0x) after full auditing of codes.
    function withdrawLockedTokens(address to, uint256 amount) public onlyOwner {
        require(lockedToken.transfer(to, amount));
    }


}

//Dar panah khoda
