pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20 is IERC20{

    using SafeMath for uint256;

    uint256 totalUnits;
    uint256 cappedLimit;
    string name;
    string symbol;
    uint256 decimal;
    address myAddress;
    mapping (address => uint256) public ledger;  //to keep record of: how many tokens do a particular address own
    mapping (address => mapping(address => uint256)) public allowances;
    mapping (address => uint256) public timeBoundAddress;
    
    constructor() public{
        name="Revolt";
        symbol="RvT";
        decimal=18;
        cappedLimit=100000*(10**decimal); //to set total tokens: totalUnits=totalTokensYouWant*10^decimal; Here, I've capped my token at 0.1 million RvT or 100k RvT	
        totalUnits=50000*(10**decimal); //Setting an initial supply to 50k RvT 
        
        /*Since solidity does not support decimal numbers, so our smallest unit of RvT which is 0.000000000000000001 would be represented as 1,
        and 1 unit of RvT would be represented as 1000000000000000000. (18 zeroes because decimal of RvT is set to 18)
        Basically, actualRvT=amountEntered/10^decimal.*/

        myAddress=msg.sender;
        ledger[myAddress]=totalUnits;   //transfering ownership of all tokens to my address
        emit Transfer(address(this),myAddress,totalUnits);
    }

    modifier OnlyOwner(){
        require(msg.sender==myAddress,"Access denied!");
        _;
    }

    function mintTokens(address adr, uint256 amount) public OnlyOwner returns(bool){
        require(cappedLimit>=totalUnits.add(amount),"Mint amount exceeds Capped limit");
        require(amount > 0, "Amount should be greater than 0");
        require(adr != address(0), "Mint to the zero address");
        ledger[adr]=ledger[adr].add(amount);
        totalUnits=totalUnits.add(amount);
        emit Transfer(address(0),adr,amount);
        return true;
    }

    function timeBound(address adr) public OnlyOwner returns(bool){
        timeBoundAddress[adr]=block.timestamp+30 days;
        return true;
    }

    function totalSupply() external override view returns(uint256){
         return totalUnits;     //it will return total units of my token that currently exists
    }
    
    function balanceOf(address _address) external override view returns(uint256){
        return ledger[_address];  //it will return balance at a particular address
    }
    
    function transfer(address _address, uint256 amount) external override returns(bool){
        //here msg.sender=the one who is transferring tokens & _address = the one who is receiving tokens
        require(msg.sender != address(0),"ERC 20: transfer from the zero address"); 
        require(_address != address(0),"ERC 20: transfer to the zero address");
        require(block.timestamp>timeBoundAddress[_address],"The recipient is under 30 days restriction");
        require(ledger[msg.sender]>=amount,"Not enough tokens");
        ledger[msg.sender]=ledger[msg.sender].sub(amount);       //deducting tokens from sender's address
        ledger[_address]=ledger[_address].add(amount);           //adding tokens to recipient's address
        emit Transfer(msg.sender,_address,amount);
        return true;
    }
    
    function transferFrom(address _sender, address _recipient, uint256 amount) external override returns(bool){
        //here, msg.sender=the one who is transferring tokens to a particular address from someone else's account
        //_sender= the one who has granted access to msg.sender and so tokens will be deducted from its address
        //_recipient=the one who will receive tokens
        require(allowances[_sender][msg.sender]>=amount,"Transfer amount exceeds allowance");
        require(ledger[_sender]>=amount,"Not enough tokens in sender's account");  //to check whether sender(the account from which tokens will be transferred) has enough tokens or not
        require(block.timestamp>timeBoundAddress[_recipient],"The recipient is under 30 days restriction");
        require(_recipient != address(0),"ERC 20: transfer to the zero address");
        allowances[_sender][msg.sender]=allowances[_sender][msg.sender].sub(amount); //it will deduct transferred amount from allowance and then it will update total tokens allowed
        ledger[_sender]=ledger[_sender].sub(amount); 
        ledger[_recipient]=ledger[_recipient].add(amount);
        emit Transfer(_sender,_recipient,amount);
        return true;
    }
    
    function approve(address _spender, uint256 amount) external override returns(bool){
        //here, msg.sender= the one who is granting access & _spender=the one who has been granted access
        require(msg.sender != address(0),"ERC 20: approve from the zero address");
        require(_spender != address(0),"ERC 20: approve to the zero address");
        allowances[msg.sender][_spender]=amount;        //it will grant access to spender to spend certain tokens from sender's(which is granting access) account
        emit Approval(msg.sender,_spender,amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) external override view returns(uint256){
        //here, _owner=the one who has allowed to spend & _spender=the one who is allowed to spend
        return allowances[_owner][_spender]; //it will return the amount of tokens a certain address is allowed to spend from a certain address
    }
}