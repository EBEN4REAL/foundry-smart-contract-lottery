
````
# 🎟️ Chainlink VRF Raffle – Foundry Smart Contract Project

A decentralized **Raffle (lottery)** smart contract built in **Solidity (0.8.19)** and powered by **Chainlink VRF v2+** to ensure verifiable on-chain randomness.  
The project uses the **Foundry** toolchain for rapid development, testing, and deployment.

---

## 💡 Features

- Anyone can enter the raffle by sending ETH using `enterRaffle()`
- Uses **Chainlink Automation (Keepers)** for autonomous winner selection
- Integrates **Chainlink VRF** for secure, tamper-proof random number generation
- Automatically transfers accumulated ETH balance to the selected winner
- Implements the Solidity CEI pattern (Checks → Effects → Interactions) for safe design

---

## 🛠️ Tech Stack

| Layer      | Tools / Services                          |
|-----------|--------------------------------------------|
| Language   | Solidity `^0.8.19`                         |
| Framework  | Foundry (`forge`, `cast`, `anvil`)         |
| Randomness | Chainlink VRF v2+                          |
| Automation | Chainlink Keepers                          |

---

## 🚀 Getting Started

### 1️⃣ Clone & Install Foundry

```bash
git clone <repo-url>
cd <project>
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge --version
````

### 2️⃣ Install Dependencies

```bash
forge install
```

### 3️⃣ Configure Environment

Create a `.env` file:

```dotenv
PRIVATE_KEY=0xabc123...
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/...
ETHERSCAN_API_KEY=XYZ
CHAINLINK_SUBSCRIPTION_ID=1234
VRF_COORDINATOR=0x...
GAS_LANE=0x...                     # keyHash
CALLBACK_GAS_LIMIT=500000
INTERVAL=300                       # seconds
ENTRANCE_FEE=10000000000000000     # 0.01 ETH
```

### 4️⃣ Deploy to Sepolia

```bash
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### 5️⃣ Enter the Raffle

```bash
cast send <raffle_contract_address> \
  "enterRaffle()" \
  --value 0.01ether \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL
```

---

## 📄 Contract Overview

| Function               | Description                                                   |
| ---------------------- | ------------------------------------------------------------- |
| `enterRaffle()`        | Allows a user to enter the raffle by sending ETH              |
| `checkUpkeep()`        | Keeper check to determine if a draw should run                |
| `performUpkeep()`      | Requests a random number from Chainlink VRF                   |
| `fulfillRandomWords()` | Chainlink callback → selects a winner & transfers the balance |

---

## ✍️ Author

**Ebenezer Igbinoba**
[https://github.com/eben4real](https://github.com/eben4real)
