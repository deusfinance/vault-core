//Be name khoda

pragma solidity >=0.6.0 <0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract FeeCalculator is Ownable{

	using SafeMath for uint256;

	uint256 public coefficient;
	uint256 public scale = 1e18;
	uint256 public constantFee;

	constructor(uint256 _coefficient, uint256 _constantFee) public{
		coefficient = _coefficient;
		constantFee = _constantFee;
	}

	function changeFee (uint256 _coefficient, uint256 _constantFee) public onlyOwner{
        coefficient = _coefficient;
		constantFee = _constantFee;
    }

	function calculateFee(address to, address from, uint256 amount) public view returns (uint256){
		return coefficient.mul(amount).div(scale).add(constantFee);
	}

	function calculateTransferFromFee(address to, address from, uint256 amount, address spender) public view returns (uint256){
		return coefficient.mul(amount).div(scale).add(constantFee);
	}
}

contract TransferController{

	constructor() public{}
	
	function beforeTokenTransfer(address from, address to, uint256 value) public{}
}

contract SandToken is ERC20, AccessControl{

    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
	bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

	TransferController public transferController;
	FeeCalculator public feeCalculator;
	address public feeCollector;

    constructor(
		string memory name,
		string memory symbol,
		address _feeCalculator,
		address _feeCollector,
		address admin) 
		public ERC20(name, symbol) {
			_setupRole(DEFAULT_ADMIN_ROLE, admin);
			_setupRole(CONFIG_ROLE, admin);
			_setupRole(MINTER_ROLE, msg.sender);
			_setupRole(BURNER_ROLE, msg.sender);

			transferController = new TransferController();
			feeCalculator = FeeCalculator(_feeCalculator);
			feeCollector = _feeCollector;
    }

	function setTransferController(address _transferController) public{
		require(hasRole(CONFIG_ROLE, msg.sender), "Caller is not a configer");
		transferController = TransferController(_transferController);
	}

	function setFeeCalculator(address _feeCalculator) public{
		require(hasRole(CONFIG_ROLE, msg.sender), "Caller is not a configer");
		feeCalculator = FeeCalculator(_feeCalculator);
	}

	function setFeeCollector(address _feeCollector) public{
		require(hasRole(CONFIG_ROLE, msg.sender), "Caller is not a configer");
		feeCollector = _feeCollector;
	}

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
		uint256 feeAmount = feeCalculator.calculateFee(recipient, msg.sender, amount);
		super.transfer(feeCollector, feeAmount);
        return super.transfer(recipient, amount.sub(feeAmount));
    }

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		uint256 feeAmount = feeCalculator.calculateTransferFromFee(sender, recipient, amount, msg.sender);
		_transfer(sender, feeCollector, feeAmount);
        _transfer(sender, recipient, amount.sub(feeAmount));
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

	function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override {
        transferController.beforeTokenTransfer(from, to, value);
        super._beforeTokenTransfer(from, to, value);
    }

}

//Dar panah khoda
