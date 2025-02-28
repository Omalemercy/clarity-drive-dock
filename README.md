# DriveDock
A decentralized carpooling app connecting people within neighborhoods on the Stacks blockchain.

## Features
- Create ride offers with destination, seats available, and pricing
- Book available rides 
- Rate and review drivers and passengers
- View ride history
- Manage user profiles

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Create a ride offer
(contract-call? .drive-dock create-ride u2 "Downtown" u50000 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Book a ride
(contract-call? .drive-dock book-ride u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Rate a completed ride
(contract-call? .drive-dock rate-ride u1 u5 "Great ride!")
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
