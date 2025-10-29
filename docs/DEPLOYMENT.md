# Deploying to Vercel

This guide covers how to deploy the documentation website to Vercel.

## Prerequisites

1. **Vercel Account**: Sign up at [vercel.com](https://vercel.com)
2. **GitHub Repository**: Ensure your config is in a GitHub repository
3. **Node.js**: Version 18+ for local development

## Quick Deploy

### Option 1: One-Click Deploy

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fawfixer%2Fnixos-config&project-name=nixos-docs&repository-name=nixos-config)

### Option 2: Manual Setup

1. **Connect Repository**
   - Go to [Vercel Dashboard](https://vercel.com/dashboard)
   - Click "New Project"
   - Import your GitHub repository

2. **Configure Build Settings**
   ```
   Framework Preset: Other
   Root Directory: docs
   Build Command: npm run build
   Output Directory: .vitepress/dist
   Install Command: npm install
   ```

3. **Deploy**
   - Click "Deploy"
   - Wait for build to complete
   - Your site will be available at `https://your-project.vercel.app`

## Local Development

```bash
# Navigate to docs directory
cd docs

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Custom Domain

1. **Add Domain**
   - Go to Project Settings → Domains
   - Add your custom domain
   - Follow DNS configuration instructions

2. **SSL Certificate**
   - Automatic SSL is provided by Vercel
   - Certificates are renewed automatically

## Environment Variables

If you need environment variables:

1. Go to Project Settings → Environment Variables
2. Add required variables
3. Redeploy the project

## Build Configuration

The site uses these key configuration files:

- `package.json` - Dependencies and scripts
- `.vitepress/config.mts` - VitePress configuration
- `vercel.json` - Vercel deployment settings
- `.gitignore` - Files to ignore

## Automatic Deployments

Vercel automatically deploys:
- **Production**: Commits to `main` branch
- **Preview**: Pull requests and other branches

## Performance Optimization

The site includes:
- **Static Site Generation**: Pre-built HTML files
- **Image Optimization**: Automatic image processing
- **CDN**: Global content delivery network
- **Caching**: Optimal cache headers
- **Compression**: Gzip/Brotli compression

## Monitoring

Monitor your site:
- **Analytics**: View in Vercel dashboard
- **Performance**: Lighthouse scores
- **Uptime**: Automatic monitoring
- **Logs**: Build and runtime logs

## Troubleshooting

### Build Failures

1. Check build logs in Vercel dashboard
2. Verify all dependencies are listed in `package.json`
3. Ensure Node.js version compatibility

### 404 Errors

1. Check file paths and routing
2. Verify `vercel.json` configuration
3. Ensure clean URLs are enabled

### Performance Issues

1. Review Lighthouse recommendations
2. Optimize images and assets
3. Check bundle size analysis

## Advanced Configuration

### Custom Headers

Edit `vercel.json` to add custom headers:

```json
{
  "headers": [
    {
      "source": "/docs/(.*)",
      "headers": [
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        }
      ]
    }
  ]
}
```

### Redirects

Add redirects in `vercel.json`:

```json
{
  "redirects": [
    {
      "source": "/old-path",
      "destination": "/new-path",
      "permanent": true
    }
  ]
}
```

## Costs

- **Hobby Plan**: Free for personal projects
- **Pro Plan**: $20/month for teams
- **Enterprise**: Custom pricing

The documentation site should fit comfortably within the free tier limits.

---

For more information, see the [Vercel Documentation](https://vercel.com/docs).