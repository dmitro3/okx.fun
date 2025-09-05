'use client'

import { useState } from 'react'
import { PortfolioOverview } from '@/components/portfolio/portfolio-overview'
import { HoldingsTable } from '@/components/portfolio/holdings-table'
import { ConnectWalletCard } from '@/components/ui/connect-wallet-card'

export default function PortfolioPage() {
  const [isConnected, setIsConnected] = useState(false)

  // Mock data - replace with actual data
  const mockStats = {
    totalValue: 12456,
    totalChange: 8.5,
    totalTokens: 12,
    activePositions: 8
  }

  const mockHoldings = [
    {
      token: {
        name: "Doge Killer",
        symbol: "DOGEEK",
        imageUrl: "/api/placeholder/40/40",
        address: "0x123"
      },
      balance: 10000,
      value: 1234,
      change24h: 15.6,
      avgBuyPrice: 0.0001,
      currentPrice: 0.000123,
      pnl: 230,
      pnlPercent: 23.0
    }
  ]

  if (!isConnected) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="max-w-md mx-auto">
          <ConnectWalletCard />
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-12">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-5xl font-bold mb-8">Your Portfolio</h1>
        
        <div className="space-y-8">
          <PortfolioOverview stats={mockStats} />
          <HoldingsTable holdings={mockHoldings} />
        </div>
      </div>
    </div>
  )
}