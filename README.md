# ViteSEO Auto-Deploy

Automatic SSH-based deployment for ViteSEO website projects using GitHub Actions. Push to a branch, and your server updates automatically.

> ⚠️ **Important:** This deployment system requires a VPS or server that supports SSH commands. Managed hosting platforms that don't provide SSH access are not compatible.

## Features

- 🚀 **Automatic deployments** - Push to `main` or `dev` and deploy automatically
- 🔀 **Multi-environment support** - Separate production and staging servers
- 🔐 **Secure SSH connections** - Key-based authentication with retry logic
- 📝 **Detailed logging** - All deployments logged with timestamps
- ⚡ **Fast installation** - One command to add to any git repository

## Quick Start

### 1. Install

Navigate to your git repository and run:

```bash
curl -sSL https://raw.githubusercontent.com/ViteSEO-OPC/viteseo-auto-deploy/main/install.sh | bash
```

### 2. Configure GitHub Secrets

Go to your repository **Settings → Secrets and variables → Actions** and add:

| Secret | Description | Example |
|--------|-------------|---------|
| `PROD_BRANCH` | Branch for production deploys | `main` |
| `STAGING_BRANCH` | Branch for staging deploys | `dev` |
| `PROD_SSH_PRIVATE_KEY` | SSH private key for production | `-----BEGIN OPENSSH...` |
| `PROD_SSH_HOST` | Production server hostname/IP | `prod.example.com` |
| `PROD_SSH_PORT` | SSH port | `22` |
| `PROD_SSH_USER` | SSH username | `deploy` |
| `PROD_THEME_DIR` | Project path on server | `/var/www/html/myproject` |

Add the following **staging** secrets (explicitly listed here so you can copy/paste them without guessing):

| Secret | Description | Example |
|--------|-------------|---------|
| `STAGING_SSH_PRIVATE_KEY` | SSH private key for staging | `-----BEGIN OPENSSH...` |
| `STAGING_SSH_HOST` | Staging server hostname/IP | `staging.example.com` |
| `STAGING_SSH_PORT` | SSH port | `22` |
| `STAGING_SSH_USER` | SSH username | `deploy` |
| `STAGING_THEME_DIR` | Project path on server | `/var/www/html/myproject-staging` |

You should also set `STAGING_BRANCH` (already listed above) so the workflow knows which branch triggers staging deploys.

### How to get/create the SSH keys (production + staging)

You need **one private key per environment** and the matching public key must be placed on the target server. You can either use the helper script included in this repo or create the keys manually. Both approaches work; choose one and repeat for **prod** and **staging**.

#### Option A: Use the helper script (recommended)

The helper script generates an SSH key pair for you:

```bash
./deploy/setup-deployment.sh
```

When it finishes, it will tell you where the key files were created. Use those paths in the steps below.

#### Option B: Generate keys manually

Run this locally for **each environment** (use different filenames):

```bash
# Production key
ssh-keygen -t ed25519 -C "viteseo-prod-deploy" -f ~/.ssh/viteseo_prod_deploy -N ""

# Staging key
ssh-keygen -t ed25519 -C "viteseo-staging-deploy" -f ~/.ssh/viteseo_staging_deploy -N ""
```

Notes:
- The `-N ""` creates a key with **no passphrase**, which is required for non-interactive GitHub Actions.
- Keep prod and staging keys **separate** so you can revoke one without affecting the other.

#### Install the public key on each server

1) Copy the **public key** (ends with `.pub`) for the environment:

```bash
# Example for production
cat ~/.ssh/viteseo_prod_deploy.pub
```

2) On the target server (prod or staging), add that public key to the deploy user's `authorized_keys`:

```bash
# On the server
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "<PASTE_PUBLIC_KEY_HERE>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

3) Test the key locally before saving secrets (replace host/user/port):

```bash
ssh -i ~/.ssh/viteseo_prod_deploy -p 22 deploy@prod.example.com
```

You should log in without a password prompt. If this fails, fix it now before moving on.

#### Save the private key into GitHub Secrets

For each environment, open the **private key file** (no `.pub`):

```bash
# Example for production
cat ~/.ssh/viteseo_prod_deploy
```

Copy the **entire** output (including the BEGIN/END lines) and paste it into:
- `PROD_SSH_PRIVATE_KEY` for production
- `STAGING_SSH_PRIVATE_KEY` for staging

#### Set the remaining secrets

For each environment, set:
- `*_SSH_HOST`: The server hostname or IP.
- `*_SSH_PORT`: The SSH port (often `22`).
- `*_SSH_USER`: The Linux user on that server (often `deploy`).
- `*_THEME_DIR`: The absolute path to the repo on that server.

Example values:
- Prod: `/var/www/html/myproject`
- Staging: `/var/www/html/myproject-staging`

### 3. Set Up Your Server

```bash
# Clone your repo on the server
git clone <your-repo-url> /path/to/project
cd /path/to/project

