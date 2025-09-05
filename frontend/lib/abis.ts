// Smart Contract ABIs for OKX DeFi Platform

export const TOKEN_FACTORY_ABI = [
  {
    "inputs": [
      {"name": "name", "type": "string"},
      {"name": "symbol", "type": "string"},
      {"name": "description", "type": "string"},
      {"name": "imageUrl", "type": "string"},
      {"name": "initialSupply", "type": "uint256"}
    ],
    "name": "createToken",
    "outputs": [{"name": "tokenAddress", "type": "address"}],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [{"name": "tokenAddress", "type": "address"}],
    "name": "getTokenInfo",
    "outputs": [
      {"name": "name", "type": "string"},
      {"name": "symbol", "type": "string"},
      {"name": "description", "type": "string"},
      {"name": "imageUrl", "type": "string"},
      {"name": "creator", "type": "address"},
      {"name": "totalSupply", "type": "uint256"},
      {"name": "marketCap", "type": "uint256"},
      {"name": "graduatedToDEX", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const

export const BONDING_CURVE_ABI = [
  {
    "inputs": [
      {"name": "tokenAddress", "type": "address"},
      {"name": "amount", "type": "uint256"}
    ],
    "name": "buyTokens",
    "outputs": [{"name": "tokensReceived", "type": "uint256"}],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "tokenAddress", "type": "address"},
      {"name": "tokenAmount", "type": "uint256"}
    ],
    "name": "sellTokens",
    "outputs": [{"name": "ethReceived", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "tokenAddress", "type": "address"},
      {"name": "ethAmount", "type": "uint256"}
    ],
    "name": "getBuyPrice",
    "outputs": [{"name": "tokenAmount", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"name": "tokenAddress", "type": "address"},
      {"name": "tokenAmount", "type": "uint256"}
    ],
    "name": "getSellPrice",
    "outputs": [{"name": "ethAmount", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "tokenAddress", "type": "address"}],
    "name": "getCurrentPrice",
    "outputs": [{"name": "price", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  }
] as const

export const ERC20_ABI = [
  {
    "inputs": [{"name": "spender", "type": "address"}, {"name": "amount", "type": "uint256"}],
    "name": "approve",
    "outputs": [{"name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"name": "account", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "totalSupply",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "name",
    "outputs": [{"name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "symbol",
    "outputs": [{"name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "decimals",
    "outputs": [{"name": "", "type": "uint8"}],
    "stateMutability": "view",
    "type": "function"
  }
] as const

export const CONTRACT_ADDRESSES = {
  TOKEN_FACTORY: "0x...", // Replace with actual deployed address
  BONDING_CURVE: "0x...", // Replace with actual deployed address
} as const