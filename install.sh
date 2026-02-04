#!/bin/bash
# Install AgentMail skill for OpenClaw
# https://github.com/brolag/openclaw-agentmail-skill
#
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/brolag/openclaw-agentmail-skill/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REPO_URL="https://raw.githubusercontent.com/brolag/openclaw-agentmail-skill/main"

echo -e "${GREEN}🦞 OpenClaw AgentMail Skill Installer${NC}"
echo ""

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

# Check for existing API key
if [ -n "$AGENTMAIL_API_KEY" ]; then
    echo -e "${GREEN}✅ API key already set in environment${NC}"
else
    echo ""
    read -p "Enter your AgentMail API key (or press Enter to skip): " API_KEY

    if [ -n "$API_KEY" ]; then
        # Test the API key first
        echo "🧪 Testing API key..."
        RESPONSE=$(curl -s "https://api.agentmail.to/v1/inboxes" \
            -H "Authorization: Bearer $API_KEY" 2>/dev/null)

        if echo "$RESPONSE" | grep -q "error\|unauthorized"; then
            echo -e "${RED}❌ API key appears invalid${NC}"
            echo "Response: $RESPONSE"
            echo "Continuing anyway - you can fix this later."
        else
            echo -e "${GREEN}✅ API key valid${NC}"
        fi

        # Add to shell config
        SHELL_RC="$HOME/.bashrc"
        [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

        # Check if already exists
        if grep -q "AGENTMAIL_API_KEY" "$SHELL_RC" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  API key already in $SHELL_RC - updating${NC}"
            sed -i.bak '/AGENTMAIL_API_KEY/d' "$SHELL_RC"
        fi

        echo "export AGENTMAIL_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
        export AGENTMAIL_API_KEY="$API_KEY"
        echo -e "${GREEN}✅ API key saved to $SHELL_RC${NC}"
    fi
fi

# Ask for email address
echo ""
read -p "Enter your AgentMail email (e.g., myagent@agentmail.to): " EMAIL_ADDRESS
EMAIL_ADDRESS="${EMAIL_ADDRESS:-agent@agentmail.to}"

# Update SKILL.md with actual email
sed -i.bak "s/your-agent@agentmail.to/$EMAIL_ADDRESS/g" "$SKILL_DIR/SKILL.md"
rm -f "$SKILL_DIR/SKILL.md.bak"
echo -e "${GREEN}✅ Email set to $EMAIL_ADDRESS${NC}"

# Verify skill is detected
echo ""
echo "🔍 Verifying skill installation..."
if openclaw skills list 2>/dev/null | grep -q "agentmail"; then
    echo -e "${GREEN}✅ Skill 'agentmail' detected by OpenClaw${NC}"
else
    echo -e "${YELLOW}⚠️  Skill may not be detected yet. Try: openclaw gateway restart${NC}"
fi

# Update agent identity (optional)
echo ""
read -p "Add email info to IDENTITY.md? (y/n): " UPDATE_IDENTITY

if [ "$UPDATE_IDENTITY" = "y" ] || [ "$UPDATE_IDENTITY" = "Y" ]; then
    cat >> "$WORKSPACE/IDENTITY.md" << EOF

## Email Capabilities
- **Email**: $EMAIL_ADDRESS
- **Skill**: Read $SKILL_DIR/SKILL.md for email commands
- I can check my inbox, read emails, reply, and send new emails using AgentMail API.
EOF
    echo -e "${GREEN}✅ Updated IDENTITY.md${NC}"
fi

# Restart gateway (optional)
echo ""
read -p "Restart OpenClaw gateway? (y/n): " RESTART

if [ "$RESTART" = "y" ] || [ "$RESTART" = "Y" ]; then
    echo "🔄 Restarting gateway..."
    openclaw gateway restart 2>/dev/null || echo -e "${YELLOW}⚠️  Could not restart gateway automatically${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Source your shell config: source ~/.bashrc"
echo "  2. Test the API: ./examples/test-api.sh"
echo "  3. Tell your agent to check email!"
echo ""
echo "Documentation: https://github.com/brolag/openclaw-agentmail-skill"
