# OKX.fun - The Premier Meme Token Launchpad on X Layer

## 🚀 Overview

**OKX.fun** is a revolutionary Pump.fun-style meme token launchpad exclusively built on **X Layer** - OKX's cutting-edge zkEVM Layer 2 network. Leveraging the power of zero-knowledge rollup technology, OKX.fun delivers lightning-fast transactions with minimal fees while maintaining Ethereum-level security.

### 🌐 Powered by X Layer (OKX zkEVM L2)
X Layer is OKX's revolutionary Layer 2 scaling solution that brings:
- **100x lower fees** than Ethereum mainnet
- **Sub-second transaction finality**
- **Full EVM compatibility**
- **Enterprise-grade security** backed by OKX
- **Seamless bridge** to Ethereum and other chains

Built on Polygon CDK technology, X Layer represents the future of DeFi scalability, making OKX.fun the fastest and most cost-effective meme token launchpad in the ecosystem.

## 🌟 Key Features

### 1. **Instant Token Creation**
- One-click token deployment with customizable parameters
- Small fee in OKB for minting new tokens
- No coding required - fully automated smart contract deployment
- Support for custom tokenomics and metadata

### 2. **Bonding Curve Mechanism**
- Automated Market Maker (AMM) with mathematical price discovery
- Progressive price increases as tokens are purchased
- Built-in liquidity accumulation
- Fair launch mechanism preventing rugpulls

### 3. **OKB Pool System**
- Automated liquidity pooling in OKB
- 80 OKB threshold for DEX migration
- 36 OKB permanently locked as base liquidity (45% of pool)
- Remaining liquidity for active trading

### 4. **DEX Integration**
- Seamless migration to OKX DEX/Uniswap V3
- Automated liquidity provision
- Concentrated liquidity positions for optimal capital efficiency
- Real-time price feeds and slippage protection

### 5. **Revenue Distribution**
- Platform fee: 2% of transactions
- Creator rewards: 1% lifetime trading fees
- Referral system: 0.5% for successful referrals
- DAO treasury allocation for future development

## 🏗️ Architecture on X Layer

```
┌─────────────────────────────────────────────────┐
│              OKX.fun Frontend                   │
│           (Next.js + TypeScript + Web3)         │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│         OKX.fun Smart Contracts                 │
│                                                  │
│  ┌─────────────┐  ┌──────────────┐             │
│  │TokenFactory │  │BondingCurve  │             │
│  └─────────────┘  └──────────────┘             │
│                                                  │
│  ┌─────────────┐  ┌──────────────┐             │
│  │ OKBPool     │  │DEXIntegrator │             │
│  └─────────────┘  └──────────────┘             │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│            X Layer (OKX zkEVM L2)               │
│         Polygon CDK + ZK Rollup Tech            │
│              Chain ID: 196                      │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│             Ethereum Mainnet                    │
│         (Security & Data Availability)          │
└─────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- Node.js v18+ and npm/yarn
- Git
- MetaMask or OKX Wallet
- OKB tokens for deployment and testing

## 🔧 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/okx-fun.git
cd okx-fun
```

### 2. Install Dependencies

#### Smart Contracts
```bash
cd contracts
npm install
```

#### Frontend
```bash
cd ../frontend
npm install
```

### 3. Environment Configuration

Create `.env` files in both directories:

#### contracts/.env
```env
PRIVATE_KEY=your_private_key_here
X_LAYER_RPC=https://rpc.xlayer.tech
ETHERSCAN_API_KEY=your_etherscan_api_key
```

#### frontend/.env.local
```env
NEXT_PUBLIC_RPC_URL=https://rpc.xlayer.tech
NEXT_PUBLIC_CHAIN_ID=196
NEXT_PUBLIC_TOKEN_FACTORY_ADDRESS=0x...
NEXT_PUBLIC_BONDING_CURVE_ADDRESS=0x...
NEXT_PUBLIC_OKB_POOL_ADDRESS=0x...
NEXT_PUBLIC_DEX_INTEGRATOR_ADDRESS=0x...
```

