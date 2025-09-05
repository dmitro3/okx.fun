'use client'

import { motion } from 'framer-motion'
import { ArrowRight, Rocket, TrendingUp, Zap } from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export function Hero() {
  return (
    <section className="relative overflow-hidden py-20 lg:py-32">
      {/* Background Effects */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-secondary/5" />
      <div className="absolute inset-0 bg-[url('/grid.svg')] bg-center opacity-5" />
      
      <div className="container relative mx-auto px-4">
        <div className="mx-auto max-w-5xl text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h1 className="mb-6 text-5xl font-bold tracking-tight lg:text-7xl">
              Launch Your Meme Token on{' '}
              <span className="gradient-text bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 bg-clip-text text-transparent">
                X Layer
              </span>
            </h1>
          </motion.div>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="mb-8 text-xl text-muted-foreground lg:text-2xl"
          >
            Create tokens with bonding curves, trade with zero friction, and graduate to OkieSwap automatically
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="flex flex-col gap-4 sm:flex-row sm:justify-center"
          >
            <Link href="/create">
              <Button size="lg" className="gap-2 text-lg">
                <Rocket className="h-5 w-5" />
                Launch Token
              </Button>
            </Link>
            <Link href="/tokens">
              <Button size="lg" variant="outline" className="gap-2 text-lg">
                Explore Tokens
                <ArrowRight className="h-5 w-5" />
              </Button>
            </Link>
          </motion.div>

          {/* Stats */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="mt-16 grid gap-8 sm:grid-cols-3"
          >
            <div className="flex flex-col items-center">
              <div className="mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
                <Zap className="h-6 w-6 text-primary" />
              </div>
              <div className="text-3xl font-bold">$0</div>
              <div className="text-sm text-muted-foreground">Listing Fees</div>
            </div>
            <div className="flex flex-col items-center">
              <div className="mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-green-500/10">
                <TrendingUp className="h-6 w-6 text-green-500" />
              </div>
              <div className="text-3xl font-bold">500 OKB</div>
              <div className="text-sm text-muted-foreground">To Graduate</div>
            </div>
            <div className="flex flex-col items-center">
              <div className="mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-purple-500/10">
                <Rocket className="h-6 w-6 text-purple-500" />
              </div>
              <div className="text-3xl font-bold">100%</div>
              <div className="text-sm text-muted-foreground">Fair Launch</div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}