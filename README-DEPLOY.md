# How to Deploy the Accelerate AI Site

This guide walks you through setting up and using `deploy.sh` to update the
site -- no GitHub experience required.

---

## One-Time Setup (5 minutes)

### 1. Get a GitHub Personal Access Token

You need a token so the script can push changes on your behalf.

1. Go to <https://github.com/settings/tokens?type=beta> (fine-grained tokens)
2. Click **Generate new token**
3. Fill in:
   - **Token name:** `accelerate-ai-deploy`
   - **Expiration:** 90 days (you can renew later)
   - **Repository access:** select **Only select repositories**, then pick
     `michael-brennan-ck/accelerate-ai-site`
   - **Permissions > Repository permissions:**
     - **Contents:** Read and write
     - Everything else can stay at "No access"
4. Click **Generate token**
5. **Copy the token** (starts with `github_pat_...`). You won't see it again.

### 2. Save the Token

Add this line to your shell profile so it's always available:

```bash
# Add to ~/.zshrc (Mac) or ~/.bashrc (Linux)
export DEPLOY_TOKEN="github_pat_YOUR_TOKEN_HERE"
```

Then reload your terminal or run:

```bash
source ~/.zshrc
```

### 3. Make the Script Executable

```bash
chmod +x deploy.sh
```

---

## Deploying

### Update the site with a new HTML file

```bash
./deploy.sh my-updated-page.html
```

Or, if your file is named `index.html` in the current directory:

```bash
./deploy.sh
```

The script will:
1. Clone the repo to a temporary folder
2. Replace `index.html` with your file
3. Commit and push the change
4. Clean up and print the live URL

The site updates automatically within 1-2 minutes.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `ERROR: DEPLOY_TOKEN is not set` | Run `export DEPLOY_TOKEN="your_token"` or add it to `~/.zshrc` |
| `ERROR: Failed to clone` | Your token may be expired -- generate a new one (step 1 above) |
| `ERROR: Push failed` | Your token may lack write permission -- regenerate with Contents read/write |
| `No changes detected` | The file you're deploying is identical to what's already live |

---

## Advanced Options

You can override defaults with environment variables:

| Variable | Default | Description |
|---|---|---|
| `DEPLOY_TOKEN` | *(required)* | GitHub personal access token |
| `DEPLOY_REPO` | `michael-brennan-ck/accelerate-ai-site` | Target repository |
| `DEPLOY_BRANCH` | `main` | Branch to push to |
| `SITE_URL` | *(derived from repo)* | Override the printed URL |

Example with overrides:

```bash
DEPLOY_REPO="my-org/my-site" ./deploy.sh page.html
```

---

## Renewing an Expired Token

Tokens expire after the duration you chose (default 90 days). When that
happens, the script will fail with a clone error. Just repeat step 1 above
to generate a fresh token, then update `DEPLOY_TOKEN` in your `~/.zshrc`.
