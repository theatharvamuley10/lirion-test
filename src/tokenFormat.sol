// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    error CooldownPeriodNotOver();

    uint256 public immutable timeOfCreation;
    uint256 public constant COOLDOWN_PERIOD = 180 days;
    bool public paused;

    event EmergencyPaused(address indexed by, uint256 timestamp);
    event EmergencyUnpaused(address indexed by, uint256 timestamp);

    modifier whenNotPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }

    constructor(string memory name, string memory symbol, address ownerOfProperty, uint256 totalSupply)
        ERC20(name, string.concat(symbol, "TKN"))
        Ownable(ownerOfProperty)
    {
        timeOfCreation = block.timestamp;
        _mint(ownerOfProperty, totalSupply);
    }

    function transfer(address to, uint256 value) public override whenNotPaused returns (bool) {
        if ((block.timestamp - timeOfCreation) < COOLDOWN_PERIOD) {
            revert CooldownPeriodNotOver();
        }
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override whenNotPaused returns (bool) {
        if ((block.timestamp - timeOfCreation) < COOLDOWN_PERIOD) {
            revert CooldownPeriodNotOver();
        }
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    // Returns days remaining until cooldown period is over
    function daysRemaining() external view returns (uint256) {
        uint256 elapsed = block.timestamp - timeOfCreation;
        if (elapsed >= COOLDOWN_PERIOD) {
            return 0;
        }
        return (COOLDOWN_PERIOD - elapsed) / 1 days;
    }

    // Check if cooldown period is over
    function isCooldownOver() external view returns (bool) {
        return (block.timestamp - timeOfCreation) >= COOLDOWN_PERIOD;
    }

    function emergencyPause() external onlyOwner {
        paused = true;
        emit EmergencyPaused(msg.sender, block.timestamp);
    }

    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused(msg.sender, block.timestamp);
    }
}
