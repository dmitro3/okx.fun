import Link from 'next/link'
import { Twitter, Github, MessageCircle, FileText } from 'lucide-react'

export function Footer() {
  return (
    <footer className="border-t bg-background">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          <div>
            <h3 className="font-semibold mb-3">Product</h3>
            <ul className="space-y-2">
              <li>
                <Link href="/tokens" className="text-muted-foreground hover:text-foreground">
                  Explore Tokens
                </Link>
              </li>
              <li>
                <Link href="/create" className="text-muted-foreground hover:text-foreground">
                  Launch Token
                </Link>
              </li>
              <li>
                <Link href="/portfolio" className="text-muted-foreground hover:text-foreground">
                  Portfolio
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="font-semibold mb-3">Resources</h3>
            <ul className="space-y-2">
              <li>
                <Link href="/docs" className="text-muted-foreground hover:text-foreground">
                  Documentation
                </Link>
              </li>
              <li>
                <Link href="/docs/api" className="text-muted-foreground hover:text-foreground">
                  API
                </Link>
              </li>
              <li>
                <Link href="/docs/contracts" className="text-muted-foreground hover:text-foreground">
                  Smart Contracts
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="font-semibold mb-3">Community</h3>
            <ul className="space-y-2">
              <li>
                <a href="https://twitter.com/xlayerfun" target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-foreground flex items-center gap-2">
                  <Twitter className="h-4 w-4" />
                  Twitter
                </a>
              </li>
              <li>
                <a href="https://t.me/xlayerfun" target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-foreground flex items-center gap-2">
                  <MessageCircle className="h-4 w-4" />
                  Telegram
                </a>
              </li>
              <li>
                <a href="https://github.com/xlayerfun" target="_blank" rel="noopener noreferrer" className="text-muted-foreground hover:text-foreground flex items-center gap-2">
                  <Github className="h-4 w-4" />
                  GitHub
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="font-semibold mb-3">Legal</h3>
            <ul className="space-y-2">
              <li>
                <Link href="/terms" className="text-muted-foreground hover:text-foreground">
                  Terms of Service
                </Link>
              </li>
              <li>
                <Link href="/privacy" className="text-muted-foreground hover:text-foreground">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/disclaimer" className="text-muted-foreground hover:text-foreground">
                  Disclaimer
                </Link>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-8 pt-8 border-t text-center text-muted-foreground">
          <p>© 2025 X Layer Fun. All rights reserved.</p>
        </div>
      </div>
    </footer>
  )
}