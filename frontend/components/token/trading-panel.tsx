"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Slider } from "@/components/ui/slider"
import { ArrowUpDown, TrendingUp, TrendingDown } from "lucide-react"
import { formatNumber } from "@/lib/utils"
import { useToast } from "@/hooks/use-toast"

interface TradingPanelProps {
  token: {
    symbol: string
    price: number
    address: string
  }
}

export function TradingPanel({ token }: TradingPanelProps) {
  const { toast } = useToast()
  const [activeTab, setActiveTab] = useState("buy")
  const [amount, setAmount] = useState("")
  const [slippage, setSlippage] = useState([0.5])
  const [isLoading, setIsLoading] = useState(false)

  const handleTrade = async (type: "buy" | "sell") => {
    if (!amount || parseFloat(amount) <= 0) {
      toast({
        title: "Invalid Amount",
        description: "Please enter a valid amount",
        variant: "destructive"
      })
      return
    }

    setIsLoading(true)
    
    try {
      // TODO: Implement actual trading logic
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      toast({
        title: `${type === "buy" ? "Purchase" : "Sale"} Successful!`,
        description: `Successfully ${type === "buy" ? "bought" : "sold"} ${amount} ${token.symbol}`,
        variant: "success"
      })
      
      setAmount("")
    } catch (error) {
      toast({
        title: "Transaction Failed",
        description: "Failed to execute trade. Please try again.",
        variant: "destructive"
      })
    } finally {
      setIsLoading(false)
    }
  }

  const estimatedValue = parseFloat(amount || "0") * token.price
  const estimatedTokens = parseFloat(amount || "0") / token.price

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <ArrowUpDown className="w-5 h-5" />
          Trade {token.symbol}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="buy" className="flex items-center gap-2">
              <TrendingUp className="w-4 h-4" />
              Buy
            </TabsTrigger>
            <TabsTrigger value="sell" className="flex items-center gap-2">
              <TrendingDown className="w-4 h-4" />
              Sell
            </TabsTrigger>
          </TabsList>
          
          <TabsContent value="buy" className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="buy-amount">ETH Amount</Label>
              <Input
                id="buy-amount"
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="0.0"
                step="0.001"
              />
              <div className="text-sm text-muted-foreground">
                ≈ {formatNumber(estimatedTokens)} {token.symbol}
              </div>
            </div>
            
            <div className="flex gap-2">
              {[0.01, 0.05, 0.1, 0.5].map((value) => (
                <Button
                  key={value}
                  variant="outline"
                  size="sm"
                  onClick={() => setAmount(value.toString())}
                >
                  {value} ETH
                </Button>
              ))}
            </div>
            
            <Button 
              className="w-full" 
              size="lg"
              onClick={() => handleTrade("buy")}
              disabled={isLoading}
            >
              {isLoading ? "Processing..." : `Buy ${token.symbol}`}
            </Button>
          </TabsContent>
          
          <TabsContent value="sell" className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="sell-amount">{token.symbol} Amount</Label>
              <Input
                id="sell-amount"
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="0.0"
                step="0.01"
              />
              <div className="text-sm text-muted-foreground">
                ≈ {formatNumber(estimatedValue)} ETH
              </div>
            </div>
            
            <div className="flex gap-2">
              {[25, 50, 75, 100].map((percent) => (
                <Button
                  key={percent}
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    // TODO: Calculate based on user's actual balance
                    const mockBalance = 1000
                    setAmount(((mockBalance * percent) / 100).toString())
                  }}
                >
                  {percent}%
                </Button>
              ))}
            </div>
            
            <Button 
              className="w-full" 
              size="lg"
              variant="destructive"
              onClick={() => handleTrade("sell")}
              disabled={isLoading}
            >
              {isLoading ? "Processing..." : `Sell ${token.symbol}`}
            </Button>
          </TabsContent>
        </Tabs>
        
        <div className="mt-6 space-y-4 pt-4 border-t">
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <Label>Slippage Tolerance</Label>
              <span className="text-sm font-medium">{slippage[0]}%</span>
            </div>
            <Slider
              value={slippage}
              onValueChange={setSlippage}
              max={5}
              min={0.1}
              step={0.1}
            />
          </div>
          
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Current Price</span>
              <span>${token.price.toFixed(6)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Network Fee</span>
              <span>~$2.50</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}