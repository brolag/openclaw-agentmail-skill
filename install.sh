#!/bin/bash
# Install AgentMail skill for OpenClaw
# https://github.com/brolag/openclaw-agentmail-skill
# v1.3.0 - Fixed API version (v0 not v1)
#
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/brolag/openclaw-agentmail-skill/main/install.sh | bash
#
# With configuration:
#   AGENTMAIL_API_KEY="your-key" AGENTMAIL_EMAIL="agent@agentmail.to" \
#     curl -fsSL https://raw.githubusercontent.com/brolag/openclaw-agentmail-skill/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REPO_URL="https://raw.githubusercontent.com/brolag/openclaw-agentmail-skill/main"

echo -e "${GREEN}🦞 OpenClaw AgentMail Skill Installer${NC}"
echo ""

# Detect if running interactively (not piped)
if [ -t 0 ]; then
    INTERACTIVE=true
else
    INTERACTIVE=false
fi

# Detect OpenClaw workspace
if [ -d "$HOME/.openclaw/workspace" ]; then
    WORKSPACE="$HOME/.openclaw/workspace"
elif [ -d "/root/.openclaw/workspace" ]; then
    WORKSPACE="/root/.openclaw/workspace"
else
    echo -e "${RED}❌ Error: OpenClaw workspace not found${NC}"
    echo "Make sure OpenClaw is installed and initialized."
    exit 1
fi

SKILL_DIR="$WORKSPACE/skills/agentmail"

echo "📁 Workspace: $WORKSPACE"
echo "📁 Skill dir: $SKILL_DIR"
echo ""

# Create directory
mkdir -p "$SKILL_DIR"

# Get SKILL.md - try local first, then download from GitHub
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null)" || SCRIPT_DIR=""

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/SKILL.md" ]; then
    cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
    echo -e "${GREEN}✅ Skill installed (from local)${NC}"
else
    echo "📥 Downloading SKILL.md from GitHub..."
    curl -fsSL "$REPO_URL/SKILL.md" -o "$SKILL_DIR/SKILL.md"
    echo -e "${GREEN}✅ Skill installed (from GitHub)${NC}"
fi

# Configure API key
if [ -n "$AGENTMAIL_API_KEY" ]; then
    echo -e "${GREEN}✅ API key found in environment${NC}"

    # Save to shell config if not already there
    SHELL_RC="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

    if ! grep -q "AGENTMAIL_API_KEY" "$SHELL_RC" 2>/dev/null; then
        echo "export AGENTMAIL_API_KEY=\"$AGENTMAIL_API_KEY\"" >> "$SHELL_RC"
        echo -e "${GREEN}✅ API key saved to $SHELL_RC${NC}"
    fi
