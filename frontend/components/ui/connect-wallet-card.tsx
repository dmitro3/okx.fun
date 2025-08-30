"use client"

import { Button } from "./button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./card"
import { Wallet } from "lucide-react"

export function ConnectWalletCard() {
  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader className="text-center">
        <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
          <Wallet className="w-6 h-6 text-primary" />
        </div>
        <CardTitle>Connect Your Wallet</CardTitle>
        <CardDescription>
          Connect your wallet to start creating and trading tokens
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Button className="w-full" size="lg">
          <Wallet className="w-4 h-4 mr-2" />
          Connect Wallet
        </Button>
        <p className="text-xs text-muted-foreground mt-4 text-center">
          By connecting your wallet, you agree to our terms of service and privacy policy
        </p>
      </CardContent>
    </Card>
  )
}