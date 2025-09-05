import { useQuery } from '@tanstack/react-query'
import { useEffect, useState } from 'react'

interface Token {
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

interface UseTokensParams {
  limit?: number
  searchQuery?: string
  filters?: {
    sortBy: string
    timeframe: string
    status: string
  }
}

export function useTokens({ limit, searchQuery, filters }: UseTokensParams = {}) {
  // Mock data for development - replace with actual API call
  const { data, isLoading, error } = useQuery({
    queryKey: ['tokens', limit, searchQuery, filters],
    queryFn: async () => {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      // Mock data
      const mockTokens: Token[] = [
        {
          address: '0x1234567890123456789012345678901234567890',
          name: 'Doge Moon',
          symbol: 'DMOON',
          imageUrl: 'https://via.placeholder.com/150',
          description: 'To the moon!',
          price: 0.000045,
          priceChange24h: 25.5,
          volume24h: 125000,
          marketCap: 450000,
          holders: 1234,
          liquidity: 50000,
          progress: 75,
          graduated: false,
          createdAt: '2024-01-01T00:00:00Z',
        },
        {
          address: '0x2345678901234567890123456789012345678901',
          name: 'Pepe Classic',
          symbol: 'PEPEC',
          imageUrl: 'https://via.placeholder.com/150',
          description: 'The original Pepe',
          price: 0.00012,
          priceChange24h: -5.2,
          volume24h: 85000,
          marketCap: 1200000,
          holders: 3456,
          liquidity: 150000,
          progress: 100,
          graduated: true,
          createdAt: '2024-01-02T00:00:00Z',
        },
        // Add more mock tokens as needed
      ]

      // Apply filters and search
      let filtered = [...mockTokens]
      
      if (searchQuery) {
        filtered = filtered.filter(token =>
          token.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          token.symbol.toLowerCase().includes(searchQuery.toLowerCase()) ||
          token.address.toLowerCase().includes(searchQuery.toLowerCase())
        )
      }

      if (filters?.status === 'graduated') {
        filtered = filtered.filter(token => token.graduated)
      } else if (filters?.status === 'bonding') {
        filtered = filtered.filter(token => !token.graduated)
      }

      // Apply sorting
      if (filters?.sortBy === 'volume') {
        filtered.sort((a, b) => b.volume24h - a.volume24h)
      } else if (filters?.sortBy === 'marketCap') {
        filtered.sort((a, b) => b.marketCap - a.marketCap)
      } else if (filters?.sortBy === 'newest') {
        filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      }

      // Apply limit
      if (limit) {
        filtered = filtered.slice(0, limit)
      }

      return filtered
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  })

  return {
    tokens: data || [],
    isLoading,
    error,
  }
}