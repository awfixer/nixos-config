# NixOS Configuration Documentation Website

This directory contains the source code for the documentation website built with [VitePress](https://vitepress.dev/).

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 📁 Structure

```
docs/
├── .vitepress/
│   ├── config.mts          # VitePress configuration
│   └── theme/              # Custom theme files
├── public/                 # Static assets
├── *.md                   # Documentation pages
├── package.json           # Dependencies
└── vercel.json           # Vercel deployment config
```

## 🛠️ Development

### Adding New Pages

1. Create a new `.md` file in the docs directory
2. Add frontmatter with title and description
3. Update navigation in `.vitepress/config.mts`

### Styling

Custom styles are in `.vitepress/theme/custom.css`. The theme extends the default VitePress theme with NixOS-specific styling.

### Assets

Place static assets in the `public/` directory. They'll be available at the root URL.

## 🚀 Deployment

### Vercel (Recommended)

1. Connect your GitHub repository to Vercel
2. Set the root directory to `docs`
3. Vercel will automatically detect and deploy the VitePress site

### Manual Deployment

```bash
# Build the site
npm run build

# Deploy the .vitepress/dist directory
```

## 📝 Writing Documentation

### Frontmatter

Each page should include frontmatter:

```yaml
---
title: Page Title
description: Page description for SEO
---
```

### VitePress Features

- **Markdown Extensions**: Enhanced markdown with custom containers
- **Code Highlighting**: Automatic syntax highlighting
- **Search**: Built-in local search
- **Navigation**: Automatic sidebar and navigation
- **Responsive Design**: Mobile-friendly layout

### Custom Containers

```markdown
::: tip
This is a tip container
:::

::: warning
This is a warning container
:::

::: danger
This is a danger container
:::

::: info
This is an info container
:::
```

### Code Blocks

````markdown
```bash
# Command examples
sudo nixos-rebuild switch --flake .#nixos
```

```nix
# Nix code examples
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    firefox
  ];
}
```
````

## 🎨 Customization

### Theme Colors

Edit CSS variables in `.vitepress/theme/custom.css`:

```css
:root {
  --vp-c-brand-1: #5f67ee;
  --vp-c-brand-2: #4e56d8;
  --vp-c-brand-3: #3d45c2;
}
```

### Logo and Branding

- Logo: `public/nixos-logo.svg`
- Hero image: `public/nixos-hero.svg`
- Favicon: Automatically generated from logo

## 📊 Analytics

Analytics can be added through:
- Vercel Analytics (automatic on Vercel)
- Google Analytics (add to config)
- Custom analytics solutions

## 🔧 Configuration

Key configuration files:

- **`.vitepress/config.mts`**: Main VitePress configuration
- **`package.json`**: Dependencies and scripts
- **`vercel.json`**: Vercel deployment settings
- **`.gitignore`**: Files to ignore in Git

## 🐛 Troubleshooting

### Build Issues

1. Check Node.js version (18+ required)
2. Clear cache: `rm -rf .vitepress/cache`
3. Reinstall dependencies: `rm -rf node_modules && npm install`

### Development Server Issues

1. Check port availability (default 5173)
2. Verify configuration syntax
3. Check for syntax errors in markdown files

### Deployment Issues

1. Verify build command in deployment platform
2. Check output directory setting
3. Ensure all dependencies are in `package.json`

## 📚 Resources

- [VitePress Documentation](https://vitepress.dev/)
- [Markdown Syntax](https://commonmark.org/)
- [Vue.js Guide](https://vuejs.org/guide/) (for advanced customization)

---

Built with ❤️ using [VitePress](https://vitepress.dev/)