# Make the pull script executable
chmod +x deploy/pull.sh
```

### 4. Push and Deploy!

```bash
git add .
git commit -m "Add auto-deployment"
git push origin main  # Triggers production deployment
```

## Installation Options

### Basic Installation

```bash
# Install in current directory
curl -sSL https://raw.githubusercontent.com/ViteSEO-OPC/viteseo-auto-deploy/main/install.sh | bash
```

### With Options

```bash
# Verbose output (see what's happening)
curl -sSL https://raw.githubusercontent.com/ViteSEO-OPC/viteseo-auto-deploy/main/install.sh | bash -s -- -v

# Force overwrite existing files + verbose
curl -sSL https://raw.githubusercontent.com/ViteSEO-OPC/viteseo-auto-deploy/main/install.sh | bash -s -- -f -v

# Install in a specific directory
curl -sSL https://raw.githubusercontent.com/ViteSEO-OPC/viteseo-auto-deploy/main/install.sh | bash -s -- /path/to/repo

# All options combined
curl -sSL https://raw.githubusercontent.com/ViteSEO-OPC/viteseo-auto-deploy/main/install.sh | bash -s -- -f -v /path/to/repo
```

### Local Installation (Offline)

```bash
# Clone this repo first
git clone https://github.com/ViteSEO-OPC/viteseo-auto-deploy.git

# Install to another repository
./viteseo-auto-deploy/install.sh --local ./viteseo-auto-deploy /path/to/target-repo
```

### Command Breakdown

```
curl -sSL <url> | bash -s -- [options] [target]
     |||              |  |
     |||              |  └─ End of bash options; everything after goes to script
     |||              └──── Read from stdin (REQUIRED when piping)
     ||└──────────────────── Follow redirects
     |└───────────────────── Show errors (with -s)
     └────────────────────── Silent mode (no progress bar)
```

## What Gets Installed

| File | Description |
|------|-------------|
| `.github/workflows/deploy.yml` | GitHub Actions workflow for automatic deployments |
| `.github/workflows/DEPLOYMENT_SETUP.md` | Detailed setup guide |
| `deploy/pull.sh` | Server-side script that pulls latest code |
| `deploy/setup-deployment.sh` | Helper to generate SSH keys |
| `deploy/QUICK_REFERENCE.md` | Quick reference guide |

## How It Works

```
┌─────────────────────┐
│  Push to main/dev   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  GitHub Actions     │
│  detects branch     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  SSH into server    │
│  (prod or staging)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Run pull.sh        │
│  → git pull         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  ✓ Server updated!  │
└─────────────────────┘
```

## Available Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-f, --force` | Overwrite existing files |
| `-q, --quiet` | Minimal output (errors only) |
| `-v, --verbose` | Verbose/debug output |
| `--no-color` | Disable colored output |
| `--version` | Show version |
| `--local <path>` | Use local source instead of downloading |

## Requirements

- Target directory must be a **git repository**
- `curl` or `wget` installed
- Write permissions in target directory

## Documentation

After installation, see:

- **Quick Start**: `cat deploy/QUICK_REFERENCE.md`
- **Full Guide**: `cat .github/workflows/DEPLOYMENT_SETUP.md`

## Troubleshooting

### "Not a git repository"

The install script must be run inside a git repository:

```bash
cd /path/to/your/project
git init  # if not already a git repo
curl -sSL https://raw.githubusercontent.com/ViteSEO-OPC/viteseo-auto-deploy/main/install.sh | bash
```

### "Cannot reach GitHub"

Check your internet connection. For offline installation, use `--local` mode.

### "Permission denied" during deployment

- Verify SSH keys are correctly configured
- Check `authorized_keys` on the server
- Ensure `deploy/pull.sh` is executable: `chmod +x deploy/pull.sh`

## License

MIT

## Contributing

Issues and pull requests are welcome!
