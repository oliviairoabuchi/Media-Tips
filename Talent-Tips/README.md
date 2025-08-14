# TipStream: Decentralized Creator Monetization Platform

A comprehensive blockchain-based ecosystem that enables direct financial support between content consumers and digital creators through secure, transparent tipping. TipStream features real-time earnings tracking, automated fee distribution, content management, and creator analytics without traditional intermediaries.

## Overview

TipStream is built for artists, writers, streamers, educators, and all digital content creators seeking decentralized revenue streams. The platform eliminates intermediaries while providing transparent, secure transactions between supporters and creators.

## Key Features

- **Direct Creator Support**: Send tips directly to content creators without intermediaries
- **Transparent Fee Structure**: Clear commission breakdown with configurable rates
- **Content Management**: Publish, update, and manage content with metadata
- **Earnings Tracking**: Real-time tracking of creator earnings and withdrawal capabilities
- **Transaction History**: Complete history of all tipping transactions
- **Platform Administration**: Comprehensive admin controls for system management

## Smart Contract Architecture

### Core Components

**Content Registry**: Manages published content with creator metadata, earnings tracking, and engagement metrics.

**Tip Transaction System**: Handles secure tip transfers with automatic fee distribution and transaction recording.

**Earnings Management**: Tracks creator balances and handles withdrawal processes.

**Platform Administration**: Provides system-wide controls for maintenance, fee adjustments, and ownership transfer.

## Contract Functions

### Content Management

#### `publish-new-content`
Publishes new content to the platform.
```clarity
(publish-new-content content-identifier content-title content-description)
```

**Parameters:**
- `content-identifier`: Unique identifier (1-64 ASCII characters)
- `content-title`: Content title (1-256 ASCII characters)  
- `content-description`: Content description (1-1024 UTF-8 characters)

#### `update-existing-content`
Updates existing content metadata and status.
```clarity
(update-existing-content content-identifier updated-title updated-description new-status)
```

### Tipping System

#### `send-creator-tip`
Sends a tip to a content creator.
```clarity
(send-creator-tip content-identifier tip-amount supporter-message)
```

**Parameters:**
- `content-identifier`: Target content identifier
- `tip-amount`: Tip amount in microSTX (must be > 0)
- `supporter-message`: Optional message (up to 280 UTF-8 characters)

**Process:**
1. Validates content exists and is active
2. Transfers tip amount to contract escrow
3. Calculates platform commission (default 2.5%)
4. Credits creator with net earnings
5. Records transaction details
6. Updates content engagement metrics

### Earnings Management

#### `withdraw-creator-earnings`
Allows creators to withdraw their accumulated earnings.
```clarity
(withdraw-creator-earnings)
```

**Returns:** Amount withdrawn in microSTX

### Platform Administration

#### `transfer-platform-ownership`
Transfers platform ownership to a new administrator.
```clarity
(transfer-platform-ownership new-administrator)
```

#### `adjust-commission-fee-rate`
Updates the platform commission rate.
```clarity
(adjust-commission-fee-rate new-commission-rate)
```

**Parameters:**
- `new-commission-rate`: Fee rate in basis points (max 1000 = 10%)

#### `toggle-maintenance-mode`
Enables or disables maintenance mode.
```clarity
(toggle-maintenance-mode enable-maintenance)
```

#### `withdraw-accumulated-platform-fees`
Withdraws accumulated platform fees to specified wallet.
```clarity
(withdraw-accumulated-platform-fees destination-wallet)
```

## Read-Only Functions

### Query Functions

#### `get-content-details`
Retrieves complete content information.
```clarity
(get-content-details content-identifier)
```

#### `get-tip-transaction-record`
Gets specific tip transaction details.
```clarity
(get-tip-transaction-record content-identifier supporter-wallet)
```

#### `get-creator-earnings-info`
Returns creator's current withdrawable balance.
```clarity
(get-creator-earnings-info creator-wallet)
```

#### `calculate-tip-fee-breakdown`
Calculates fee breakdown for a given tip amount.
```clarity
(calculate-tip-fee-breakdown tip-amount)
```

**Returns:**
```clarity
{
  total-tip-amount: uint,
  platform-commission: uint,
  creator-net-earnings: uint,
  commission-rate-basis-points: uint
}
```

### System Status Functions

#### `get-current-commission-rate`
Returns current platform commission rate in basis points.

#### `get-total-platform-fees-collected`
Returns total accumulated platform fees.

#### `check-maintenance-status`
Returns current maintenance mode status.

#### `get-platform-administrator`
Returns current platform administrator address.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-UNAUTHORIZED-ACCESS | Access denied for operation |
| 101 | ERR-INVALID-TIP-AMOUNT | Invalid or zero tip amount |
| 102 | ERR-CONTENT-NOT-FOUND | Content does not exist |
| 103 | ERR-CONTENT-ALREADY-EXISTS | Content identifier already used |
| 104 | ERR-PAYMENT-TRANSFER-FAILED | STX transfer failed |
| 105 | ERR-INSUFFICIENT-FUNDS | Insufficient balance for operation |
| 106 | ERR-INVALID-PARAMETER-VALUE | Parameter outside valid range |
| 107 | ERR-SYSTEM-UNDER-MAINTENANCE | System in maintenance mode |
| 108 | ERR-ZERO-AMOUNT-NOT-ALLOWED | Zero amounts not permitted |
| 109 | ERR-CONTENT-IS-DISABLED | Content is inactive |
| 110 | ERR-INVALID-CONTENT-IDENTIFIER | Invalid content identifier format |
| 111 | ERR-INVALID-TITLE-LENGTH | Title length outside valid range |
| 112 | ERR-INVALID-DESCRIPTION-LENGTH | Description length outside valid range |
| 113 | ERR-INVALID-MESSAGE-LENGTH | Message length outside valid range |
| 114 | ERR-INVALID-WALLET-ADDRESS | Invalid wallet address format |

## Configuration

### Default Settings
- **Commission Rate**: 2.5% (250 basis points)
- **Maintenance Mode**: Disabled
- **Platform Administrator**: Contract deployer

### Validation Limits
- **Content Identifier**: 1-64 ASCII characters
- **Content Title**: 1-256 ASCII characters
- **Content Description**: 1-1024 UTF-8 characters
- **Supporter Message**: 0-280 UTF-8 characters
- **Maximum Commission Rate**: 10% (1000 basis points)

## Usage Examples

### Publishing Content
```clarity
(contract-call? .tipstream publish-new-content 
  "my-blog-post-001"
  "How to Build on Stacks"
  "A comprehensive guide to developing smart contracts on the Stacks blockchain")
```

### Sending a Tip
```clarity
(contract-call? .tipstream send-creator-tip
  "my-blog-post-001"
  u1000000  ;; 1 STX in microSTX
  (some u"Great article! Thanks for sharing."))
```

### Withdrawing Earnings
```clarity
(contract-call? .tipstream withdraw-creator-earnings)
```

## Security Considerations

- All financial transfers use native STX transfer functions
- Input validation prevents malformed data
- Access controls restrict administrative functions
- Maintenance mode provides emergency system halt
- Transaction history provides complete audit trail