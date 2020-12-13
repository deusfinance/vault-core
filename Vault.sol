//Be name khoda

pragma solidity >=0.6.0 <0.8.0;

import "SandToken.sol";

interface TokenSubInterface {
    function balanceOf(address account) external view returns (uint256);
	function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
}

contract SandController{
	function calculateSand(address from, uint256 amount) public view returns (uint256){
		return amount;
	}
	function calculateWithdrawAmount(address to, uint256 amount) public view returns (uint256){
		return amount;
	}
}

contract TimeController{
	using SafeMath for uint256;

	function calculateTime(address from, uint256 amount) public view returns (uint256){
		return amount.div(2);
	}
}

contract Vault is Ownable {

    struct User {
        uint256 lockedAmount;
        uint256 paidReward;
    }

    using SafeMath for uint256;

    mapping (address => User) public users;

    // uint256 public scale = 1e18;

    // uint256 public particleCollector = 0;
    // uint256 public daoShare;
    // uint256 public earlyFoundersShare;
    // address public daoWallet;
    // address public earlyFoundersWallet;

    TokenSubInterface public lockedToken;
	TokenSubInterface public timeToken;
	SandToken public sandToken;
	SandController public sandController;
	TimeController public timeController;

	uint256 public startBlock;
	uint256 public endLockBlock;

    event Locked(address user, uint256 lockedAmount, uint256 sandAmount, uint256 timeAmount);
    event Withdraw(address user, uint256 sandAmount, uint256 lockedAmount);

    constructor (
		address _lockedToken,
		// uint256 _daoShare,
		// uint256 _earlyFoundersShare,
		string memory name,
		string memory symbol,
		address _feeCalculator,
		address _feeCollector,
		address _timeToken,
		address _sandController,
		address _timeController
		) public {
			lockedToken = TokenSubInterface(_lockedToken);
			timeToken = TokenSubInterface(_timeToken);
			sandToken = new SandToken(name, symbol, _feeCalculator, _feeCollector, msg.sender);
			sandController = SandController(_sandController);
			timeController = TimeController(_timeController);

			startBlock = block.number; //todo get it in constructor
			endLockBlock = block.number; //todo get it in constructor


			// daoShare = _daoShare;
			// earlyFoundersShare = _earlyFoundersShare;
			// daoWallet = msg.sender;
			// earlyFoundersWallet = msg.sender;
    }

	function setSandController(address _sandController) public onlyOwner{
		sandController = SandController(_sandController);
	}

	function setTimeController(address _timeController) public onlyOwner{
		timeController = TimeController(_timeController);
	}

	function setBlocks(uint256 _startBlock, uint256 _endLockBlock) public onlyOwner{
		startBlock = _startBlock;
		endLockBlock = _endLockBlock;
	}

    // function setWallets(address _daoWallet, address _earlyFoundersWallet) public onlyOwner {
    //     daoWallet = _daoWallet;
    //     earlyFoundersWallet = _earlyFoundersWallet;
    // }

    // function setShares(uint256 _daoShare, uint256 _earlyFoundersShare) public onlyOwner {
    //     withdrawParticleCollector();
    //     daoShare = _daoShare;
    //     earlyFoundersShare = _earlyFoundersShare;
    // }

	function sandAndTimeAmount(uint256 amount, address _user) external view returns (uint256, uint256){
		uint256 sandAmount = sandController.calculateSand(_user, amount);
		uint256 timeAmount = timeController.calculateTime(_user, amount); 
		return (sandAmount, timeAmount);
	}

    function lockFor(uint256 amount, address _user) public {
		require(block.number > startBlock , 'inappropriate time for locking'); // TODO add end block check

        User storage user = users[_user];
        user.lockedAmount = user.lockedAmount.add(amount);
        lockedToken.transferFrom(address(msg.sender), address(this), amount);
		uint256 sandAmount = sandController.calculateSand(_user, amount);
		sandToken.mint(msg.sender, sandAmount);

		uint256 timeAmount = timeController.calculateTime(_user, amount); 
		timeToken.mint(_user, timeAmount);

        emit Locked(_user, amount, sandAmount, timeAmount);
    }

	function lock(uint256 amount) public {
		lockFor(amount, msg.sender);
	}

	function getWithdrawAmount(uint256 amount, address user) external view returns (uint256){
		uint256 withdrawShare = lockedToken.balanceOf(address(this)).mul(amount).div(sandToken.totalSupply());
		return sandController.calculateWithdrawAmount(user, withdrawShare);
	} 

    function withdraw(uint256 amount) public {
		require(block.number > endLockBlock , 'inappropriate time to withdraw'); // TODO add end block check

        User storage user = users[msg.sender];
        // user.lockedAmount = user.lockedAmount.sub(amount);

		uint256 withdrawShare = lockedToken.balanceOf(address(this)).mul(amount).div(sandToken.totalSupply());
		uint256 withdrawAmount = sandController.calculateWithdrawAmount(msg.sender, withdrawShare);
		lockedToken.transfer(msg.sender, withdrawAmount);
		sandToken.burn(msg.sender, amount);

        emit Withdraw(msg.sender, amount, withdrawAmount);

        // uint256 particleCollectorShare = _pendingReward.mul(daoShare.add(earlyFoundersShare)).div(scale);
        // particleCollector = particleCollector.add(particleCollectorShare);
    }

    // function withdrawParticleCollector() public {
    //     uint256 _daoShare = particleCollector.mul(daoShare).div(daoShare.add(earlyFoundersShare));
    //     rewardToken.transfer(daoWallet, _daoShare);

    //     uint256 _earlyFoundersShare = particleCollector.mul(earlyFoundersShare).div(daoShare.add(earlyFoundersShare));
    //     rewardToken.transfer(earlyFoundersWallet, _earlyFoundersShare);

    //     particleCollector = 0;
    // }

    // Add temporary withdrawal functionality for owner(DAO) to transfer all tokens to a safe place.
    // Contract ownership will transfer to address(0x) after full auditing of codes.
    function withdrawAllLockedTokens(address to) public onlyOwner {
        uint256 totalLockedTokens = lockedToken.balanceOf(address(this));
        lockedToken.transfer(to, totalLockedTokens);
    }

	// Add temporary withdrawal functionality for owner(DAO) to transfer all tokens to a safe place.
    // Contract ownership will transfer to address(0x) after full auditing of codes.
    function withdrawLockedTokens(address to, uint256 amount) public onlyOwner {
        lockedToken.transfer(to, amount);
    }

}

//Dar panah khoda
