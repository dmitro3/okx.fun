'use client'

import { useState } from 'react'
import { TokenGrid } from '@/components/tokens/token-grid'
import { TokenFilters } from '@/components/tokens/token-filters'
import { SearchBar } from '@/components/ui/search-bar'

export default function TokensPage() {
  const [searchQuery, setSearchQuery] = useState('')
  const [filters, setFilters] = useState({
    sortBy: 'volume',
    timeframe: '24h',
    status: 'all',
  })

  return (
    <div className="container mx-auto px-4 py-12">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-5xl font-bold mb-4">Explore Tokens</h1>
        <p className="text-xl text-muted-foreground mb-8">
          Discover and trade the hottest meme tokens on X Layer
        </p>

        <div className="flex flex-col lg:flex-row gap-6 mb-8">
          <div className="flex-1">
            <SearchBar 
              value={searchQuery}
              onChange={setSearchQuery}
              placeholder="Search by name, symbol, or address..."
            />
          </div>
          <TokenFilters 
            filters={filters}
            onChange={setFilters}
          />
        </div>

        <TokenGrid 
          searchQuery={searchQuery}
          filters={filters}
        />
      </div>
    </div>
  )
}