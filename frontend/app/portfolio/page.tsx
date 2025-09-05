'use client'

import { useAccount } from 'wagmi'
import { PortfolioStats } from '@/components/portfolio/portfolio-stats'
import { HoldingsTable } from '@/components/portfolio/holdings-table'
import { TransactionHistory } from '@/components/portfolio/transaction-history'
import { PnLChart } from '@/components/portfolio/pnl-chart'
import { ConnectWalletCard } from '@/components/ui/connect-wallet-card'

export default function PortfolioPage() {
  const { address, isConnected } = useAccount()

  if (!isConnected) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="max-w-md mx-auto">
          <ConnectWalletCard 
            title="Connect Your Wallet"
            description="Please connect your wallet to view your portfolio"
          />
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-12">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-5xl font-bold mb-8">Your Portfolio</h1>
        
        <div className="grid gap-6 mb-8">
          <PortfolioStats address={address!} />
          <PnLChart address={address!} />
        </div>

        <div className="grid lg:grid-cols-2 gap-8">
          <div>
            <h2 className="text-2xl font-bold mb-4">Your Holdings</h2>
            <HoldingsTable address={address!} />
          </div>
          <div>
            <h2 className="text-2xl font-bold mb-4">Recent Transactions</h2>
            <TransactionHistory address={address!} />
          </div>
        </div>
      </div>
    </div>
  )
}