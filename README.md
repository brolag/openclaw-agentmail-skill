# OpenClaw AgentMail Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Email integration for OpenClaw AI agents via [AgentMail](https://agentmail.to) API.

## Why?

AI agents need email to:
- Register for services
- Receive confirmations and notifications
- Communicate with external systems
- Operate autonomously

AgentMail provides email infrastructure designed specifically for AI agents.

## Features

- ✅ Check inbox
- ✅ Read emails
- ✅ Reply to emails
- ✅ Send new emails
- ✅ List all inboxes
- ✅ Simple curl-based commands (no plugin dependencies)

## Prerequisites

1. [OpenClaw](https://openclaw.ai) v2026.2.0+ installed and running
2. [AgentMail](https://agentmail.to) account (free tier: 3 inboxes, 3000 emails/month)
3. AgentMail API key
4. `curl` and `jq` installed on your system

## Compatibility

This skill follows the [OpenClaw AgentSkills format](https://docs.openclaw.ai/tools/skills):

- ✅ YAML frontmatter with `name`, `description`, `metadata`
- ✅ Dependency gating (`requires.bins`, `requires.env`)
- ✅ Works with workspace skills (`~/.openclaw/workspace/skills/`)
- ✅ Tested with OpenClaw 2026.2.x

## Installation

### One-Line Install (with config)

```bash
AGENTMAIL_API_KEY="your-key" AGENTMAIL_EMAIL="agent@agentmail.to" \
  curl -fsSL https://raw.githubusercontent.com/brolag/openclaw-agentmail-skill/main/install.sh | bash
```

### One-Line Install (basic)

```bash
curl -fsSL https://raw.githubusercontent.com/brolag/openclaw-agentmail-skill/main/install.sh | bash
```

Then complete setup:
```bash
export AGENTMAIL_API_KEY="your-key"
sed -i 's/your-agent@agentmail.to/YOUR_EMAIL/g' ~/.openclaw/workspace/skills/agentmail/SKILL.md
openclaw gateway restart
```

### From Source (interactive)

```bash
git clone https://github.com/brolag/openclaw-agentmail-skill.git
cd openclaw-agentmail-skill
chmod +x install.sh
./install.sh
```

### Manual Install

1. Copy the skill to your OpenClaw workspace:

```bash
mkdir -p ~/.openclaw/workspace/skills/agentmail
cp SKILL.md ~/.openclaw/workspace/skills/agentmail/
```

2. Set your API key:

```bash
echo 'export AGENTMAIL_API_KEY="your-api-key"' >> ~/.bashrc
source ~/.bashrc
```

3. Restart OpenClaw:

```bash
openclaw gateway restart
```

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `AGENTMAIL_API_KEY` | Your AgentMail API key | Yes |

### Getting Your API Key

1. Sign up at [agentmail.to](https://agentmail.to)
2. Go to Settings → API Keys
3. Create a new key
4. Copy and save it securely

## Usage

Once installed, your agent can use these commands:

### Check Inbox

```bash
curl -s "https://api.agentmail.to/v0/inboxes/YOUR_EMAIL/messages?limit=10" \
  -H "Authorization: Bearer $AGENTMAIL_API_KEY" | jq
```

### Send Email

```bash
curl -X POST "https://api.agentmail.to/v0/inboxes/YOUR_EMAIL/messages" \
  -H "Authorization: Bearer $AGENTMAIL_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"to": ["recipient@email.com"], "subject": "Hello", "body": "Message"}'
```

See [SKILL.md](SKILL.md) for all available commands.

## Why Not Use the Official Plugin?

The [official OpenClaw AgentMail plugin](https://github.com/wko/openclaw-agentmail) has compatibility issues with some OpenClaw versions due to schema validation changes. This skill-based approach:

- Works with any OpenClaw version
- No dependency conflicts
- Simpler to maintain and debug
- Full control over API interactions

## Security Considerations

- Store API keys securely (environment variables, not in code)
- Use `allowFrom` whitelist if using as a channel
- The skill uses HTTPS for all API calls
- Consider reply-only mode for untrusted environments

## Contributing

Contributions welcome! Please:

1. Fork the repo
2. Create a feature branch
3. Submit a PR

## License

MIT License - see [LICENSE](LICENSE)

## Credits

- [AgentMail](https://agentmail.to) - Email API for AI agents
- [OpenClaw](https://openclaw.ai) - The universal AI agent gateway

---

Built with 🦞 for the AI agent community
