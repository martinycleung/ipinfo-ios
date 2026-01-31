# Amazing Dino Lead Generation System

A complete automated lead generation system for AI agent consultancy services, powered by Claude Code.

## What This System Does

This system automates the entire lead generation pipeline:

1. **Finds Prospects** - Scans job boards and news for companies showing AI/automation buying signals
2. **Qualifies Leads** - Scores prospects based on size, budget signals, pain points, and fit
3. **Executes Outreach** - Manages multi-touch email and LinkedIn campaigns
4. **Prepares for Meetings** - Creates comprehensive briefing documents
5. **Generates Proposals** - Creates customised proposals based on meeting outcomes
6. **Creates Content** - Produces LinkedIn posts and blog articles for brand awareness

## Quick Start

```bash
# 1. Extract the package
unzip amazingdino-leadgen-agents.zip
cd amazingdino-agents

# 2. Run setup
chmod +x setup.sh
./setup.sh

# 3. Test the system
./workflows/daily-workflow.sh
```

## System Requirements

- **Claude Code CLI** - Install from https://claude.ai/code
- **Bash** - Standard Unix shell
- **Internet connection** - For web research

## Directory Structure

```
amazingdino-agents/
├── CLAUDE.md              # Main configuration for Claude Code
├── README.md              # This file
├── setup.sh               # First-time setup script
│
├── agents/                # AI agent prompt definitions
│   ├── 01-prospect-finder-agent.md
│   ├── 02-outreach-sequencer-agent.md
│   ├── 03-meeting-prep-agent.md
│   ├── 04-proposal-generator-agent.md
│   └── 05-content-engine-agent.md
│
├── workflows/             # Executable automation scripts
│   ├── 00-master-workflow.md    # Complete documentation
│   ├── daily-workflow.sh        # Run every morning
│   ├── weekly-workflow.sh       # Run Monday mornings
│   ├── meeting-workflow.sh      # Meeting prep & follow-up
│   └── inbound-handler.sh       # Process new inbound leads
│
├── data/                  # CSV tracking files
│   ├── prospects.csv
│   ├── outreach-tracking.csv
│   └── meetings.csv
│
├── outputs/               # Generated content
│   ├── daily/            # Daily scan results & outreach
│   ├── weekly/           # Research & content calendar
│   ├── briefings/        # Meeting prep documents
│   ├── proposals/        # Generated proposals
│   └── content/          # Marketing content
│
└── logs/                  # Execution logs
```

## Daily Usage

### Morning Routine (5 minutes)

```bash
# Run daily workflow
./workflows/daily-workflow.sh

# Check what was generated
ls outputs/daily/$(date +%Y-%m-%d)/

# Review and send outreach
cat outputs/daily/$(date +%Y-%m-%d)/OUTREACH-CHECKLIST.md
```

### When You Have a Meeting Tomorrow

```bash
# Generate briefing
./workflows/meeting-workflow.sh prep "Company Name" "Contact Name"

# Review briefing
cat outputs/briefings/[date]-[company].md
```

### After a Meeting

```bash
# Quick notes template
./workflows/meeting-workflow.sh notes "Company Name"
# (Opens editor, fill in notes, save)

# Process the meeting
./workflows/meeting-workflow.sh post "Company Name" hot yes ./notes.md

# Check generated follow-up and proposal
ls outputs/meetings/[date]-[company]/
```

### Weekly Planning (Monday)

```bash
# Run full weekly workflow
./workflows/weekly-workflow.sh

# Review new prospects
ls outputs/weekly/$(date +%Y-W%V)/prospects/

# Review content calendar
cat outputs/weekly/$(date +%Y-W%V)/CONTENT-CALENDAR.md

# Check pipeline health
cat outputs/weekly/$(date +%Y-W%V)/PIPELINE-REPORT.md
```

## Automation Options

### Option 1: Cron Jobs

```bash
crontab -e

# Add these lines:
# Daily at 8am
0 8 * * * cd /path/to/amazingdino-agents && ./workflows/daily-workflow.sh >> logs/cron.log 2>&1

# Weekly Monday at 7am
0 7 * * 1 cd /path/to/amazingdino-agents && ./workflows/weekly-workflow.sh >> logs/cron.log 2>&1
```

### Option 2: n8n / Make.com

See `workflows/00-master-workflow.md` for webhook integration examples.

### Option 3: Manual

Just run the scripts when you need them. Still saves hours of work.

## Customisation

### Modify Target Industries

Edit `agents/01-prospect-finder-agent.md`:
- Update the "Ideal Customer Profile" section
- Add industry-specific search queries
- Adjust qualification scoring

### Change Email Templates

Edit `agents/02-outreach-sequencer-agent.md`:
- Modify templates for each sequence stage
- Adjust tone and messaging
- Add new template variations

### Adjust Content Strategy

Edit `agents/05-content-engine-agent.md`:
- Change content pillars
- Modify posting frequency
- Update tone guidelines

## Workflow Details

### Prospect Qualification Scoring

| Criteria | Weight | Description |
|----------|--------|-------------|
| Company Size | 20% | 50-500 employees ideal |
| Budget Signals | 25% | Funding, growth, hiring |
| Pain Point Clarity | 25% | Explicit need signals |
| Decision Maker Access | 15% | Can we reach them? |
| Security/Compliance Need | 15% | Regulated industry? |

**Score >= 3.5**: Hot lead (aggressive outreach)
**Score 2.5-3.5**: Warm lead (standard sequence)
**Score < 2.5**: Nurture (monthly touch)

### Outreach Sequence

**Hot Leads:**
- Day 0: Personalised email
- Day 3: LinkedIn connection
- Day 7: Follow-up with value
- Day 14: Case study
- Day 21: Break-up email

**Warm Leads:**
- Day 0: Personalised email
- Day 7: LinkedIn connection
- Day 14: Educational content

### Content Calendar

| Day | Content Type |
|-----|--------------|
| Tuesday | Educational post |
| Wednesday | Insight/opinion |
| Thursday | Engagement/case study |
| Friday | Blog article |

## Troubleshooting

### "Claude Code not found"
```bash
# Install Claude Code from https://claude.ai/code
# Or add to PATH if already installed
export PATH="$PATH:/path/to/claude"
```

### Workflows not executing
```bash
# Make sure scripts are executable
chmod +x workflows/*.sh

# Check logs for errors
cat logs/[date].log
```

### Empty outputs
```bash
# Verify data files exist
ls -la data/

# Re-run setup if needed
./setup.sh
```

## Support

This system is designed for Amazing Dino Consulting's specific needs. For customisation or support:

- Email: martin@amazingdino.au
- Web: amazingdino.au

## License

Proprietary - Amazing Dino Consulting Pty Ltd
