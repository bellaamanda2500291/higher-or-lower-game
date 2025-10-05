# Higher or Lower Game

A blockchain-based guessing game implemented on the Stacks blockchain using Clarity smart contracts.

## Overview

This project implements a higher/lower guessing game where users predict whether the next random number will be higher or lower than the current one. Correct guessers win half of the contract's prize pool balance.

## Game Mechanics

- Players make predictions (higher or lower) on the next generated number
- Winners receive half of the current contract balance
- The game uses verifiable randomness for fair number generation
- Prize pool is managed automatically by smart contracts

## Smart Contracts

### game-logic-engine
Implements the core game logic including:
- Higher/lower comparison logic
- Winner determination algorithms
- Random number generation and verification
- Game state management

### prize-pool-manager
Manages the financial aspects of the game:
- Prize pool accumulation and distribution
- Winner payout calculations
- Balance tracking and security
- Transaction fee management

## Technology Stack

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity
- **Development Framework**: Clarinet
- **Testing Framework**: Vitest
- **Version Control**: Git

## Development Setup

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Clarity development environment
- Node.js and npm
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd higher-or-lower-game
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run tests:
   ```bash
   clarinet test
   ```

4. Check contract syntax:
   ```bash
   clarinet check
   ```

## Usage

### Local Development

1. Start the Clarinet console:
   ```bash
   clarinet console
   ```

2. Deploy contracts locally:
   ```clarity
   ::deploy_contracts
   ```

3. Interact with the game contracts through the console or tests

### Testing

Run the comprehensive test suite:
```bash
npm test
```

Individual contract testing:
```bash
clarinet test tests/game-logic-engine_test.ts
clarinet test tests/prize-pool-manager_test.ts
```

## Contract Functions

### Game Logic Engine

- `make-prediction(prediction: bool)` - Submit higher/lower prediction
- `generate-next-number()` - Generate next random number
- `determine-winners()` - Calculate game winners
- `get-current-number()` - Get current game number

### Prize Pool Manager

- `get-pool-balance()` - Check current prize pool
- `distribute-winnings(winners: list)` - Pay out winners
- `add-to-pool(amount: uint)` - Add funds to prize pool
- `calculate-payout(winner-count: uint)` - Calculate individual payouts

## Security Features

- Verifiable random number generation
- Secure prize pool management
- Winner verification mechanisms
- Anti-manipulation safeguards

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Run `clarinet check` to verify contract syntax
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Roadmap

- [ ] Basic game logic implementation
- [ ] Prize pool management
- [ ] Random number generation
- [ ] Winner determination
- [ ] Frontend interface
- [ ] Mainnet deployment

## Support

For questions or issues, please open a GitHub issue or contact the development team.