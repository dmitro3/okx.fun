'use client'

import { Hero } from '@/components/home/hero'
import { Features } from '@/components/home/features'
import { TokenGrid } from '@/components/tokens/token-grid'
import { Stats } from '@/components/home/stats'
import { HowItWorks } from '@/components/home/how-it-works'

export default function HomePage() {
  return (
    <div className="flex flex-col">
      <Hero />
      <Stats />
      <Features />
      <HowItWorks />
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <h2 className="text-4xl font-bold text-center mb-12">
            Trending Tokens
          </h2>
          <TokenGrid limit={8} />
        </div>
      </section>
    </div>
  )
}