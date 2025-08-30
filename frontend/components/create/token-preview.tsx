"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

interface TokenPreviewProps {
  name: string
  symbol: string
  description: string
  imageUrl: string
  initialSupply: string
}

export function TokenPreview({ name, symbol, description, imageUrl, initialSupply }: TokenPreviewProps) {
  if (!name && !symbol && !description) {
    return (
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="text-lg">Token Preview</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground text-center py-8">
            Fill in the form to see a preview of your token
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="w-full max-w-md">
      <CardHeader>
        <CardTitle className="text-lg">Token Preview</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center space-x-4">
          {imageUrl ? (
            <img
              src={imageUrl}
              alt={name}
              className="w-16 h-16 rounded-full object-cover"
            />
          ) : (
            <div className="w-16 h-16 rounded-full bg-muted flex items-center justify-center">
              <span className="text-2xl font-bold">{symbol.charAt(0)}</span>
            </div>
          )}
          <div>
            <h3 className="text-xl font-bold">{name || "Token Name"}</h3>
            <Badge variant="secondary">{symbol || "SYMBOL"}</Badge>
          </div>
        </div>
        
        {description && (
          <div className="space-y-2">
            <h4 className="font-semibold">Description</h4>
            <p className="text-sm text-muted-foreground">{description}</p>
          </div>
        )}
        
        <div className="space-y-2">
          <h4 className="font-semibold">Token Details</h4>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <span className="text-muted-foreground">Supply:</span>
              <p className="font-mono">{Number(initialSupply || 0).toLocaleString()}</p>
            </div>
            <div>
              <span className="text-muted-foreground">Type:</span>
              <p>Bonding Curve</p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}