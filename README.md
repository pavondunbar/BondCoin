<p align="center"><img width="684" alt="Screenshot 2025-01-02 at 2 02 46 PM" src="https://github.com/user-attachments/assets/d7c83db1-957d-45eb-b306-0c85368e0b37" /></p>

<p align="center">Image Source: https://medium.com/@0xkryptokeisarii/pump-fun-complete-tutorial-april-2024-282462dc9a9a</p>

## BondCoin Smart Contract
A two-way bonding curve token contract that enables automated market making between BOND tokens and AGC (ArgoCoin). This contract implements a linear pricing curve that increases with supply and provides predictable token pricing. 

Prices go up for each purchase and goes down for each sell. You can rename this token to anything you like and pair it with any native gas token you are willing to accept. It is ideal to deploy this contract to the blockchain that corresponds with the native gas token you wish to accept (I am using Argocoin in this example. Argocoin is the native gas token for Argochain).

# Features:

- ERC20 compliant token (BOND)
- Two-way bonding curve mechanism
- Linear price scaling
- Automated market making
- Reentrancy protection
- Owner-controlled liquidity withdrawal

# Core Functions:

**Pricing and Calculations:**

`getCurrentPrice()`

- Returns the current price of BOND in AGC
- First purchase is always 1:1 (1 AGC = 1 BOND)
- Price increases linearly by 0.05 AGC per token minted

`calculatePurchaseReturn(uint256 agcAmount)`

- Calculates how many BOND tokens you'll receive for a given AGC amount
- First buyer gets 1:1 ratio
- Subsequent purchases use current price for calculation

`calculateSaleReturn(uint256 bondAmount)`

- Calculates how much AGC you'll receive for selling BOND tokens
- Uses current price to determine return amount
- Special handling for complete supply liquidation

**Trading Functions**

`buy()`

- Purchase BOND tokens with AGC
- Automatically calculates token amount based on current price
- Emits price update event
- Requires AGC payment

`sell(uint256 amount)`

- Sell BOND tokens back to the contract
- Receive AGC based on current price
- Requires sufficient contract reserves
- Updates reserve balance after sale

**View Functions**

`getAGCBalance()`

Check contract's AGC balance

`getBONDBalance()`

Check total BOND supply

`getBONDBalanceOf(address account)`

Check BOND balance of any address

**Admin Functions**

`withdrawForLiquidity(uint256 bondAmount, uint256 agcAmount)`

- Owner can withdraw AGC and mint BOND for DEX liquidity
- Requires sufficient balances
- Updates reserve tracking

# Benefits for Users

**Predictable Pricing**

- Know exact price before trading
- Linear price scaling
- No sudden price jumps


**Guaranteed Liquidity**

- Always able to buy tokens
- Always able to sell (if reserves available)
- No need to find counterparty


**Early Adopter Advantage**

- Better prices for early buyers
- Price appreciates with supply
- Natural token value growth


**Transparency**

- All calculations visible on-chain
- Clear price formula
- Real-time price updates


**Security**

- Reentrancy protection
- Balance checks
- Reserve tracking


# Technical Details

- Solidity Version: 0.8.24
- Initial Price: 1 AGC
- Price Increment: 0.05 AGC per token
- Decimal Places: 18

# Usage Example (JavaScript)
```
// Buy BOND tokens
contract.buy({value: ethers.utils.parseEther("1.0")})

// Check current price
const price = await contract.getCurrentPrice()

// Sell BOND tokens
const amount = ethers.utils.parseEther("1.0")
contract.sell(amount)
```

# Important Notes

**Reserve Limitations**

- Sells require sufficient AGC reserves
- Large sells might be limited by available reserves
- Consider reserve levels when trading


**Price Movement**

- Price increases with every purchase
- No price decrease from sales
- Consider timing of trades


**Gas Considerations**

- Buy/sell transactions require gas
- Price calculations are gas-efficient
- Multiple safety checks included


# License
MIT
