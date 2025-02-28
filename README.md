# ZenTrek
A decentralized mindfulness app that pairs nature sounds with daily breathing exercises on the Stacks blockchain.

## Features
- Create and manage breathing exercise sessions
- Store and access nature sound assets
- Track user session history and achievements
- Reward system with mindfulness tokens

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract 
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Start a new breathing session
(contract-call? .zentrek start-session 'meditation-01 'ocean-waves u300)

;; Complete a session and earn rewards
(contract-call? .zentrek complete-session 'session-id)

;; Get user stats
(contract-call? .zentrek get-user-stats tx-sender)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
