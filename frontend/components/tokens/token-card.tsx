'use client'

import { motion } from 'framer-motion'
import Link from 'next/link'
import Image from 'next/image'
import { TrendingUp, TrendingDown, Users, Droplets } from 'lucide-react'
import { formatNumber, formatPercent, shortenAddress } from '@/lib/utils'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'

interface TokenCardProps {
  token: {
    address: string
    name: string
    symbol: string
    imageUrl: string
    description: string
    price: number
    priceChange24h: number
    volume24h: number
    marketCap: number
    holders: number
    liquidity: number
    progress: number
    graduated: boolean
    createdAt: string
  }
}

export function TokenCard({ token }: TokenCardProps) {
  const isPositive = token.priceChange24h >= 0

  return (
    <motion.div
      whileHover={{ y: -4 }}
      transition={{ duration: 0.2 }}
    >
      <Link href={`/token/${token.address}`}>
        <div className="bg-card rounded-lg border hover:border-primary/50 transition-colors p-4 h-full">
          {/* Header */}
          <div className="flex items-start justify-between mb-3">
            <div className="flex items-center gap-3">
              <div className="relative w-12 h-12">
                <Image
                  src={token.imageUrl || '/placeholder.png'}
                  alt={token.name}
                  fill
                  className="rounded-full object-cover"
                />
                {token.graduated && (
                  <div className="absolute -top-1 -right-1 w-4 h-4 bg-green-500 rounded-full flex items-center justify-center">
                    <span className="text-xs">✓</span>
                  </div>
                )}
              </div>
              <div>
                <h3 className="font-semibold">{token.name}</h3>
                <p className="text-sm text-muted-foreground">{token.symbol}</p>
              </div>
            </div>
            {token.graduated && (
              <Badge variant="success">DEX</Badge>
            )}
          </div>

          {/* Price Info */}
          <div className="space-y-2 mb-3">
            <div className="flex items-center justify-between">
              <span className="text-2xl font-bold">
                ${formatNumber(token.price, 6)}
              </span>
              <div className={`flex items-center gap-1 ${isPositive ? 'text-green-500' : 'text-red-500'}`}>
                {isPositive ? <TrendingUp className="h-4 w-4" /> : <TrendingDown className="h-4 w-4" />}
                <span className="text-sm font-medium">
                  {formatPercent(Math.abs(token.priceChange24h))}
                </span>
              </div>
            </div>

            {/* Progress Bar (if not graduated) */}
            {!token.graduated && (
              <div className="space-y-1">
                <div className="flex justify-between text-xs text-muted-foreground">
                  <span>Progress to DEX</span>
                  <span>{token.progress}%</span>
                </div>
                <Progress value={token.progress} className="h-2" />
              </div>
            )}
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div className="flex items-center gap-1">
              <Users className="h-3 w-3 text-muted-foreground" />
              <span className="text-muted-foreground">Holders:</span>
              <span className="font-medium">{formatNumber(token.holders)}</span>
            </div>
            <div className="flex items-center gap-1">
              <Droplets className="h-3 w-3 text-muted-foreground" />
              <span className="text-muted-foreground">Liq:</span>
              <span className="font-medium">${formatNumber(token.liquidity)}</span>
            </div>
          </div>

          {/* Volume */}
          <div className="mt-3 pt-3 border-t">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">24h Vol</span>
              <span className="font-medium">${formatNumber(token.volume24h)}</span>
            </div>
          </div>
        </div>
      </Link>
    </motion.div>
  )
}