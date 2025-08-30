"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Upload, Loader2 } from "lucide-react"
import { useToast } from "@/hooks/use-toast"

interface TokenFormData {
  name: string
  symbol: string
  description: string
  imageUrl: string
  initialSupply: string
}

export function TokenCreationForm() {
  const { toast } = useToast()
  const [formData, setFormData] = useState<TokenFormData>({
    name: "",
    symbol: "",
    description: "",
    imageUrl: "",
    initialSupply: "1000000000"
  })
  const [isLoading, setIsLoading] = useState(false)
  const [imageFile, setImageFile] = useState<File | null>(null)

  const handleInputChange = (field: keyof TokenFormData, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
  }

  const handleImageUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      setImageFile(file)
      const reader = new FileReader()
      reader.onload = (e) => {
        setFormData(prev => ({
          ...prev,
          imageUrl: e.target?.result as string
        }))
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    
    if (!formData.name || !formData.symbol || !formData.description) {
      toast({
        title: "Missing Information",
        description: "Please fill in all required fields",
        variant: "destructive"
      })
      return
    }

    setIsLoading(true)
    
    try {
      // TODO: Implement token creation logic with smart contract
      await new Promise(resolve => setTimeout(resolve, 2000)) // Simulate contract call
      
      toast({
        title: "Token Created!",
        description: `${formData.name} (${formData.symbol}) has been created successfully`,
        variant: "success"
      })
      
      // Reset form
      setFormData({
        name: "",
        symbol: "",
        description: "",
        imageUrl: "",
        initialSupply: "1000000000"
      })
      setImageFile(null)
    } catch (error) {
      toast({
        title: "Creation Failed",
        description: "Failed to create token. Please try again.",
        variant: "destructive"
      })
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle className="text-2xl">Create Your Token</CardTitle>
        <CardDescription>
          Launch your meme token with our bonding curve mechanism
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <Label htmlFor="name">Token Name *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => handleInputChange("name", e.target.value)}
                placeholder="Doge Killer"
                required
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="symbol">Symbol *</Label>
              <Input
                id="symbol"
                value={formData.symbol}
                onChange={(e) => handleInputChange("symbol", e.target.value.toUpperCase())}
                placeholder="DOGEEK"
                maxLength={10}
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description *</Label>
            <textarea
              id="description"
              value={formData.description}
              onChange={(e) => handleInputChange("description", e.target.value)}
              placeholder="Describe your token and its community..."
              className="w-full p-3 border border-input rounded-md resize-none h-24"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="image">Token Image</Label>
            <div className="border-2 border-dashed border-border rounded-lg p-6 text-center">
              {formData.imageUrl ? (
                <div className="space-y-4">
                  <img
                    src={formData.imageUrl}
                    alt="Token preview"
                    className="w-24 h-24 object-cover rounded-full mx-auto"
                  />
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => document.getElementById('image-upload')?.click()}
                  >
                    Change Image
                  </Button>
                </div>
              ) : (
                <div className="space-y-4">
                  <Upload className="w-12 h-12 text-muted-foreground mx-auto" />
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => document.getElementById('image-upload')?.click()}
                  >
                    Upload Image
                  </Button>
                </div>
              )}
              <input
                id="image-upload"
                type="file"
                accept="image/*"
                onChange={handleImageUpload}
                className="hidden"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="supply">Initial Supply</Label>
            <Input
              id="supply"
              type="number"
              value={formData.initialSupply}
              onChange={(e) => handleInputChange("initialSupply", e.target.value)}
              placeholder="1000000000"
            />
            <p className="text-sm text-muted-foreground">
              Total number of tokens to mint
            </p>
          </div>

          <Button 
            type="submit" 
            className="w-full" 
            size="lg"
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                Creating Token...
              </>
            ) : (
              "Create Token (0.01 ETH)"
            )}
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}