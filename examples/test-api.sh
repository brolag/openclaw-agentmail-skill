#!/bin/bash
# Test AgentMail API connection
# Usage: ./test-api.sh YOUR_API_KEY

set -e

API_KEY="${1:-$AGENTMAIL_API_KEY}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: No API key provided"
    echo "Usage: ./test-api.sh YOUR_API_KEY"
    echo "   or: export AGENTMAIL_API_KEY=your-key && ./test-api.sh"
    exit 1
fi

echo "🧪 Testing AgentMail API..."
echo ""

# Test 1: List inboxes
echo "1️⃣ Listing inboxes..."
RESPONSE=$(curl -s "https://api.agentmail.to/v0/inboxes" \
    -H "Authorization: Bearer $API_KEY")

if echo "$RESPONSE" | grep -q "error\|Forbidden"; then
    echo "❌ Failed: $RESPONSE"
    exit 1
else
    echo "✅ Success! Inboxes:"
    echo "$RESPONSE" | jq '.inboxes[] | {inbox_id, display_name}' 2>/dev/null || echo "$RESPONSE"
fi

echo ""

# Test 2: Check if jq is installed
echo "2️⃣ Checking dependencies..."
if command -v jq &> /dev/null; then
    echo "✅ jq is installed"
else
    echo "⚠️  jq not found - install with: apt install jq"
fi

if command -v curl &> /dev/null; then
    echo "✅ curl is installed"
else
    echo "❌ curl not found - install with: apt install curl"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Your API key is working."
echo ""
echo "Next steps:"
echo "  1. Run: ./install.sh"
echo "  2. Restart OpenClaw: openclaw gateway restart"
echo "  3. Test with your agent!"
