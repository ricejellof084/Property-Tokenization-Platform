# 🏠 Property Tokenization Platform

A blockchain-based property tokenization platform built on Stacks that enables fractional ownership of real estate through tokenization.

## 🌟 Features

- 🏘️ **Property Registration**: List properties with detailed metadata
- 🪙 **Token Creation**: Generate fractional ownership tokens for properties
- 💰 **Token Trading**: Buy and sell property tokens
- 📊 **Portfolio Tracking**: Monitor ownership percentages and portfolio value
- 🔄 **Token Transfers**: Transfer tokens between users
- ⚙️ **Property Management**: Update pricing and toggle property status
- 💼 **Platform Fees**: Configurable transaction fees

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet)
- Node.js and npm

### Installation
```bash
git clone <repository-url>
cd Property-Tokenization-Platform
npm install
```

### Testing
```bash
clarinet check
npm test
```

## 📋 Contract Functions

### 🏠 Property Management

#### `create-property`
Create a new tokenized property
```clarity
(create-property 
  "123 Main St, City" 
  u1000 
  u100 
  "Beautiful downtown property" 
  "Commercial" 
  u5000 
  u2020)
```

#### `update-property-price`
Update token price per property (owner only)
```clarity
(update-property-price u1 u150)
```

#### `toggle-property-status`
Activate/deactivate property trading (owner only)
```clarity
(toggle-property-status u1)
```

### 💰 Token Operations

#### `purchase-tokens`
Buy property tokens
```clarity
(purchase-tokens u1 u10)
```

#### `transfer-tokens`
Transfer tokens to another user
```clarity
(transfer-tokens u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u5)
```

#### `list-tokens-for-sale`
List tokens for secondary sale
```clarity
(list-tokens-for-sale u1 u5 u120)
```

### 📊 Read Functions

#### `get-property`
Get property details
```clarity
(get-property u1)
```

#### `get-token-balance`
Check token balance for specific property
```clarity
(get-token-balance u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### `calculate-ownership-percentage`
Calculate ownership percentage (basis points)
```clarity
(calculate-ownership-percentage u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### `get-property-value`
Get total property value
```clarity
(get-property-value u1)
```

#### `get-user-portfolio-value`
Get user's total portfolio value
```clarity
(get-user-portfolio-value 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 💳 Fee Structure

- Default platform fee: 2.5% (250 basis points)
- Fees are collected on token purchases
- Only contract owner can modify fees (max 10%)

## 🔐 Security Features

- Owner-only functions for property management
- Input validation for all parameters
- Protection against self-transfers
- Balance checks before transfers
- Active property status verification

## 📝 Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Property not found |
| u102 | Invalid amount |
| u103 | Insufficient balance |
| u104 | Property already exists |
| u105 | Property not active |
| u106 | Invalid price |
| u107 | Cannot transfer to self |

## 🛠️ Development

### Running Tests
```bash
npm test
```

### Contract Deployment
```bash
clarinet deployments generate --devnet
clarinet deployments apply -p devnet
```

## 📈 Usage Examples

### Create and Tokenize Property
```clarity
;; Create property with 1000 tokens at 100 STX each
(contract-call? .Property-Tokenization-Platform create-property 
  "456 Oak Ave" 
  u1000 
  u100 
  "Modern apartment building" 
  "Residential" 
  u8000 
  u2022)
```

### Purchase Fractional Ownership
```clarity
;; Buy 50 tokens (5% ownership if 1000 total tokens)
(contract-call? .Property-Tokenization-Platform purchase-tokens u1 u50)
```

### Transfer Ownership
```clarity
;; Transfer 10 tokens to another user
(contract-call? .Property-Tokenization-Platform transfer-tokens 
  u1 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  u10)
```


## 📄 License

MIT License - see LICENSE file for details

---

