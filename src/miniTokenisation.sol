// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Token} from "./tokenFormat.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MiniTokenisationFactory is Ownable {
    error InvalidPropertyId();
    error InvalidPercentage();
    error InvalidValuation();

    uint256 constant TOKEN_PRICE = 2; // for simplicity
    uint256 public nextPropertyId;

    struct Property {
        uint256 id;
        address owner;
        string name;
        uint256 valuation;
        uint256 percentTokenized;
        address tokenAddress;
        uint40 timeOfCreation;
    }

    mapping(uint256 => Property) public propertyIdToPropertyDetails;
    Token[] public deployedTokens;

    event PropertyCreated(
        uint256 indexed propertyId, address indexed owner, string name, address tokenAddress, uint256 totalTokens
    );

    constructor() Ownable(msg.sender) {
        nextPropertyId = 1;
    }

    function createProperty(string memory name, uint256 valuation, uint256 percentTokenized)
        external
        returns (address tokenContract)
    {
        if (percentTokenized = 0 || percentTokenized >= 100) revert InvalidPercentage();
        if (!valuation > 0) revert InvalidValuation();

        uint256 totalTokens = (valuation * percentTokenized) / (TOKEN_PRICE * 100);
        Token newToken = new Token(name, name, msg.sender, totalTokens);
        deployedTokens.push(newToken);
        tokenContract = address(newToken);

        Property memory newProperty = Property({
            id: nextPropertyId,
            owner: msg.sender,
            name: name,
            valuation: valuation,
            percentTokenized: percentTokenized,
            tokenAddress: tokenContract,
            timeOfCreation: uint40(block.timestamp)
        });

        propertyIdToPropertyDetails[nextPropertyId] = newProperty;

        emit PropertyCreated(nextPropertyId, msg.sender, name, tokenContract, totalTokens);

        nextPropertyId += 1;
    }

    // all view functions take no gas so easy display on frontend with repeated calls
    function getProperty(uint256 propertyId) public view returns (Property memory) {
        Property memory property = propertyIdToPropertyDetails[propertyId];
        if (property.id == 0) revert InvalidPropertyId();
        return property;
    }

    function getAllProperties() external view returns (Property[] memory) {
        Property[] memory properties = new Property[](nextPropertyId - 1);
        for (uint256 i = 1; i < nextPropertyId; i++) {
            properties[i - 1] = propertyIdToPropertyDetails[i];
        }
        return properties;
    }

    function getPropertyOwner(uint256 propertyId) external view returns (address) {
        Property memory property = getProperty(propertyId);
        return property.owner;
    }
}
