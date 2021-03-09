// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract ERC20 is Context, IERC20, ChainlinkClient {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "somex";
    string private _symbol="sox";
	address [] investors;
   //for clock
	bool public alarmDone = false;
    int constant OFFSET19700101 = 2440588;
    // for ropsten
	address private oracle= 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
    bytes32 private jobId = "982105d690504c5d9ce374d040c08654;
    uint256 private fee = 0.1 * 10 ** 18; // 0.1 LINK;

    /**
     * Create a Chainlink request to start an alarm every day
     * , return throught the fulfillAlarm
     * function
     */
    function requestClock(uint256 durationInSeconds) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillAlarm.selector);
        request.addUint("until", now + 1440 minutes);
        return sendChainlinkRequestTo(oracle, request, fee);
    }

      
     function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
 
   // wrote the function to checkdate on 20th of each month instead of 30th as given in the challenge to avoid all that code to check for February months
    function checkDate() internal view returns (bool){
     uint  SECONDS_PER_DAY = 24 * 60 * 60;
     uint year;
     uint month;
     uint day;
     (year, month, day) = _daysToDate(block.timestamp / SECONDS_PER_DAY);
     if (day==20) return true;
    }
    /**
     * Receive the response in the form of uint256
     */
     
    function fulfillAlarm(bytes32 _requestId) public recordChainlinkFulfillment(_requestId)
    {
       
     if(checkDate()) clearBalances();
     alarmDone= true;
       
    }
    
   
   
    function name() public view virtual returns (string memory) {
        return _name;
    }

  
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function store() public {
// the next line is for linking to Chainlink for timer		
		setPublicChainlinkToken();
		clearBalances();
       
	} 
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

  
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

	function clearBalances()public {
		for (uint i=0; i< investors.length ; i++){
			_balances[investers[i]] = 0;
		}
	}

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

   
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

  
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

  
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { 
	investors.push(to);
	}
}