elif [ "$INTERACTIVE" = true ]; then
    echo ""
    read -p "Enter your AgentMail API key (or press Enter to skip): " API_KEY

    if [ -n "$API_KEY" ]; then
        echo "🧪 Testing API key..."
        RESPONSE=$(curl -s "https://api.agentmail.to/v0/inboxes" \
            -H "Authorization: Bearer $API_KEY" 2>/dev/null)

        if echo "$RESPONSE" | grep -q "error\|unauthorized"; then
            echo -e "${RED}❌ API key appears invalid${NC}"
            echo "Response: $RESPONSE"
            echo "Continuing anyway - you can fix this later."
        else
            echo -e "${GREEN}✅ API key valid${NC}"
        fi

        SHELL_RC="$HOME/.bashrc"
        [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

        if grep -q "AGENTMAIL_API_KEY" "$SHELL_RC" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  API key already in $SHELL_RC - updating${NC}"
            sed -i.bak '/AGENTMAIL_API_KEY/d' "$SHELL_RC"
        fi

        echo "export AGENTMAIL_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
        export AGENTMAIL_API_KEY="$API_KEY"
        echo -e "${GREEN}✅ API key saved to $SHELL_RC${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No API key provided. Set it with:${NC}"
    echo "   export AGENTMAIL_API_KEY=\"your-key\""
fi

# Configure email address
if [ -n "$AGENTMAIL_EMAIL" ]; then
    EMAIL_ADDRESS="$AGENTMAIL_EMAIL"
    echo -e "${GREEN}✅ Email found in environment: $EMAIL_ADDRESS${NC}"
elif [ "$INTERACTIVE" = true ]; then
    echo ""
    read -p "Enter your AgentMail email (e.g., myagent@agentmail.to): " EMAIL_ADDRESS
    EMAIL_ADDRESS="${EMAIL_ADDRESS:-agent@agentmail.to}"
else
    EMAIL_ADDRESS="your-agent@agentmail.to"
    echo -e "${YELLOW}⚠️  Using placeholder email. Update with:${NC}"
    echo "   sed -i 's/your-agent@agentmail.to/YOUR_EMAIL/g' $SKILL_DIR/SKILL.md"
fi

# Update SKILL.md with actual email
sed -i.bak "s/your-agent@agentmail.to/$EMAIL_ADDRESS/g" "$SKILL_DIR/SKILL.md" 2>/dev/null || \
    sed -i '' "s/your-agent@agentmail.to/$EMAIL_ADDRESS/g" "$SKILL_DIR/SKILL.md"
rm -f "$SKILL_DIR/SKILL.md.bak"
echo -e "${GREEN}✅ Email set to $EMAIL_ADDRESS${NC}"

# Verify skill is detected
echo ""
echo "🔍 Verifying skill installation..."
if command -v openclaw &>/dev/null && openclaw skills list 2>/dev/null | grep -q "agentmail"; then
    echo -e "${GREEN}✅ Skill 'agentmail' detected by OpenClaw${NC}"
else
    echo -e "${YELLOW}⚠️  Skill may not be detected yet. Try: openclaw gateway restart${NC}"
fi

# Update IDENTITY.md
UPDATE_IDENTITY_FILE=false

if [ "$INTERACTIVE" = true ]; then
    echo ""
    read -p "Add email info to IDENTITY.md? (y/n): " UPDATE_IDENTITY
    if [ "$UPDATE_IDENTITY" = "y" ] || [ "$UPDATE_IDENTITY" = "Y" ]; then
        UPDATE_IDENTITY_FILE=true
    fi
elif [ -n "$AGENTMAIL_EMAIL" ]; then
    # Auto-update in non-interactive mode if email was provided
    UPDATE_IDENTITY_FILE=true
fi

if [ "$UPDATE_IDENTITY_FILE" = true ]; then
    # Check if already has email capabilities section
    if ! grep -q "## Email Capabilities" "$WORKSPACE/IDENTITY.md" 2>/dev/null; then
        cat >> "$WORKSPACE/IDENTITY.md" << EOF

## Email Capabilities

I have email via AgentMail API. My email address is: $EMAIL_ADDRESS

To check my inbox:
\`\`\`bash
curl -s "https://api.agentmail.to/v0/inboxes/$EMAIL_ADDRESS/messages?limit=10" \\
  -H "Authorization: Bearer \$AGENTMAIL_API_KEY" | jq '.messages[] | {id, from, subject, date}'
\`\`\`

To send email:
\`\`\`bash
curl -X POST "https://api.agentmail.to/v0/inboxes/$EMAIL_ADDRESS/messages" \\
  -H "Authorization: Bearer \$AGENTMAIL_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{"to": ["recipient@email.com"], "subject": "Subject", "body": "Message"}'
\`\`\`

Read the full skill at: $SKILL_DIR/SKILL.md
EOF
        echo -e "${GREEN}✅ Updated IDENTITY.md with email capabilities${NC}"
    else
        echo -e "${YELLOW}⚠️  IDENTITY.md already has email capabilities${NC}"
    fi
fi

# Restart gateway
if [ "$INTERACTIVE" = true ]; then
    echo ""
    read -p "Restart OpenClaw gateway? (y/n): " RESTART

    if [ "$RESTART" = "y" ] || [ "$RESTART" = "Y" ]; then
        echo "🔄 Restarting gateway..."
        openclaw gateway restart 2>/dev/null || echo -e "${YELLOW}⚠️  Could not restart gateway automatically${NC}"
    fi
elif [ -n "$AGENTMAIL_EMAIL" ] && [ -n "$AGENTMAIL_API_KEY" ]; then
    # Auto-restart in non-interactive mode if fully configured
    echo "🔄 Restarting gateway..."
    openclaw gateway restart 2>/dev/null || echo -e "${YELLOW}⚠️  Could not restart gateway automatically${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo ""

if [ "$INTERACTIVE" = false ]; then
    echo -e "${YELLOW}📋 To complete setup, run these commands:${NC}"
    echo ""
    echo "  export AGENTMAIL_API_KEY=\"your-api-key\""
    echo "  sed -i 's/your-agent@agentmail.to/YOUR_EMAIL/g' $SKILL_DIR/SKILL.md"
    echo "  openclaw gateway restart"
    echo ""
    echo -e "${YELLOW}Or reinstall with env vars:${NC}"
    echo "  AGENTMAIL_API_KEY=\"key\" AGENTMAIL_EMAIL=\"you@agentmail.to\" \\"
    echo "    curl -fsSL $REPO_URL/install.sh | bash"
else
    echo "Next steps:"
    echo "  1. Source your shell config: source ~/.bashrc"
    echo "  2. Tell your agent to check email!"
fi
echo ""
echo "Documentation: https://github.com/brolag/openclaw-agentmail-skill"
