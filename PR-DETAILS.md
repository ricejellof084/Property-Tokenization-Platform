# Property Auction System

## Overview
Added comprehensive auction functionality to the Property Tokenization Platform, enabling property owners to sell their entire properties through competitive bidding. This feature enhances the platform by providing a decentralized marketplace for complete property sales.

## Technical Implementation

### New Data Structures
- **`property-auctions`**: Maps auction IDs to auction details including property ID, seller, bidding information, and status
- **`auction-bids`**: Records all bids placed on auctions for transparent bid tracking
- **`next-auction-id`**: Auto-incrementing counter for unique auction identifiers

### Key Functions Added

#### Auction Management
- **`create-property-auction`**: Property owners can create time-limited auctions with starting prices
- **`cancel-auction`**: Sellers can cancel auctions that have no bids
- **`end-auction`**: Mark auctions as ended when duration expires
- **`settle-auction`**: Transfer property ownership and payments after auction completion

#### Bidding System  
- **`place-bid`**: Users can place bids with automatic refund of previous highest bidder
- **`get-auction`**: Retrieve auction details and current status
- **`get-auction-bid`**: View specific bid information

### Enhanced Error Handling
Added 7 new error constants for auction-specific scenarios:
- `ERR_AUCTION_NOT_FOUND` (u110)
- `ERR_AUCTION_ENDED` (u111)
- `ERR_AUCTION_NOT_ENDED` (u112)
- `ERR_BID_TOO_LOW` (u113)
- `ERR_AUCTION_ACTIVE` (u114)
- `ERR_NOT_HIGHEST_BIDDER` (u115)
- `ERR_NO_BIDS` (u116)

### Security Features
- Property ownership verification for auction creation
- Prevention of self-bidding by sellers
- Automatic bid refunds to prevent fund locking
- Complete property token transfer to auction winners
- Platform fee collection on successful sales

## Testing & Validation
- ✅ Contract passes `clarinet check` with Clarity v3 compliance
- ✅ Comprehensive test suite covering auction workflows
- ✅ CI/CD pipeline configured with GitHub Actions
- ✅ Error scenarios properly tested and handled
- ✅ Line endings normalized (CRLF → LF) for cross-platform compatibility

## Usage Examples

### Creating an Auction
```clarity
;; Create 7-day auction with 50,000 STX starting price
(contract-call? .Property-Tokenization-Platform create-property-auction 
  u1 u50000 u1008)  ;; property-id, starting-price, duration-blocks
```

### Placing Bids
```clarity
;; Place bid of 55,000 STX on auction #1
(contract-call? .Property-Tokenization-Platform place-bid u1 u55000)
```

### Settling Auctions
```clarity
;; End and settle auction after duration expires
(contract-call? .Property-Tokenization-Platform end-auction u1)
(contract-call? .Property-Tokenization-Platform settle-auction u1)
```

## Impact
This feature transforms the platform from a fractional ownership system into a complete property marketplace, enabling:
- Full property sales through transparent auctions
- Competitive price discovery through bidding
- Automated settlement and ownership transfers
- Enhanced platform utility and revenue through auction fees

The auction system is fully independent, requiring no modifications to existing property tokenization functionality while seamlessly integrating with the current architecture.