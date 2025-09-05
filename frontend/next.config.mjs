/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
      {
        protocol: 'http',
        hostname: '**',
      },
    ],
    // Optionally, you can set 'dangerouslyAllowSVG' or 'unoptimized' if needed for your use case
    // dangerouslyAllowSVG: true,
    // unoptimized: true,
  },
}

export default nextConfig
