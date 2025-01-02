// THIS CONTRACT USES A LOGARITHMIC BONDING CURVE
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BondCoin is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant PRECISION = 1e18;
    uint256 public constant INITIAL_PRICE = 1e18; // 1 AGC
    uint256 public constant BASE_FACTOR = 1e18; // Log base multiplier
    uint256 public constant PRICE_FACTOR = 5e17; // 0.5 - Controls steepness of curve
    
    uint256 public reserveBalance;
    bool private firstBuyExecuted;
    
    event PriceUpdate(uint256 newPrice);
    
    constructor() ERC20("BondCoin", "BOND") Ownable(msg.sender) {
        firstBuyExecuted = false;
    }

    function getAGCBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getBONDBalance() public view returns (uint256) {
        return totalSupply();
    }
    
    function getBONDBalanceOf(address account) public view returns (uint256) {
        return balanceOf(account);
    }

    // Natural log approximation using binary search
    function ln(uint256 x) internal pure returns (uint256) {
        require(x > 0, "Input must be positive");
        
        if (x == PRECISION) return 0;
        
        uint256 left = 0;
        uint256 right = 100 * PRECISION; // Maximum reasonable value
        
        // Binary search for 50 iterations
        for (uint256 i = 0; i < 50; i++) {
            uint256 mid = (left + right) / 2;
            
            // Calculate e^mid using Taylor series
            uint256 emid = exp(mid);
            
            if (emid == x) {
                return mid;
            } else if (emid < x) {
                left = mid;
            } else {
                right = mid;
            }
        }
        
        return left; // Return best approximation
    }

    // Taylor series approximation of e^x
    function exp(uint256 x) internal pure returns (uint256) {
        uint256 result = PRECISION;
        uint256 term = PRECISION;
        
        for (uint256 i = 1; i <= 10; i++) {
            term = (term * x) / (i * PRECISION);
            result += term;
        }
        
        return result;
    }

    function getCurrentPrice() public view returns (uint256) {
        if (!firstBuyExecuted || totalSupply() == 0) {
            return INITIAL_PRICE;
        }

        uint256 supply = totalSupply();
        // Price = INITIAL_PRICE + PRICE_FACTOR * ln(supply / PRECISION + 1)
        uint256 normalizedSupply = (supply * PRECISION) / PRECISION + PRECISION;
        uint256 logComponent = ln(normalizedSupply);
        return INITIAL_PRICE + (PRICE_FACTOR * logComponent) / PRECISION;
    }

    function calculatePurchaseReturn(uint256 agcAmount) public view returns (uint256) {
        require(agcAmount > 0, "Amount must be greater than 0");
        
        // First buy is 1:1
        if (!firstBuyExecuted) {
            return agcAmount;
        }
        
        // For subsequent purchases, use current price
        uint256 currentPrice = getCurrentPrice();
        return (agcAmount * PRECISION) / currentPrice;
    }

    function calculateSaleReturn(uint256 bondAmount) public view returns (uint256) {
        require(bondAmount > 0, "Amount must be greater than 0");
        uint256 supply = totalSupply();
        require(bondAmount <= supply, "Exceeds supply");
        
        // If selling would bring supply to 0, use 1:1 ratio
        if (bondAmount == supply) {
            return bondAmount;
        }
        
        // Calculate return based on current price
        uint256 currentPrice = getCurrentPrice();
        return (bondAmount * currentPrice) / PRECISION;
    }

    function buy() external payable nonReentrant {
        require(msg.value > 0, "Must send AGC");
        
        uint256 tokensToMint = calculatePurchaseReturn(msg.value);
        require(tokensToMint > 0, "Cannot purchase 0 tokens");
        
        reserveBalance += msg.value;
        _mint(msg.sender, tokensToMint);
        
        if (!firstBuyExecuted) {
            firstBuyExecuted = true;
        }
        
        emit PriceUpdate(getCurrentPrice());
    }

    function sell(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        uint256 agcReturn = calculateSaleReturn(amount);
        require(agcReturn <= address(this).balance, "Insufficient reserve balance");
        
        _burn(msg.sender, amount);
        
        (bool success, ) = msg.sender.call{value: agcReturn}("");
        require(success, "AGC transfer failed");
        
        // Update reserve balance after successful transfer
        reserveBalance = address(this).balance;
        
        emit PriceUpdate(getCurrentPrice());
    }

    function withdrawForLiquidity(uint256 bondAmount, uint256 agcAmount) external onlyOwner {
        require(bondAmount <= totalSupply(), "Insufficient BOND balance");
        require(agcAmount <= address(this).balance, "Insufficient AGC balance");
        require(agcAmount <= reserveBalance, "Exceeds reserve balance");
        
        reserveBalance -= agcAmount;
        _mint(msg.sender, bondAmount);
        
        (bool success, ) = msg.sender.call{value: agcAmount}("");
        require(success, "AGC withdrawal failed");
    }

    receive() external payable {
        revert("Use buy() to purchase tokens");
    }

    fallback() external payable {
        revert("Use buy() to purchase tokens");
    }
}
