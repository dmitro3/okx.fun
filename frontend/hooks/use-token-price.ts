import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'

export function useTokenPrice(
  tokenAddress: string,
  amount: string,
  tradeType: 'buy' | 'sell'
) {
  const [price, setPrice] = useState(0)
  const [priceImpact, setPriceImpact] = useState(0)

  const { data: tokenData } = useQuery({
    queryKey: ['token-price', tokenAddress],
    queryFn: async () => {
      // Mock implementation - replace with actual contract call
      return {
        currentPrice: 0.000045,
        virtualOkbReserves: 30,
        virtualTokenReserves: 1073000000,
      }
    },
    refetchInterval: 5000, // Update every 5 seconds
  })

  useEffect(() => {
    if (!tokenData || !amount || parseFloat(amount) === 0) {
      setPrice(tokenData?.currentPrice || 0)
      setPriceImpact(0)
      return
    }

    const amountNum = parseFloat(amount)
    
    if (tradeType === 'buy') {
      // Calculate tokens received for OKB amount
      const tokensOut = calculateTokensOut(
        amountNum,
        tokenData.virtualOkbReserves,
        tokenData.virtualTokenReserves
      )
      
      const executionPrice = amountNum / tokensOut
      const impact = ((executionPrice - tokenData.currentPrice) / tokenData.currentPrice) * 100
      
      setPrice(executionPrice)
      setPriceImpact(Math.abs(impact))
    } else {
      // Calculate OKB received for token amount
      const okbOut = calculateOkbOut(
        amountNum,
        tokenData.virtualOkbReserves,
        tokenData.virtualTokenReserves
      )
      
      const executionPrice = okbOut / amountNum
      const impact = ((tokenData.currentPrice - executionPrice) / tokenData.currentPrice) * 100
      
      setPrice(executionPrice)
      setPriceImpact(Math.abs(impact))
    }
  }, [tokenData, amount, tradeType])

  return { price, priceImpact }
}

function calculateTokensOut(
  okbIn: number,
  okbReserve: number,
  tokenReserve: number
): number {
  const k = okbReserve * tokenReserve
  const newOkbReserve = okbReserve + okbIn
  const newTokenReserve = k / newOkbReserve
  return tokenReserve - newTokenReserve
}

function calculateOkbOut(
  tokensIn: number,
  okbReserve: number,
  tokenReserve: number
): number {
  const k = okbReserve * tokenReserve
  const newTokenReserve = tokenReserve + tokensIn
  const newOkbReserve = k / newTokenReserve
  return okbReserve - newOkbReserve
}