import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "AWFixer's NixOS Configuration",
  description: "Complete documentation for a modular NixOS configuration using Nix Flakes",
  
  // Base URL for deployment
  base: '/',
  
  // Clean URLs
  cleanUrls: true,
  
  // Theme configuration
  themeConfig: {
    // Logo
    logo: '/nixos-logo.svg',
    
    // Site title in nav
    siteTitle: "AWFixer's NixOS Docs",
    
    // Navigation menu
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/getting-started' },
      { text: 'Guides', link: '/modules' },
      { 
        text: 'Reference',
        items: [
          { text: 'Modules', link: '/modules' },
          { text: 'Packages', link: '/packages' },
          { text: 'Maintenance', link: '/maintenance' }
        ]
      },
      { text: 'Development', link: '/development' }
    ],

    // Sidebar configuration
    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Quick Start', link: '/getting-started' },
          { text: 'Architecture', link: '/architecture' }
        ]
      },
      {
        text: 'Core Concepts',
        items: [
          { text: 'Module System', link: '/modules' },
          { text: 'Package Management', link: '/packages' },
          { text: 'Configuration Structure', link: '/structure' }
        ]
      },
      {
        text: 'User Guides',
        items: [
          { text: 'Installation', link: '/installation' },
          { text: 'Customization', link: '/customization' },
          { text: 'Troubleshooting', link: '/troubleshooting' }
        ]
      },
      {
        text: 'Administration',
        items: [
          { text: 'Maintenance', link: '/maintenance' },
          { text: 'Updates', link: '/updates' },
          { text: 'Backup & Recovery', link: '/backup' }
        ]
      },
      {
        text: 'Development',
        items: [
          { text: 'Contributing', link: '/development' },
          { text: 'Module Development', link: '/module-development' },
          { text: 'Testing', link: '/testing' }
        ]
      },
      {
        text: 'Reference',
        items: [
          { text: 'Command Reference', link: '/commands' },
          { text: 'FAQ', link: '/faq' },
          { text: 'Resources', link: '/resources' }
        ]
      }
    ],

    // Social links
    socialLinks: [
      { icon: 'github', link: 'https://github.com/awfixer/nixos-config' }
    ],

    // Footer
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024 AWFixer'
    },

    // Search
    search: {
      provider: 'local',
      options: {
        translations: {
          button: {
            buttonText: 'Search docs',
            buttonAriaLabel: 'Search docs'
          },
          modal: {
            noResultsText: 'No results for',
            resetButtonTitle: 'Clear search',
            footer: {
              selectText: 'to select',
              navigateText: 'to navigate'
            }
          }
        }
      }
    },

    // Edit link
    editLink: {
      pattern: 'https://github.com/awfixer/nixos-config/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    // Last updated
    lastUpdated: {
      text: 'Last updated',
      formatOptions: {
        dateStyle: 'short',
        timeStyle: 'medium'
      }
    },

    // Outline
    outline: {
      level: [2, 3],
      label: 'On this page'
    },

    // Previous/next links
    docFooter: {
      prev: 'Previous page',
      next: 'Next page'
    }
  },

  // Markdown configuration
  markdown: {
    // Code block themes
    theme: {
      light: 'github-light',
      dark: 'github-dark'
    },
    
    // Line numbers in code blocks
    lineNumbers: true,
    
    // Code copy button
    code: {
      copyButtonTitle: 'Copy to clipboard',
      copyButtonSuccessTitle: 'Copied!'
    }
  },

  // Head configuration
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/nixos-logo.svg' }],
    ['meta', { name: 'theme-color', content: '#5f67ee' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en' }],
    ['meta', { property: 'og:title', content: "AWFixer's NixOS Configuration | Complete Documentation" }],
    ['meta', { property: 'og:site_name', content: "AWFixer's NixOS Docs" }],
    ['meta', { property: 'og:url', content: 'https://nixos-docs.awfixer.dev/' }],
    ['meta', { property: 'og:description', content: 'Comprehensive documentation for a modular NixOS configuration using Nix Flakes, Home Manager, and modern development practices.' }]
  ],

  // Sitemap
  sitemap: {
    hostname: 'https://nixos-docs.awfixer.dev'
  }
})