"use client"

import { Button } from "@/components/ui/button"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"

interface TokenFiltersProps {
  filters: {
    sortBy: string
    timeframe: string
    status: string
  }
  onChange: (filters: any) => void
}

export function TokenFilters({ filters, onChange }: TokenFiltersProps) {
  return (
    <div className="flex flex-col sm:flex-row gap-4">
      <Tabs
        value={filters.sortBy}
        onValueChange={(value) => onChange({ ...filters, sortBy: value })}
      >
        <TabsList>
          <TabsTrigger value="volume">Volume</TabsTrigger>
          <TabsTrigger value="price">Price</TabsTrigger>
          <TabsTrigger value="marketcap">Market Cap</TabsTrigger>
          <TabsTrigger value="age">Age</TabsTrigger>
        </TabsList>
      </Tabs>

      <Tabs
        value={filters.timeframe}
        onValueChange={(value) => onChange({ ...filters, timeframe: value })}
      >
        <TabsList>
          <TabsTrigger value="1h">1H</TabsTrigger>
          <TabsTrigger value="24h">24H</TabsTrigger>
          <TabsTrigger value="7d">7D</TabsTrigger>
          <TabsTrigger value="30d">30D</TabsTrigger>
        </TabsList>
      </Tabs>

      <Tabs
        value={filters.status}
        onValueChange={(value) => onChange({ ...filters, status: value })}
      >
        <TabsList>
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="active">Active</TabsTrigger>
          <TabsTrigger value="graduated">Graduated</TabsTrigger>
        </TabsList>
      </Tabs>
    </div>
  )
}