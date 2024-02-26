// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OptionsTradingInterface is Ownable {
    IERC20 public token;

    struct Option {
        address buyer;
        uint256 amount;
        uint256 strikePrice;
        uint256 expiryDate;
        bool exercised;
    }

    Option[] public options;

    mapping(address => uint256) public balances;

    event OptionPurchased(address indexed buyer, uint256 amount, uint256 strikePrice, uint256 expiryDate);

    event OptionExercised(address indexed buyer, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function purchaseOption(uint256 _amount, uint256 _strikePrice, uint256 _expiryDate) external {
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(token.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");

        token.transferFrom(msg.sender, address(this), _amount);
        options.push(Option(msg.sender, _amount, _strikePrice, _expiryDate, false));
        
        emit OptionPurchased(msg.sender, _amount, _strikePrice, _expiryDate);
    }

    function exerciseOption(uint256 _index) external {
        require(_index < options.length, "Invalid index");
        Option storage option = options[_index];
        require(msg.sender == option.buyer, "You are not the buyer");
        require(block.timestamp < option.expiryDate, "Option expired");
        require(!option.exercised, "Option already exercised");
        
        option.exercised = true;
        require(token.balanceOf(address(this)) >= option.amount, "Not enough tokens to exercise option");

        uint256 currentPrice = 1; // Assuming a hypothetical current price for demonstration; replace with actual pricing mechanism
        uint256 profit = (currentPrice > option.strikePrice) ? (currentPrice - option.strikePrice) * option.amount : 0;
        require(profit > 0, "No payoff");
        balances[msg.sender] += profit;

        emit OptionExercised(msg.sender, profit);
    }

    function withdraw() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to withdraw");

        balances[msg.sender] = 0;
        token.transfer(msg.sender, balance);
    }
}