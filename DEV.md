# Development Environment Setup

This document explains how to set up the development environment for this project.

## NixOS / Nix Users

This project includes a Nix flake for reproducible development environments.

### Prerequisites

- Nix with flakes enabled
- If flakes are not enabled, add to your `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

### Enter Development Environment

```bash
# Enter the dev shell
nix develop

# Or run a command directly
nix develop --command npm run docs:dev
```

### Using direnv (Optional)

For automatic environment loading when entering the directory:

1. Install direnv and nix-direnv
2. Create `.envrc` file:

```bash
echo "use flake" > .envrc
direnv allow
```

Now the environment will automatically load when you `cd` into the project.

### What's Included

The Nix development shell provides:

| Tool | Version | Description |
|------|---------|-------------|
| Node.js | 20.x LTS | JavaScript runtime |
| npm | (bundled) | Package manager |

### Quick Start

```bash
# 1. Enter dev environment
nix develop

# 2. Install project dependencies
npm install

# 3. Start development server
npm run docs:dev

# 4. Open in browser
# Visit: http://localhost:5173
```

## Non-Nix Users

For users without Nix, ensure you have:

- Node.js >= 18
- npm >= 9

Then follow the standard setup:

```bash
npm install
npm run docs:dev
```

## Available Scripts

| Command | Description |
|---------|-------------|
| `npm run docs:dev` | Start local development server |
| `npm run docs:build` | Build documentation for production |
| `npm run docs:preview` | Preview production build locally |

