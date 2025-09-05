'use client'

import { useEffect, useState } from 'react'
import { TokenCard } from './token-card'
import { Loader2 } from 'lucide-react'
import { useTokens } from '@/hooks/use-tokens'

interface TokenGridProps {
  limit?: number
  searchQuery?: string
  filters?: {
    sortBy: string
    timeframe: string
    status: string
  }
}

export function TokenGrid({ limit, searchQuery, filters }: TokenGridProps) {
  const { tokens, isLoading, error } = useTokens({ limit, searchQuery, filters })

  if (isLoading) {
    return (
      <div className="flex justify-center items-center py-20">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-20">
        <p className="text-red-500">Failed to load tokens</p>
      </div>
    )
  }

  if (tokens.length === 0) {
    return (
      <div className="text-center py-20">
        <p className="text-muted-foreground">No tokens found</p>
      </div>
    )
  }

  return (
    <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {tokens.map((token) => (
        <TokenCard key={token.address} token={token} />
      ))}
    </div>
  )
}