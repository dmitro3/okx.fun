'use client'

import { motion } from 'framer-motion'
import { 
  Zap, 
  Shield, 
  TrendingUp, 
  Users, 
  Lock, 
  BarChart3 
} from 'lucide-react'

const features = [
  {
    icon: Zap,
    title: 'Instant Launch',
    description: 'Deploy your token in seconds with our streamlined creation process',
    color: 'text-yellow-500',
    bgColor: 'bg-yellow-500/10',
  },
  {
    icon: TrendingUp,
    title: 'Bonding Curves',
    description: 'Fair price discovery with mathematical bonding curve mechanics',
    color: 'text-green-500',
    bgColor: 'bg-green-500/10',
  },
  {
    icon: Shield,
    title: 'Secure & Audited',
    description: 'Smart contracts audited by leading security firms',
    color: 'text-blue-500',
    bgColor: 'bg-blue-500/10',
  },
  {
    icon: Users,
    title: 'Community First',
    description: 'No VCs, no private sales - 100% fair launch for everyone',
    color: 'text-purple-500',
    bgColor: 'bg-purple-500/10',
  },
  {
    icon: Lock,
    title: 'Liquidity Lock',
    description: 'Permanent liquidity lock when graduating to OkieSwap',
    color: 'text-red-500',
    bgColor: 'bg-red-500/10',
  },
  {
    icon: BarChart3,
    title: 'Real-Time Analytics',
    description: 'Advanced charts and analytics for informed trading decisions',
    color: 'text-indigo-500',
    bgColor: 'bg-indigo-500/10',
  },
]

export function Features() {
  return (
    <section className="py-20 px-4">
      <div className="container mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <h2 className="text-4xl font-bold mb-4">Why Choose X Layer Fun?</h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            The most advanced meme token launchpad with cutting-edge features
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              viewport={{ once: true }}
              className="bg-card rounded-lg p-6 border hover:shadow-lg transition-shadow"
            >
              <div className={`w-12 h-12 rounded-full ${feature.bgColor} flex items-center justify-center mb-4`}>
                <feature.icon className={`h-6 w-6 ${feature.color}`} />
              </div>
              <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
              <p className="text-muted-foreground">{feature.description}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}