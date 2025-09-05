'use client'

import { useParams } from 'next/navigation'
import { TradingInterface } from '@/components/trading/trading-interface'
import { TokenInfo } from '@/components/token/token-info'
import { BondingCurveChart } from '@/components/charts/bonding-curve-chart'
import { TradeHistory } from '@/components/token/trade-history'
import { TokenHolders } from '@/components/token/token-holders'
import { Comments } from '@/components/token/comments'

export default function TokenPage() {
  const params = useParams()
  const tokenAddress = params.address as string

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="grid lg:grid-cols-3 gap-8">
        {/* Left Column - Token Info & Chart */}
        <div className="lg:col-span-2 space-y-6">
          <TokenInfo address={tokenAddress} />
          <BondingCurveChart address={tokenAddress} />
          
          {/* Tabs for History, Holders, Comments */}
          <div className="bg-card rounded-lg p-6">
            <div className="tabs">
              <TradeHistory address={tokenAddress} />
              <TokenHolders address={tokenAddress} />
              <Comments address={tokenAddress} />
            </div>
          </div>
        </div>

        {/* Right Column - Trading Interface */}
        <div className="lg:col-span-1">
          <div className="sticky top-24">
            <TradingInterface tokenAddress={tokenAddress} />
          </div>
        </div>
      </div>
    </div>
  )
}