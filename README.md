# EMR-Security-Application

This project is a personal academic exercise to explore the use of blockchain technology for securely storing and managing Electronic Medical Records (EMR). The system encodes EMR data into shares, stores them on the blockchain, and retrieves them as needed. The frontend is built with Streamlit, and the backend uses Solidity for the smart contract deployed on the Ethereum blockchain (simulated with Ganache).

## Features

- **Upload EMR:** Encode and store EMR data on the blockchain securely.
- **Update EMR:** Update existing EMR records with new data and track changes.
- **Retrieve EMR Data:** Fetch and decode EMR data from the blockchain using shares.
- **View EMR History:** Track the history of changes to an EMR, including timestamps and block numbers.

## Getting Started

### Prerequisites

- Python 3.x
- Node.js and npm
- Ganache
- MetaMask or any Ethereum wallet
- Streamlit

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/Mridul-Dixit/EMR-Security-Application.git
    cd emr-blockchain-interface
    ```

2. Install the dependencies:
    ```sh
    pip install -r requirements.txt
    npm install -g truffle
    ```

3. Start Ganache and configure your local blockchain.

4. Compile and deploy the smart contract:
    ```sh
    truffle compile
    truffle migrate
    ```

5. Update the contract address in your Python script (`app.py`) with the address from the migration output.

6. Run the Streamlit application:
    ```sh
    streamlit run app.py
    ```

## Usage

- Open the Streamlit interface in your browser.
- Select the desired task: Upload EMR, Update EMR, Get EMR Data, or Get EMR History.
- Follow the prompts to perform the task.

## Smart Contract Details

- **Contract Name:** EMR_Security
- **Functions:**
  - `uploadEMR(string memory emr, uint t) public returns (uint256 emrID, uint256 blockNumber)`
  - `updateEMR(uint256 emrID, uint256[] memory shares, string memory changeData, string memory changeMessage) public returns (uint256 updatedEmrID, uint256 blockNumber)`
  - `getEMRData(uint256[] memory shares, uint256 EMR_id) public view returns (string memory)`
  - `getEMRHistory(uint256 emrID) public view returns (string[] memory history, uint256[] memory timestamps, uint256[] memory blocks)`

