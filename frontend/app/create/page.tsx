'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { TokenCreationForm } from '@/components/create/token-creation-form'
import { PreviewCard } from '@/components/create/preview-card'
import { CreationGuide } from '@/components/create/creation-guide'

export default function CreatePage() {
  const router = useRouter()
  const [tokenData, setTokenData] = useState({
    name: '',
    symbol: '',
    description: '',
    imageUrl: '',
    twitter: '',
    telegram: '',
    website: '',
  })

  const handleTokenCreated = (tokenAddress: string) => {
    router.push(`/token/${tokenAddress}`)
  }

  return (
    <div className="container mx-auto px-4 py-12">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-5xl font-bold text-center mb-4">
          Launch Your Token
        </h1>
        <p className="text-xl text-center text-muted-foreground mb-12">
          Create your meme token with bonding curves and automatic DEX graduation
        </p>

        <div className="grid lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <TokenCreationForm 
              onTokenDataChange={setTokenData}
              onTokenCreated={handleTokenCreated}
            />
          </div>
          <div className="space-y-6">
            <PreviewCard tokenData={tokenData} />
            <CreationGuide />
          </div>
        </div>
      </div>
    </div>
  )
}