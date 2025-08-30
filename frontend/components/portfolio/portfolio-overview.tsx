"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { TrendingUp, TrendingDown, DollarSign, Coins } from "lucide-react"
import { formatNumber } from "@/lib/utils"

interface PortfolioOverviewProps {
  stats: {
    totalValue: number
    totalChange: number
    totalTokens: number
    activePositions: number
  }
}

export function PortfolioOverview({ stats }: PortfolioOverviewProps) {
  const isPositive = stats.totalChange > 0

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Value</CardTitle>
          <DollarSign className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">${formatNumber(stats.totalValue)}</div>
          <div className={`flex items-center text-xs ${
            isPositive ? 'text-green-600' : 'text-red-600'
          }`}>
            {isPositive ? (
              <TrendingUp className="w-3 h-3 mr-1" />
            ) : (
              <TrendingDown className="w-3 h-3 mr-1" />
            )}
            {isPositive ? '+' : ''}{stats.totalChange.toFixed(2)}%
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Tokens</CardTitle>
          <Coins className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{stats.totalTokens}</div>
          <p className="text-xs text-muted-foreground">Different tokens held</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Active Positions</CardTitle>
          <TrendingUp className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{stats.activePositions}</div>
          <p className="text-xs text-muted-foreground">Currently trading</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Best Performer</CardTitle>
          <Badge variant="secondary" className="text-xs">+24.5%</Badge>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">DOGE</div>
          <p className="text-xs text-muted-foreground">Top gainer today</p>
        </CardContent>
      </Card>
    </div>
  )
}