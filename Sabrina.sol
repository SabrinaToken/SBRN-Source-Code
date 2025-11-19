// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Sabrina {
    string public constant name = "Sabrina";
    string public constant symbol = "SBRN";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public constant FEE_RECIPIENT = 0xfa5f9F6140C6b824bd624BfE40be8f838d03C7e5;
    uint256 public constant FEE_PERCENT = 24; 
    uint256 private constant PERCENT_DIVISOR = 1000000;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address recipient) {
        uint256 initialSupply = 18000000 * 10**decimals;
        _mint(recipient, initialSupply);
    }

    function _update(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            _mint(to, value);
            return;
        }

        if (to == address(0)) {
            _burn(from, value);
            return;
        }

        uint256 fee = (value * FEE_PERCENT) / PERCENT_DIVISOR;
        uint256 feeToRecipient = fee / 2;
        uint256 feeToBurn = fee - feeToRecipient; // handles odd numbers

        uint256 amountAfterFee = value - fee;
        require(balanceOf[from] >= value, "Insufficient balance");

        // Deduct full amount
        balanceOf[from] -= value;

        // --- 50% SEND FEE ---
        if (feeToRecipient > 0) {
            balanceOf[FEE_RECIPIENT] += feeToRecipient;
            emit Transfer(from, FEE_RECIPIENT, feeToRecipient);
        }

        // --- 50% BURN FEE ---
        if (feeToBurn > 0) {
            totalSupply -= feeToBurn;
            emit Transfer(from, address(0), feeToBurn);
        }

        // --- TRANSFER REMAINDER ---
        balanceOf[to] += amountAfterFee;
        emit Transfer(from, to, amountAfterFee);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _update(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 permitted = allowance[from][msg.sender];
        require(permitted >= value, "Allowance too low");

        allowance[from][msg.sender] = permitted - value;
        emit Approval(from, msg.sender, allowance[from][msg.sender]);

        _update(from, to, value);
        return true;
    }

    // --- Burning like ERC20Burnable ---
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) external {
        uint256 permitted = allowance[from][msg.sender];
        require(permitted >= value, "Allowance too low");

        allowance[from][msg.sender] = permitted - value;
        emit Approval(from, msg.sender, allowance[from][msg.sender]);

        _burn(from, value);
    }

    function _mint(address to, uint256 value) internal {
        require(to != address(0), "Mint to zero");

        totalSupply += value;
        balanceOf[to] += value;

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(balanceOf[from] >= value, "Burn exceeds balance");

        balanceOf[from] -= value;
        totalSupply -= value;

        emit Transfer(from, address(0), value);
    }
}