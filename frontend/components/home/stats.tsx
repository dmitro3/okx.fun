'use client'

import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { formatNumber } from '@/lib/utils'

export function Stats() {
  const [stats, setStats] = useState({
    totalTokens: 0,
    totalVolume: 0,
    totalUsers: 0,
    graduatedTokens: 0,
  })

  useEffect(() => {
    // Simulate fetching stats - replace with actual API call
    setStats({
      totalTokens: 1234,
      totalVolume: 5678900,
      totalUsers: 8901,
      graduatedTokens: 234,
    })
  }, [])

  return (
    <section className="py-12 border-y">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <div className="text-3xl lg:text-4xl font-bold">
              {formatNumber(stats.totalTokens)}
            </div>
            <div className="text-muted-foreground mt-1">Total Tokens</div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <div className="text-3xl lg:text-4xl font-bold">
              ${formatNumber(stats.totalVolume)}
            </div>
            <div className="text-muted-foreground mt-1">Total Volume</div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <div className="text-3xl lg:text-4xl font-bold">
              {formatNumber(stats.totalUsers)}
            </div>
            <div className="text-muted-foreground mt-1">Active Users</div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            viewport={{ once: true }}
            className="text-center"
          >
            <div className="text-3xl lg:text-4xl font-bold">
              {formatNumber(stats.graduatedTokens)}
            </div>
            <div className="text-muted-foreground mt-1">Graduated to DEX</div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}