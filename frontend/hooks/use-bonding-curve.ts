import { useContractWrite, useWaitForTransaction, useAccount } from 'wagmi'
import { parseEther } from 'viem'
import { toast } from '@/hooks/use-toast'
import { BONDING_CURVE_ABI } from '@/lib/abis'

const BONDING_CURVE_ADDRESS = process.env.NEXT_PUBLIC_BONDING_CURVE as `0x${string}`

export function useBondingCurve(tokenAddress: string) {
  const { address } = useAccount()

  // Buy tokens
  const {
    write: buyWrite,
    data: buyData,
    isLoading: buyLoading,
  } = useContractWrite({
    address: BONDING_CURVE_ADDRESS,
    abi: BONDING_CURVE_ABI,
    functionName: 'buyTokens',
  })

  const { isLoading: buyConfirming } = useWaitForTransaction({
    hash: buyData?.hash,
    onSuccess: () => {
      toast({
        title: 'Purchase successful!',
        description: 'Your tokens have been purchased.',
      })
    },
  })

  // Sell tokens
  const {
    write: sellWrite,
    data: sellData,
    isLoading: sellLoading,
  } = useContractWrite({
    address: BONDING_CURVE_ADDRESS,
    abi: BONDING_CURVE_ABI,
    functionName: 'sellTokens',
  })

  const { isLoading: sellConfirming } = useWaitForTransaction({
    hash: sellData?.hash,
    onSuccess: () => {
      toast({
        title: 'Sale successful!',
        description: 'Your tokens have been sold.',
      })
    },
  })

  const buy = async (amountOKB: string, slippage: number) => {
    if (!address) throw new Error('Wallet not connected')
    
    const value = parseEther(amountOKB)
    const minTokensOut = calculateMinTokensOut(value, slippage)
    
    await buyWrite({
      args: [tokenAddress, minTokensOut],
      value,
    })
  }

  const sell = async (amountTokens: string, slippage: number) => {
    if (!address) throw new Error('Wallet not connected')
    
    const tokens = parseEther(amountTokens)
    const minOkbOut = calculateMinOkbOut(tokens, slippage)
    
    await sellWrite({
      args: [tokenAddress, tokens, minOkbOut],
    })
  }

  return {
    buy,
    sell,
    isBuying: buyLoading || buyConfirming,
    isSelling: sellLoading || sellConfirming,
  }
}

function calculateMinTokensOut(okbAmount: bigint, slippage: number): bigint {
  // Implement slippage calculation
  const slippageFactor = BigInt(Math.floor((100 - slippage) * 100))
  return (okbAmount * slippageFactor) / 10000n
}

function calculateMinOkbOut(tokenAmount: bigint, slippage: number): bigint {
  // Implement slippage calculation
  const slippageFactor = BigInt(Math.floor((100 - slippage) * 100))
  return (tokenAmount * slippageFactor) / 10000n
}