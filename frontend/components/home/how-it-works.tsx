'use client'

import { motion } from 'framer-motion'
import { Rocket, TrendingUp, Trophy, Coins } from 'lucide-react'

const steps = [
  {
    icon: Rocket,
    title: 'Create Token',
    description: 'Launch your meme token with custom name, symbol, and metadata',
  },
  {
    icon: TrendingUp,
    title: 'Trade on Curve',
    description: 'Price discovery through bonding curve with instant liquidity',
  },
  {
    icon: Coins,
    title: 'Collect 500 OKB',
    description: 'Community trades until 500 OKB threshold is reached',
  },
  {
    icon: Trophy,
    title: 'Graduate to DEX',
    description: 'Automatic listing on OkieSwap with locked liquidity',
  },
]

export function HowItWorks() {
  return (
    <section className="py-20 px-4 bg-muted/30">
      <div className="container mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <h2 className="text-4xl font-bold mb-4">How It Works</h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            From creation to DEX graduation in four simple steps
          </p>
        </motion.div>

        <div className="relative">
          {/* Connection Line */}
          <div className="hidden lg:block absolute top-1/2 left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-primary to-transparent -translate-y-1/2" />

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {steps.map((step, index) => (
              <motion.div
                key={step.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                viewport={{ once: true }}
                className="relative"
              >
                <div className="bg-background rounded-lg p-6 text-center">
                  <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
                    <step.icon className="h-8 w-8 text-primary" />
                  </div>
                  <div className="text-sm text-primary font-semibold mb-2">
                    Step {index + 1}
                  </div>
                  <h3 className="text-xl font-semibold mb-2">{step.title}</h3>
                  <p className="text-muted-foreground">{step.description}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}