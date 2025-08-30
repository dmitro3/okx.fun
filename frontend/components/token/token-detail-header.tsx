"use client"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ExternalLink, Share2, Heart } from "lucide-react"
import { formatNumber } from "@/lib/utils"

interface TokenDetailHeaderProps {
  token: {
    name: string
    symbol: string
    description: string
    imageUrl: string
    address: string
    marketCap: number
    price: number
    change24h: number
    volume24h: number
    holders: number
    creator: string
    createdAt: string
  }
}

export function TokenDetailHeader({ token }: TokenDetailHeaderProps) {
  const isPositive = token.change24h > 0

  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex flex-col lg:flex-row gap-6">
          {/* Token Info */}
          <div className="flex items-start gap-4">
            <img
              src={token.imageUrl}
              alt={token.name}
              className="w-20 h-20 rounded-full object-cover"
            />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-2">
                <h1 className="text-3xl font-bold truncate">{token.name}</h1>
                <Badge variant="secondary" className="text-lg px-3 py-1">
                  {token.symbol}
                </Badge>
              </div>
              <p className="text-muted-foreground mb-4 line-clamp-2">
                {token.description}
              </p>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <span>Created by</span>
                <code className="bg-muted px-2 py-1 rounded text-xs">
                  {token.creator.slice(0, 6)}...{token.creator.slice(-4)}
                </code>
                <span>•</span>
                <span>{new Date(token.createdAt).toLocaleDateString()}</span>
              </div>
            </div>
          </div>

          {/* Price Info */}
          <div className="lg:text-right">
            <div className="text-3xl font-bold mb-2">
              ${token.price.toFixed(6)}
            </div>
            <div className={`text-lg mb-4 ${
              isPositive ? 'text-green-600' : 'text-red-600'
            }`}>
              {isPositive ? '+' : ''}{token.change24h.toFixed(2)}%
            </div>
            <div className="grid grid-cols-2 lg:grid-cols-1 gap-4 text-sm">
              <div>
                <div className="text-muted-foreground">Market Cap</div>
                <div className="font-semibold">${formatNumber(token.marketCap)}</div>
              </div>
              <div>
                <div className="text-muted-foreground">24h Volume</div>
                <div className="font-semibold">${formatNumber(token.volume24h)}</div>
              </div>
              <div>
                <div className="text-muted-foreground">Holders</div>
                <div className="font-semibold">{formatNumber(token.holders)}</div>
              </div>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center justify-between mt-6 pt-6 border-t">
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm">
              <Heart className="w-4 h-4 mr-2" />
              Follow
            </Button>
            <Button variant="outline" size="sm">
              <Share2 className="w-4 h-4 mr-2" />
              Share
            </Button>
            <Button variant="outline" size="sm">
              <ExternalLink className="w-4 h-4 mr-2" />
              View on Explorer
            </Button>
          </div>
          <div className="text-xs text-muted-foreground">
            Contract: {token.address.slice(0, 8)}...{token.address.slice(-6)}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}