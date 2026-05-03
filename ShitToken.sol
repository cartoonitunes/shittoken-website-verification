// Submitted by EthereumHistory (ethereumhistory.com)
pragma solidity ^0.4.11;

library SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ShitToken {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public INITIAL_SUPPLY;
    address public ShitCoinGod;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function ShitToken() {
        name = "ShitToken";
        symbol = "SHIT";
        decimals = 18;
        INITIAL_SUPPLY = 151 * 10**18;
        totalSupply = INITIAL_SUPPLY;
        ShitCoinGod = msg.sender;
        balances[ShitCoinGod] = INITIAL_SUPPLY;
    }

    function () payable {
        require(msg.value > 0);
        uint256 amount = msg.value;
        uint256 tokens = amount.safeMul(10);
        require(tokens <= balances[ShitCoinGod]);
        allowed[ShitCoinGod][msg.sender] = tokens;
        transferFrom(ShitCoinGod, msg.sender, tokens);
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].safeAdd(_value);
        balances[_from] = balances[_from].safeSub(_value);
        allowed[_from][msg.sender] = _allowance.safeSub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function claimMoney() {
        require(msg.sender == ShitCoinGod);
        ShitCoinGod.transfer(this.balance);
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        balances[msg.sender] = balances[msg.sender].safeSub(_value);
        balances[_to] = balances[_to].safeAdd(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