## 🚀 Deployment

### Smart Contracts Deployment

1. **Compile Contracts**
```bash
cd contracts
npx hardhat compile
```

2. **Run Tests**
```bash
npx hardhat test
```

3. **Deploy to Testnet**
```bash
npx hardhat run scripts/deploy.js --network xlayer-testnet
```

4. **Verify Contracts**
```bash
npx hardhat verify --network xlayer-testnet DEPLOYED_CONTRACT_ADDRESS
```

### Frontend Deployment

1. **Development Mode**
```bash
cd frontend
npm run dev
```

2. **Production Build**
```bash
npm run build
npm run start
```

3. **Deploy to Vercel/Netlify**
```bash
# Vercel
vercel --prod

# Netlify
netlify deploy --prod
```

## 💰 Tokenomics

### Fee Structure
- **Token Creation Fee**: 0.1 OKB
- **Trading Fee**: 1% (0.5% to liquidity, 0.3% to creator, 0.2% to platform)
- **Early Exit Tax**: 5% (first 24 hours) to prevent pump & dump

### Bonding Curve Formula
```
Price = k * (Supply)^n
where:
- k = initial price constant (0.0001 OKB)
- n = curve steepness (1.5)
- Supply = current token supply
```

## 🔐 Security Features

- ✅ Audited smart contracts
- ✅ Multi-signature treasury
- ✅ Time-locked liquidity
- ✅ Anti-bot measures (max transaction size, cooldown periods)
- ✅ Slippage protection
- ✅ Reentrancy guards
- ✅ Emergency pause mechanism

## 📊 Platform Statistics

| Metric | Value |
|--------|-------|
| Total Tokens Launched | 0 |
| Total Value Locked (TVL) | 0 OKB |
| 24h Trading Volume | 0 OKB |
| Active Users | 0 |
| Platform Revenue | 0 OKB |

## 🛣️ Roadmap

### Phase 1: Launch (Q1 2025)
- ✅ Smart contract development
- ✅ Frontend implementation
- ✅ Testnet deployment
- ⏳ Security audit
- ⏳ Mainnet launch

### Phase 2: Enhancement (Q2 2025)
- [ ] Mobile app development
- [ ] Advanced charting tools
- [ ] Social features (comments, likes)
- [ ] NFT integration

### Phase 3: Expansion (Q3 2025)
- [ ] Cross-chain support
- [ ] Governance token launch
- [ ] DAO formation
- [ ] Partner integrations

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Discord**: [Join our community](https://discord.gg/okxfun)
- **Twitter**: [@OKXfun](https://twitter.com/okxfun)
- **Telegram**: [t.me/okxfun](https://t.me/okxfun)
- **Email**: support@okx.fun
- **Documentation**: [docs.okx.fun](https://docs.okx.fun)
- **X Layer Docs**: [www.okx.com/xlayer](https://www.okx.com/xlayer)

## ⚠️ Disclaimer

This platform is experimental software. Use at your own risk. Always do your own research before investing in any tokens. The creators are not responsible for any losses incurred through the use of this platform.

## 🙏 Acknowledgments

- **OKX Team** for pioneering X Layer zkEVM technology
- **Polygon Labs** for CDK infrastructure
- **OpenZeppelin** for secure contract libraries
- **Uniswap** for DEX integration protocols
- **Pump.fun** for proving the bonding curve model

## 🔗 Important Links

- **X Layer Explorer**: [www.okx.com/explorer/xlayer](https://www.okx.com/explorer/xlayer)
- **X Layer Bridge**: [www.okx.com/xlayer/bridge](https://www.okx.com/xlayer/bridge)
- **OKX Wallet**: [www.okx.com/web3/wallet](https://www.okx.com/web3/wallet)
- **X Layer Faucet**: [www.okx.com/xlayer/faucet](https://www.okx.com/xlayer/faucet)

---

**🚀 OKX.fun - Where Memes Meet zkEVM Innovation on X Layer**

*Built exclusively for the X Layer ecosystem - The future of scalable DeFi*