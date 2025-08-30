"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, ResponsiveContainer, Tooltip } from "recharts"

interface BondingCurveChartProps {
  tokenAddress: string
  currentSupply: number
  maxSupply: number
}

export function BondingCurveChart({ tokenAddress, currentSupply, maxSupply }: BondingCurveChartProps) {
  const [chartData, setChartData] = useState<Array<{ supply: number; price: number }>>([])

  useEffect(() => {
    // Generate bonding curve data points
    const generateCurveData = () => {
      const points = []
      const step = maxSupply / 100
      
      for (let supply = 0; supply <= maxSupply; supply += step) {
        // Square root bonding curve formula: price = k * sqrt(supply)
        // Where k is a constant that determines the curve steepness
        const k = 0.00001 // Adjust this constant for different curve steepness
        const price = k * Math.sqrt(supply)
        
        points.push({
          supply: supply,
          price: price
        })
      }
      
      return points
    }

    setChartData(generateCurveData())
  }, [maxSupply])

  const currentPrice = 0.00001 * Math.sqrt(currentSupply)

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <span>Bonding Curve</span>
          <div className="text-sm text-muted-foreground">
            Current: ${currentPrice.toFixed(8)}
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-64 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
              <XAxis 
                dataKey="supply" 
                tickFormatter={(value) => `${(value / 1e6).toFixed(0)}M`}
                className="text-xs"
              />
              <YAxis 
                tickFormatter={(value) => `$${value.toFixed(8)}`}
                className="text-xs"
              />
              <Tooltip
                formatter={(value: number) => [`$${value.toFixed(8)}`, 'Price']}
                labelFormatter={(label) => `Supply: ${Number(label).toLocaleString()}`}
                contentStyle={{
                  backgroundColor: 'hsl(var(--card))',
                  border: '1px solid hsl(var(--border))',
                  borderRadius: '6px'
                }}
              />
              <Line
                type="monotone"
                dataKey="price"
                stroke="hsl(var(--primary))"
                strokeWidth={2}
                dot={false}
                activeDot={{ r: 4, fill: 'hsl(var(--primary))' }}
              />
              {/* Current supply indicator */}
              <Line
                data={[
                  { supply: currentSupply, price: 0 },
                  { supply: currentSupply, price: Math.max(...chartData.map(d => d.price)) }
                ]}
                type="monotone"
                dataKey="price"
                stroke="hsl(var(--destructive))"
                strokeWidth={1}
                strokeDasharray="5 5"
                dot={false}
                connectNulls={false}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
        
        <div className="mt-4 grid grid-cols-3 gap-4 text-sm">
          <div>
            <div className="text-muted-foreground">Current Supply</div>
            <div className="font-semibold">{currentSupply.toLocaleString()}</div>
          </div>
          <div>
            <div className="text-muted-foreground">Max Supply</div>
            <div className="font-semibold">{maxSupply.toLocaleString()}</div>
          </div>
          <div>
            <div className="text-muted-foreground">Progress</div>
            <div className="font-semibold">
              {((currentSupply / maxSupply) * 100).toFixed(1)}%
            </div>
          </div>
        </div>
        
        <div className="mt-4 p-3 bg-muted/50 rounded-lg text-xs text-muted-foreground">
          <p className="mb-2">
            <strong>How it works:</strong> The bonding curve automatically sets the price based on supply. 
            As more tokens are bought, the price increases following a square root function.
          </p>
          <p>
            When the token reaches its funding goal, it will be listed on decentralized exchanges 
            with initial liquidity.
          </p>
        </div>
      </CardContent>
    </Card>
  )
}