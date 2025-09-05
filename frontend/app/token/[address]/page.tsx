'use client'

import { useParams } from 'next/navigation'
import { TokenDetailHeader } from '@/components/token/token-detail-header'
import { TradingPanel } from '@/components/token/trading-panel'
import { BondingCurveChart } from '@/components/charts/bonding-curve-chart'

export default function TokenPage() {
  const params = useParams()
  const tokenAddress = params.address as string

  // Mock token data - replace with actual data fetching
  const mockToken = {
    name: "Doge Killer",
    symbol: "DOGEEK",
    description: "The ultimate meme token that will overtake DOGE",
    imageUrl: "/api/placeholder/80/80",
    address: tokenAddress,
    marketCap: 1234567,
    price: 0.000123,
    change24h: 15.6,
    volume24h: 789012,
    holders: 1567,
    creator: "0x1234567890123456789012345678901234567890",
    createdAt: new Date().toISOString()
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="space-y-6">
        <TokenDetailHeader token={mockToken} />
        
        <div className="grid lg:grid-cols-3 gap-8">
          {/* Left Column - Chart */}
          <div className="lg:col-span-2">
            <BondingCurveChart 
              tokenAddress={tokenAddress}
              currentSupply={500000000}
              maxSupply={1000000000}
            />
          </div>

          {/* Right Column - Trading Interface */}
          <div className="lg:col-span-1">
            <div className="sticky top-24">
              <TradingPanel token={mockToken} />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}