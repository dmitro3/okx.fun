"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { TrendingUp, TrendingDown, MoreHorizontal } from "lucide-react"
import { formatNumber } from "@/lib/utils"

interface Holding {
  token: {
    name: string
    symbol: string
    imageUrl: string
    address: string
  }
  balance: number
  value: number
  change24h: number
  avgBuyPrice: number
  currentPrice: number
  pnl: number
  pnlPercent: number
}

interface HoldingsTableProps {
  holdings: Holding[]
}

export function HoldingsTable({ holdings }: HoldingsTableProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Your Holdings</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {holdings.map((holding) => {
            const isPnlPositive = holding.pnl > 0
            const isPricePositive = holding.change24h > 0
            
            return (
              <div
                key={holding.token.address}
                className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center gap-4">
                  <img
                    src={holding.token.imageUrl}
                    alt={holding.token.name}
                    className="w-10 h-10 rounded-full"
                  />
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-semibold">{holding.token.symbol}</span>
                      <span className="text-sm text-muted-foreground">
                        {holding.token.name}
                      </span>
                    </div>
                    <div className="text-sm text-muted-foreground">
                      {formatNumber(holding.balance)} tokens
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-4 gap-8 text-right">
                  <div>
                    <div className="font-semibold">
                      ${holding.currentPrice.toFixed(6)}
                    </div>
                    <div className={`text-sm flex items-center justify-end ${
                      isPricePositive ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {isPricePositive ? (
                        <TrendingUp className="w-3 h-3 mr-1" />
                      ) : (
                        <TrendingDown className="w-3 h-3 mr-1" />
                      )}
                      {isPricePositive ? '+' : ''}{holding.change24h.toFixed(2)}%
                    </div>
                  </div>

                  <div>
                    <div className="font-semibold">
                      ${formatNumber(holding.value)}
                    </div>
                    <div className="text-sm text-muted-foreground">
                      Value
                    </div>
                  </div>

                  <div>
                    <div className={`font-semibold ${
                      isPnlPositive ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {isPnlPositive ? '+' : ''}${formatNumber(Math.abs(holding.pnl))}
                    </div>
                    <div className={`text-sm ${
                      isPnlPositive ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {isPnlPositive ? '+' : ''}{holding.pnlPercent.toFixed(2)}%
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Button size="sm" variant="outline">
                      Trade
                    </Button>
                    <Button size="sm" variant="ghost">
                      <MoreHorizontal className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              </div>
            )
          })}
          
          {holdings.length === 0 && (
            <div className="text-center py-12">
              <div className="text-muted-foreground mb-4">
                You don't have any tokens yet
              </div>
              <Button>Start Trading</Button>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  )
}