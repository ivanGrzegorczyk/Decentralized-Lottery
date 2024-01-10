# Decentralized Lottery

## Overview
Decentralized Lottery is a project created to explore and showcase the implementation of a decentralized lottery system on the Ethereum blockchain. This project is based on the learnings from Patrick Collins' course, incorporating key concepts and best practices in decentralized application development.

It utilizes the Foundry framework for efficient and secure smart contract development and testing.

## Features
* Decentralization: Built on the Ethereum blockchain, ensuring transparency and fairness in the lottery process.
* Smart Contracts: Leveraging the power of smart contracts using the Foundry framework for automated and secure lottery operations.

## How it Works
1. **Raffle Purchase**
Users can participate in the lottery by purchasing raffles. Each raffle serves as an entry into the drawing, and users can buy as many raffles as they desire. The value of each raffle contributes to the total jackpot amount.

2. **Jackpot Accumulation**
The total value of all purchased raffles accumulates to form the jackpot.

3. **Lottery Conclusion**
Chainlink Automation is employed to automate the finalization of the lottery. This ensures a seamless and secure execution of the lottery conclusion process, distributing the accumulated jackpot to the winning participant.

4. **Random Winner Selection**
To ensure a fair and random selection of the winner, the lottery system integrates Chainlink VRF (Verifiable Random Function). This decentralized oracle service provides a tamper-proof source of randomness, guaranteeing an unbiased selection process. 

## Disclaimer
This project is developed for educational and portfolio purposes and is not intended for production use. It is based on the learnings from Patrick Collins' course on decentralized application development.
