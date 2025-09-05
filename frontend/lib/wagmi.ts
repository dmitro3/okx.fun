import { createConfig, http } from 'wagmi'
import { Chain } from 'wagmi/chains'
import { walletConnect, injected, coinbaseWallet } from 'wagmi/connectors'

// Define X Layer chain
export const xLayer: Chain = {
  id: 196,
  name: 'X Layer',
  nativeCurrency: {
    decimals: 18,
    name: 'OKB',
    symbol: 'OKB',
  },
  rpcUrls: {
    default: {
      http: ['https://xlayerrpc.okx.com'],
      webSocket: ['wss://xlayerws.okx.com'],
    },
    public: {
      http: ['https://xlayerrpc.okx.com'],
      webSocket: ['wss://xlayerws.okx.com'],
    },
  },
  blockExplorers: {
    default: {
      name: 'OKLink',
      url: 'https://www.oklink.com/x-layer',
    },
  },
  testnet: false,
}

// Define X Layer Testnet
export const xLayerTestnet: Chain = {
  id: 195,
  name: 'X Layer Testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'OKB',
    symbol: 'OKB',
  },
  rpcUrls: {
    default: {
      http: ['https://xlayertestrpc.okx.com'],
    },
    public: {
      http: ['https://xlayertestrpc.okx.com'],
    },
  },
  blockExplorers: {
    default: {
      name: 'OKLink',
      url: 'https://www.oklink.com/x-layer-test',
    },
  },
  testnet: true,
}

const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!

export const config = createConfig({
  chains: [xLayer, xLayerTestnet],
  connectors: [
    injected(),
    walletConnect({
      projectId,
      showQrModal: true,
    }),
    coinbaseWallet({
      appName: 'X Layer Fun',
    }),
  ],
  transports: {
    [xLayer.id]: http(),
    [xLayerTestnet.id]: http(),
  },
})