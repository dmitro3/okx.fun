'use client'

import { useState } from 'react'
import { useAccount } from 'wagmi'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card } from '@/components/ui/card'
import { Slider } from '@/components/ui/slider'
import { ArrowUpDown, Info, Loader2 } from 'lucide-react'
import { useTokenPrice } from '@/hooks/use-token-price'
import { useBondingCurve } from '@/hooks/use-bonding-curve'
import { formatNumber } from '@/lib/utils'
import { toast } from '@/hooks/use-toast'

interface TradingInterfaceProps {
  tokenAddress: string
}

export function TradingInterface({ tokenAddress }: TradingInterfaceProps) {
  const { address, isConnected } = useAccount()
  const [activeTab, setActiveTab] = useState('buy')
  const [amount, setAmount] = useState('')
  const [slippage, setSlippage] = useState(1)
  const [isLoading, setIsLoading] = useState(false)

  const { price, priceImpact } = useTokenPrice(tokenAddress, amount, activeTab)
  const { buy, sell } = useBondingCurve(tokenAddress)

  const handleTrade = async () => {
    if (!isConnected) {
      toast({
        title: 'Wallet not connected',
        description: 'Please connect your wallet to trade',
        variant: 'destructive',
      })
      return
    }

    if (!amount || parseFloat(amount) <= 0) {
      toast({
        title: 'Invalid amount',
        description: 'Please enter a valid amount',
        variant: 'destructive',
      })
      return
    }

    setIsLoading(true)
    try {
      if (activeTab === 'buy') {
        await buy(amount, slippage)
        toast({
          title: 'Purchase successful',
          description: `You bought ${amount} tokens`,
        })
      } else {
        await sell(amount, slippage)
        toast({
          title: 'Sale successful',
          description: `You sold ${amount} tokens`,
        })
      }
      setAmount('')
    } catch (error: any) {
      toast({
        title: 'Transaction failed',
        description: error.message || 'Please try again',
        variant: 'destructive',
      })
    } finally {
      setIsLoading(false)
    }
  }

  const presetAmounts = activeTab === 'buy' 
    ? ['0.1', '0.5', '1', '5'] 
    : ['25%', '50%', '75%', '100%']

  return (
    <Card className="p-6">
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="buy">Buy</TabsTrigger>
          <TabsTrigger value="sell">Sell</TabsTrigger>
        </TabsList>

        <TabsContent value="buy" className="space-y-4">
          <div>
            <Label htmlFor="buy-amount">Amount (OKB)</Label>
            <Input
              id="buy-amount"
              type="number"
              placeholder="0.0"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="mt-1"
            />
          </div>

          <div className="grid grid-cols-4 gap-2">
            {presetAmounts.map((preset) => (
              <Button
                key={preset}
                variant="outline"
                size="sm"
                onClick={() => setAmount(preset)}
              >
                {preset} OKB
              </Button>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="sell" className="space-y-4">
          <div>
            <Label htmlFor="sell-amount">Amount (Tokens)</Label>
            <Input
              id="sell-amount"
              type="number"
              placeholder="0.0"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="mt-1"
            />
          </div>

          <div className="grid grid-cols-4 gap-2">
            {presetAmounts.map((preset) => (
              <Button
                key={preset}
                variant="outline"
                size="sm"
                onClick={() => {
                  // Handle percentage selection for selling
                  if (preset.includes('%')) {
                    // Calculate from balance
                    setAmount(preset)
                  }
                }}
              >
                {preset}
              </Button>
            ))}
          </div>
        </TabsContent>
      </Tabs>

      {/* Slippage Settings */}
      <div className="mt-6 space-y-2">
        <div className="flex items-center justify-between">
          <Label className="flex items-center gap-1">
            Slippage Tolerance
            <Info className="h-3 w-3 text-muted-foreground" />
          </Label>
          <span className="text-sm font-medium">{slippage}%</span>
        </div>
        <Slider
          value={[slippage]}
          onValueChange={([value]) => setSlippage(value)}
          min={0.1}
          max={5}
          step={0.1}
          className="w-full"
        />
      </div>

      {/* Price Impact */}
      {amount && (
        <div className="mt-4 p-3 bg-muted rounded-lg space-y-2">
          <div className="flex justify-between text-sm">
            <span>Price per token</span>
            <span className="font-medium">${formatNumber(price, 6)}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span>Price impact</span>
            <span className={`font-medium ${priceImpact > 5 ? 'text-red-500' : ''}`}>
              {priceImpact.toFixed(2)}%
            </span>
          </div>
          <div className="flex justify-between text-sm">
            <span>Total</span>
            <span className="font-medium">
              {activeTab === 'buy' 
                ? `${amount} OKB`
                : `${formatNumber(parseFloat(amount) * price)} OKB`
              }
            </span>
          </div>
        </div>
      )}

      {/* Trade Button */}
      <Button
        className="w-full mt-6"
        size="lg"
        onClick={handleTrade}
        disabled={isLoading || !amount}
      >
        {isLoading ? (
          <>
            <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            Processing...
          </>
        ) : (
          <>
            {activeTab === 'buy' ? 'Buy' : 'Sell'} Tokens
            <ArrowUpDown className="h-4 w-4 ml-2" />
          </>
        )}
      </Button>

      {!isConnected && (
        <p className="text-center text-sm text-muted-foreground mt-4">
          Connect your wallet to trade
        </p>
      )}
    </Card>
  )
}