# Lead Generation System Orchestrator

## System Overview

This document describes how to orchestrate the Amazing Dino lead generation agent system using Claude Code.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     LEAD GENERATION SYSTEM                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────────┐                                               │
│   │  Content Engine  │ ←── Ongoing brand awareness                   │
│   │      Agent       │                                               │
│   └────────┬─────────┘                                               │
│            │ Attracts                                                │
│            ▼                                                         │
│   ┌──────────────────┐                                               │
│   │ Prospect Finder  │ ←── Identifies & qualifies leads              │
│   │      Agent       │                                               │
│   └────────┬─────────┘                                               │
│            │ Qualified leads                                         │
│            ▼                                                         │
│   ┌──────────────────┐                                               │
│   │    Outreach      │ ←── Executes personalised sequences           │
│   │ Sequencer Agent  │                                               │
│   └────────┬─────────┘                                               │
│            │ Meeting scheduled                                       │
│            ▼                                                         │
│   ┌──────────────────┐                                               │
│   │  Meeting Prep    │ ←── Creates briefing documents                │
│   │      Agent       │                                               │
│   └────────┬─────────┘                                               │
│            │ Meeting completed                                       │
│            ▼                                                         │
│   ┌──────────────────┐                                               │
│   │    Proposal      │ ←── Generates customised proposals            │
│   │ Generator Agent  │                                               │
│   └──────────────────┘                                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Claude Code Implementation

### Directory Structure

```
amazingdino-leadgen/
├── agents/
│   ├── prospect-finder.md
│   ├── outreach-sequencer.md
│   ├── meeting-prep.md
│   ├── proposal-generator.md
│   └── content-engine.md
├── data/
│   ├── prospects.csv
│   ├── outreach-tracking.csv
│   └── meetings.csv
├── templates/
│   ├── email-templates/
│   ├── proposal-template.docx
│   └── case-studies/
├── outputs/
│   ├── proposals/
│   ├── briefings/
│   └── content/
└── CLAUDE.md
```

### CLAUDE.md (Master Configuration)

```markdown
# Amazing Dino Lead Generation System

## Overview

This project contains agents for automated lead generation for Amazing Dino Consulting's AI agent consultancy services.

## Available Agents

1. **Prospect Finder** (`agents/prospect-finder.md`)
   - Searches for and qualifies potential customers
   - Run weekly to fill pipeline

2. **Outreach Sequencer** (`agents/outreach-sequencer.md`)
   - Manages multi-touch outreach campaigns
   - Run daily to execute scheduled touches

3. **Meeting Prep** (`agents/meeting-prep.md`)
   - Creates briefing documents before calls
   - Run when meeting is scheduled

4. **Proposal Generator** (`agents/proposal-generator.md`)
   - Creates customised proposals
   - Run after successful discovery call

5. **Content Engine** (`agents/content-engine.md`)
   - Generates marketing content
   - Run weekly for content calendar

## Data Files

- `data/prospects.csv` - Master prospect list
- `data/outreach-tracking.csv` - Outreach activity log
- `data/meetings.csv` - Scheduled and completed meetings

## How to Use

### Find New Prospects
```
Read agents/prospect-finder.md and search for prospects in [INDUSTRY]. 
Output qualified leads to data/prospects.csv.
```

### Execute Outreach
```
Read agents/outreach-sequencer.md. Check data/outreach-tracking.csv for 
scheduled touches due today. Draft emails for my review.
```

### Prepare for Meeting
```
Read agents/meeting-prep.md. I have a meeting with [COMPANY] on [DATE]. 
Create a briefing document and save to outputs/briefings/.
```

### Generate Proposal
```
Read agents/proposal-generator.md. Create a proposal for [COMPANY] based 
on meeting notes: [PASTE NOTES]. Save to outputs/proposals/.
```

### Create Content
```
Read agents/content-engine.md. Create this week's LinkedIn posts on the 
topic of [TOPIC]. Save to outputs/content/.
```

## Key Context

- Company: Amazing Dino Consulting (amazingdino.au)
- Location: Melbourne, Australia
- Focus: AI agent implementation with security expertise
- Target: Mid-market companies in regulated industries
- Differentiator: Security-first approach to AI
```

### Sample Claude Code Commands

**Weekly Prospect Research**
```
@claude Read agents/prospect-finder.md. Search for Australian healthcare 
companies showing AI/automation buying signals. Find 10 qualified prospects 
and add them to data/prospects.csv with full qualification scoring.
```

**Daily Outreach Execution**
```
@claude Read agents/outreach-sequencer.md. Review data/outreach-tracking.csv 
and identify all prospects due for a touch today. Draft the appropriate 
emails based on their sequence stage and save to outputs/emails/[date]/.
```

**Pre-Meeting Prep**
```
@claude Read agents/meeting-prep.md. I have a discovery call with ABC Corp 
tomorrow at 2pm. The contact is Jane Smith, Head of Operations. We connected 
because they're hiring for process automation roles. Research them thoroughly 
and create a meeting briefing document.
```

**Post-Meeting Proposal**
```
@claude Read agents/proposal-generator.md. Create a proposal for ABC Corp 
based on these meeting notes:

[Paste meeting notes]

They're interested in automating their claims processing workflow. Budget 
discussed was $30-50k. Timeline is Q2 implementation.
```

**Weekly Content Batch**
```
@claude Read agents/content-engine.md. Create next week's content:
- 3 LinkedIn posts about AI agents in healthcare
- 1 blog article on "AI Compliance in Healthcare: What You Need to Know"
Save all outputs to outputs/content/week-[date]/
```

## Automation Schedule

### Daily Tasks
- [ ] 9:00 AM - Check for outreach touches due today
- [ ] 9:30 AM - Review and send approved emails
- [ ] 5:00 PM - Log any responses received

### Weekly Tasks (Monday)
- [ ] Run prospect finder for 2 target industries
- [ ] Review and score new prospects
- [ ] Plan week's content
- [ ] Move stale prospects to nurture

### Weekly Tasks (Friday)
- [ ] Review week's outreach metrics
- [ ] Update prospect scores based on engagement
- [ ] Schedule next week's content
- [ ] Prepare briefings for next week's meetings

### Monthly Tasks
- [ ] Publish case study (if approved)
- [ ] Send newsletter
- [ ] Review and optimise email templates
- [ ] Analyse pipeline conversion rates
- [ ] Refresh ICP criteria if needed

## Metrics to Track

### Pipeline Metrics
- New prospects added per week
- Qualification score distribution
- Response rates by sequence stage
- Meetings scheduled per week
- Proposals sent per month
- Win rate

### Content Metrics
- LinkedIn post engagement (likes, comments, shares)
- Blog traffic (if analytics set up)
- Newsletter open/click rates
- Inbound inquiries attributed to content

## Tips for Best Results

1. **Quality over quantity** - Better to deeply research 10 prospects than superficially identify 50

2. **Personalisation matters** - Generic outreach gets ignored. Every email should reference something specific.

3. **Consistency wins** - 3 posts/week for 6 months beats 20 posts in one week then silence

4. **Follow up** - Most deals close after 5+ touches. Don't give up after 2.

5. **Learn from responses** - Track what works and refine templates continuously

6. **Be human** - These agents create drafts. Add your personality before sending.
