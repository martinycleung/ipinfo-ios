# Amazing Dino Lead Generation - Complete Automated Workflow

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AUTOMATED WORKFLOW SYSTEM                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   TRIGGER   │───▶│    AGENT    │───▶│   OUTPUT    │───▶│   ACTION    │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                              │
│  Scheduled          Claude Code        CSV/Docs/         Email/LinkedIn/    │
│  Webhook            Execution          Reports           CRM Update         │
│  Manual                                                                      │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DAILY WORKFLOWS                                                             │
│  ├── 08:00 - Prospect Signal Scanner                                         │
│  ├── 09:00 - Outreach Executor (emails due today)                           │
│  ├── 17:00 - Response Processor                                              │
│  └── 18:00 - Daily Summary Report                                            │
│                                                                              │
│  WEEKLY WORKFLOWS                                                            │
│  ├── Monday 07:00 - Deep Prospect Research                                   │
│  ├── Monday 08:00 - Content Calendar Generator                               │
│  ├── Wednesday 09:00 - LinkedIn Content Publisher                            │
│  └── Friday 16:00 - Weekly Pipeline Report                                   │
│                                                                              │
│  TRIGGERED WORKFLOWS                                                         │
│  ├── Meeting Scheduled → Meeting Prep (T-24h)                               │
│  ├── Meeting Complete → Follow-up + Proposal                                │
│  ├── Positive Response → Escalate to Hot                                    │
│  └── New Inbound Lead → Immediate Research + Response                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Workflow Execution Methods

### Method 1: Claude Code CLI (Recommended)

Run workflows directly from terminal:

```bash
# Daily prospect scan
claude -p "Execute workflow: daily-prospect-scan" --project ./amazingdino-agents

# Weekly deep research
claude -p "Execute workflow: weekly-research --industry healthcare" --project ./amazingdino-agents
```

### Method 2: Cron + Claude Code

Schedule with cron jobs:

```bash
# Edit crontab
crontab -e

# Add scheduled workflows
0 8 * * * cd /path/to/amazingdino-agents && claude -p "Execute: daily-prospect-scan" >> logs/daily.log 2>&1
0 9 * * * cd /path/to/amazingdino-agents && claude -p "Execute: daily-outreach" >> logs/outreach.log 2>&1
0 7 * * 1 cd /path/to/amazingdino-agents && claude -p "Execute: weekly-research" >> logs/weekly.log 2>&1
```

### Method 3: n8n / Make.com Integration

Connect to automation platforms via webhooks (see integration guide below).

---

## Detailed Workflow Specifications

### WORKFLOW 1: Daily Prospect Signal Scanner

**Schedule**: Daily 08:00 AEST
**Duration**: ~15 minutes
**Output**: New signals added to `data/prospect-signals.csv`

```yaml
workflow_id: daily-prospect-scan
trigger: scheduled
schedule: "0 8 * * *"
timezone: Australia/Melbourne

steps:
  - name: scan_job_boards
    agent: prospect-finder
    action: |
      Search these sources for AI/automation hiring signals:
      - seek.com.au: "AI implementation" OR "process automation" Melbourne Sydney Brisbane
      - LinkedIn Jobs: automation manager Australia
      Extract: company_name, job_title, posting_date, job_url
      
  - name: scan_news
    agent: prospect-finder
    action: |
      Search for Australian company AI announcements from last 24 hours:
      - site:afr.com AI automation
      - site:itnews.com.au AI implementation
      - "Australian company" AI strategy 2025
      Extract: company_name, headline, date, source_url
      
  - name: check_existing
    action: |
      Compare found companies against data/prospects.csv
      Flag: new_prospect or existing_prospect_new_signal
      
  - name: output_signals
    action: |
      Append new signals to data/prospect-signals.csv
      Format: date,source,company_name,signal_type,signal_detail,url,status
      
  - name: notify
    action: |
      If new_signals > 0:
        Create summary in outputs/daily/[date]-signals.md
        Include top 5 highest-potential new prospects
```

---

### WORKFLOW 2: Daily Outreach Executor

**Schedule**: Daily 09:00 AEST
**Duration**: ~20 minutes
**Output**: Draft emails in `outputs/daily/[date]-outreach/`

```yaml
workflow_id: daily-outreach
trigger: scheduled
schedule: "0 9 * * *"
timezone: Australia/Melbourne

steps:
  - name: load_schedule
    action: |
      Read data/outreach-tracking.csv
      Filter: next_touch_date = today AND status != completed
      Group by sequence_stage
      
  - name: generate_emails
    agent: outreach-sequencer
    action: |
      For each prospect due today:
        1. Load prospect details from data/prospects.csv
        2. Determine appropriate template based on:
           - sequence_stage (day_0, day_3, day_7, day_14, day_21)
           - qualification_score (hot, warm, nurture)
           - industry
        3. Generate personalised email using template
        4. Save to outputs/daily/[date]-outreach/[company_name].md
        
  - name: generate_linkedin
    agent: outreach-sequencer
    action: |
      For prospects at day_3 stage (LinkedIn connection):
        Generate connection request message
        Save to outputs/daily/[date]-outreach/linkedin/[company_name].md
        
  - name: create_checklist
    action: |
      Create outputs/daily/[date]-outreach/CHECKLIST.md with:
        - [ ] Email: [Company] - [Contact] - [Subject]
        - [ ] LinkedIn: [Company] - [Contact]
      Include copy-paste ready content for each
      
  - name: update_tracking
    action: |
      For each generated touch:
        Update data/outreach-tracking.csv:
          - message_drafted = true
          - draft_location = [file_path]
```

---

### WORKFLOW 3: Response Processor

**Schedule**: Daily 17:00 AEST
**Duration**: ~10 minutes
**Input**: Manual response logging or email integration
**Output**: Updated tracking, escalation actions

```yaml
workflow_id: response-processor
trigger: scheduled
schedule: "0 17 * * *"
timezone: Australia/Melbourne

steps:
  - name: check_responses
    action: |
      Read data/responses-today.csv (manually updated or via integration)
      Columns: date,company_name,contact_name,response_type,response_content
      
  - name: categorise_responses
    agent: outreach-sequencer
    action: |
      For each response, categorise as:
        - positive_meeting: Interested, wants to meet
        - positive_info: Interested, wants more info
        - timing_later: Interested but not now
        - negative: Not interested
        - out_of_office: Auto-reply detected
        - bounce: Email bounced
        
  - name: process_positive
    action: |
      For positive_meeting responses:
        1. Move to data/meetings.csv with status=to_schedule
        2. Generate calendar invite draft
        3. Trigger: meeting-prep workflow (T-24h before meeting)
        
      For positive_info responses:
        1. Update sequence to send requested info
        2. Queue follow-up in 3 days
        
  - name: process_timing
    action: |
      For timing_later responses:
        1. Extract mentioned timeframe if any
        2. Set next_touch_date to appropriate future date
        3. Move to nurture sequence
        
  - name: process_negative
    action: |
      For negative responses:
        1. Mark sequence_status = closed_lost
        2. Remove from active sequences
        3. Add to do_not_contact if requested
        
  - name: update_tracking
    action: |
      Update data/outreach-tracking.csv with all changes
      Update data/prospects.csv qualification scores based on engagement
```

---

### WORKFLOW 4: Weekly Deep Research

**Schedule**: Monday 07:00 AEST
**Duration**: ~45 minutes
**Output**: 10-15 fully researched prospects

```yaml
workflow_id: weekly-research
trigger: scheduled
schedule: "0 7 * * 1"
timezone: Australia/Melbourne
parameters:
  industries:
    - healthcare
    - financial_services
    - professional_services
    - manufacturing
  prospects_per_industry: 3

steps:
  - name: research_industries
    agent: prospect-finder
    action: |
      For each industry in parameters.industries:
        Execute full prospect research:
        1. Run industry-specific search queries
        2. Identify companies showing buying signals
        3. Research each company deeply:
           - Company overview
           - Key contacts (CEO, CTO, CIO, Head of Ops)
           - Technology stack
           - Recent news
           - AI readiness indicators
        4. Score using qualification matrix
        5. Select top [prospects_per_industry] by score
        
  - name: compile_profiles
    action: |
      For each qualified prospect:
        Create detailed profile in outputs/weekly/[date]/[company_name].md
        Include:
          - Full company research
          - Contact details and LinkedIn URLs
          - Buying signals detected
          - Recommended approach
          - Draft initial outreach message
          
  - name: update_pipeline
    action: |
      Add qualified prospects to data/prospects.csv
      Set sequence_status = new
      Set next_touch_date = tomorrow
      
  - name: generate_report
    action: |
      Create outputs/weekly/[date]/WEEKLY-RESEARCH-REPORT.md
      Include:
        - Summary of research conducted
        - [X] new prospects added to pipeline
        - Top opportunities with rationale
        - Industry observations and trends
        - Recommended focus areas for outreach
```

---

### WORKFLOW 5: Content Calendar Generator

**Schedule**: Monday 08:00 AEST
**Duration**: ~30 minutes
**Output**: Week's content ready to publish

```yaml
workflow_id: weekly-content
trigger: scheduled
schedule: "0 8 * * 1"
timezone: Australia/Melbourne

steps:
  - name: determine_themes
    agent: content-engine
    action: |
      Based on:
        - Current pipeline industries (from data/prospects.csv)
        - Recent meeting topics (from data/meetings.csv)
        - Trending AI/security news
      Select 2-3 content themes for the week
      
  - name: generate_linkedin_posts
    agent: content-engine
    action: |
      Create 3-4 LinkedIn posts for the week:
        - Tuesday: Educational post on [theme 1]
        - Wednesday: Insight/opinion on [theme 2]
        - Thursday: Mini case study or engagement question
        - Friday (optional): Light content or industry news reaction
      
      Save to outputs/content/week-[date]/linkedin/
      
  - name: generate_blog_article
    agent: content-engine
    action: |
      Create 1 blog article:
        - Topic aligned with top pipeline industry
        - SEO optimised for target keywords
        - 1,500-2,000 words
        - Include internal links to previous posts
        
      Save to outputs/content/week-[date]/blog/
      
  - name: create_calendar
    action: |
      Create outputs/content/week-[date]/CONTENT-CALENDAR.md
      
      | Day | Platform | Content | Status |
      |-----|----------|---------|--------|
      | Tue | LinkedIn | [Title] | Draft |
      | Wed | LinkedIn | [Title] | Draft |
      | Thu | LinkedIn | [Title] | Draft |
      | Fri | Blog | [Title] | Draft |
      
      Include publishing instructions and optimal times
```

---

### WORKFLOW 6: Meeting Prep Trigger

**Trigger**: Meeting scheduled (T-24 hours)
**Duration**: ~20 minutes
**Output**: Complete briefing document

```yaml
workflow_id: meeting-prep
trigger: event
event_type: meeting_scheduled
timing: T-24h before meeting

steps:
  - name: load_meeting
    action: |
      Read meeting details from data/meetings.csv
      Get: company_name, contact_name, contact_title, meeting_date, meeting_type
      
  - name: load_history
    action: |
      Pull all prior interactions from data/outreach-tracking.csv
      Pull prospect profile from data/prospects.csv
      
  - name: deep_research
    agent: meeting-prep
    action: |
      Execute comprehensive research:
        1. Company deep dive
           - Business model, financials, recent news
           - Technology stack, AI initiatives
           - Competitors and market position
        2. Contact research
           - LinkedIn profile, career history
           - Recent posts and content
           - Communication style
        3. Industry context
           - AI adoption trends
           - Regulatory landscape
           - Competitor AI usage
           
  - name: generate_briefing
    agent: meeting-prep
    action: |
      Create comprehensive briefing document:
        - Quick reference (2-min read)
        - Company overview
        - Contact profile
        - Pain points and use cases
        - Objection handling
        - Discovery questions
        - Suggested agenda
        
      Save to outputs/briefings/[date]-[company_name].md
      
  - name: notify
    action: |
      Create notification:
        "Meeting briefing ready for [Company] - [Contact]"
        Link to briefing document
```

---

### WORKFLOW 7: Post-Meeting Processor

**Trigger**: Meeting completed
**Duration**: ~30 minutes
**Output**: Follow-up email, proposal if needed

```yaml
workflow_id: post-meeting
trigger: manual
input_required:
  - meeting_id
  - meeting_notes
  - outcome (hot/warm/cold/lost)
  - next_steps
  - proposal_needed (yes/no)

steps:
  - name: process_notes
    action: |
      Parse meeting notes for:
        - Key pain points discussed
        - Budget mentioned
        - Timeline discussed
        - Decision makers identified
        - Specific requirements
        - Objections raised
        
  - name: update_records
    action: |
      Update data/meetings.csv:
        - status = completed
        - outcome = [outcome]
        - notes = [meeting_notes]
        
      Update data/prospects.csv:
        - Last meeting date
        - Updated qualification score
        - Stage = [new stage based on outcome]
        
  - name: generate_followup
    agent: outreach-sequencer
    action: |
      Create thank-you/follow-up email:
        - Reference specific discussion points
        - Summarise agreed next steps
        - Attach any promised materials
        
      Save to outputs/meetings/[date]-[company]/follow-up-email.md
      
  - name: generate_proposal
    condition: proposal_needed == yes
    agent: proposal-generator
    action: |
      Create customised proposal:
        - Use meeting notes for personalisation
        - Include discussed use cases
        - Price according to budget range
        - Timeline per their requirements
        
      Save to outputs/meetings/[date]-[company]/proposal.docx
      
  - name: schedule_followup
    action: |
      Add to data/outreach-tracking.csv:
        - Send follow-up email: today
        - Check-in call: +7 days
        - Proposal follow-up: +3 days (if proposal sent)
```

---

### WORKFLOW 8: Weekly Pipeline Report

**Schedule**: Friday 16:00 AEST
**Duration**: ~15 minutes
**Output**: Pipeline health report

```yaml
workflow_id: weekly-report
trigger: scheduled
schedule: "0 16 * * 5"
timezone: Australia/Melbourne

steps:
  - name: calculate_metrics
    action: |
      From data/prospects.csv:
        - Total active prospects
        - By stage: new, contacted, engaged, meeting, proposal, negotiating
        - By qualification: hot, warm, nurture
        - Movement this week (stage changes)
        
      From data/outreach-tracking.csv:
        - Emails sent this week
        - Response rate
        - Positive response rate
        
      From data/meetings.csv:
        - Meetings this week
        - Outcomes (hot/warm/cold/lost)
        
  - name: identify_actions
    action: |
      Flag prospects needing attention:
        - Stale (no activity >14 days)
        - Hot leads not contacted in >3 days
        - Proposals sent >7 days ago without response
        
  - name: generate_report
    action: |
      Create outputs/reports/week-[date]-pipeline.md
      
      # Pipeline Report - Week of [Date]
      
      ## Summary
      - Active prospects: [X]
      - Meetings held: [X]
      - Proposals sent: [X]
      - Expected close this month: $[X]
      
      ## Pipeline by Stage
      [Stage breakdown with week-over-week change]
      
      ## Activity Metrics
      - Outreach sent: [X]
      - Response rate: [X]%
      - Meeting conversion: [X]%
      
      ## Action Items
      - [ ] Follow up: [Company A] - proposal sent 7 days ago
      - [ ] Re-engage: [Company B] - stale 14 days
      - [ ] Schedule: [Company C] - positive response
      
      ## Next Week Focus
      [Recommendations based on pipeline health]
```

---

### WORKFLOW 9: Inbound Lead Processor

**Trigger**: New inbound inquiry (form submission, email, LinkedIn message)
**Duration**: ~15 minutes
**Output**: Immediate response + research

```yaml
workflow_id: inbound-lead
trigger: webhook
webhook_endpoint: /api/inbound-lead

steps:
  - name: capture_lead
    action: |
      Parse inbound data:
        - Source (website form, email, LinkedIn)
        - Company name
        - Contact name and email
        - Message/inquiry content
        
  - name: immediate_response
    action: |
      Generate and queue immediate response:
        "Thanks for reaching out, [Name]. I've received your inquiry 
        about [topic]. I'll review and get back to you within 
        [X hours] with some initial thoughts.
        
        In the meantime, you might find this relevant: [resource link]
        
        Best,
        Martin"
        
  - name: research_lead
    agent: prospect-finder
    action: |
      Quick research on company:
        - Company size and industry
        - Role of contact
        - Likely pain points
        - Qualification score
        
  - name: add_to_pipeline
    action: |
      Add to data/prospects.csv:
        - Source = inbound
        - Priority = high (inbound always prioritised)
        - Next action = personalised response
        
  - name: prepare_response
    agent: outreach-sequencer
    action: |
      Draft personalised response:
        - Address their specific inquiry
        - Demonstrate understanding of their situation
        - Propose next step (call, more info, etc.)
        
      Save to outputs/inbound/[date]-[company]-response.md
      
  - name: notify
    action: |
      Alert: New inbound lead from [Company]
      Qualification: [Score]
      Suggested response ready for review
```

---

## Integration Configurations

### Google Sheets Integration (for tracking)

```javascript
// Apps Script to sync with Google Sheets
function syncProspects() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Prospects');
  const data = sheet.getDataRange().getValues();
  
  // Export to CSV for Claude Code
  const csv = data.map(row => row.join(',')).join('\n');
  
  // Save to Drive for Claude Code access
  DriveApp.createFile('prospects.csv', csv, MimeType.CSV);
}

function onFormSubmit(e) {
  // Trigger inbound lead workflow
  const webhookUrl = 'YOUR_WEBHOOK_URL';
  const payload = {
    source: 'website_form',
    company: e.values[1],
    contact_name: e.values[2],
    email: e.values[3],
    message: e.values[4]
  };
  
  UrlFetchApp.fetch(webhookUrl, {
    method: 'POST',
    contentType: 'application/json',
    payload: JSON.stringify(payload)
  });
}
```

### n8n Workflow Integration

```json
{
  "name": "Daily Prospect Scan Trigger",
  "nodes": [
    {
      "type": "n8n-nodes-base.cron",
      "parameters": {
        "cronExpression": "0 8 * * *"
      }
    },
    {
      "type": "n8n-nodes-base.executeCommand",
      "parameters": {
        "command": "cd /path/to/amazingdino-agents && claude -p 'Execute: daily-prospect-scan'"
      }
    },
    {
      "type": "n8n-nodes-base.gmail",
      "parameters": {
        "operation": "send",
        "toEmail": "martin@amazingdino.au",
        "subject": "Daily Prospect Scan Complete",
        "text": "{{$node['Execute'].data.stdout}}"
      }
    }
  ]
}
```

### Zapier Integration

```yaml
# Zapier Zap: Website Form → Inbound Lead Workflow
trigger:
  app: typeform  # or google_forms, etc.
  event: new_response
  
actions:
  - app: webhooks
    event: post
    url: https://your-server.com/api/inbound-lead
    data:
      source: website_form
      company: "{{company}}"
      contact_name: "{{name}}"
      email: "{{email}}"
      message: "{{message}}"
      
  - app: slack
    event: send_message
    channel: "#leads"
    text: "New inbound lead: {{company}} - {{name}}"
```

---

## Monitoring & Alerts

### Health Check Script

```bash
#!/bin/bash
# Run daily to ensure system health

# Check data files exist
for file in prospects.csv outreach-tracking.csv meetings.csv; do
  if [ ! -f "data/$file" ]; then
    echo "ERROR: Missing $file"
    exit 1
  fi
done

# Check for stale data
last_modified=$(stat -c %Y data/outreach-tracking.csv)
current_time=$(date +%s)
diff=$((current_time - last_modified))

if [ $diff -gt 172800 ]; then  # 48 hours
  echo "WARNING: No outreach activity in 48 hours"
fi

# Check pipeline health
hot_leads=$(grep -c ",hot," data/prospects.csv)
if [ $hot_leads -eq 0 ]; then
  echo "WARNING: No hot leads in pipeline"
fi

echo "Health check complete"
```

### Slack Notifications

```python
import requests
from datetime import datetime

SLACK_WEBHOOK = "your-webhook-url"

def notify_slack(message, channel="#leads"):
    payload = {
        "channel": channel,
        "text": message,
        "username": "LeadGen Bot",
        "icon_emoji": ":robot_face:"
    }
    requests.post(SLACK_WEBHOOK, json=payload)

# Example notifications
notify_slack("🎯 New hot lead: ABC Corp - Score 4.2/5")
notify_slack("📅 Meeting scheduled: XYZ Inc - Tomorrow 2pm")
notify_slack("📊 Weekly Report: 12 prospects, 3 meetings, 1 proposal")
```

---

## Quick Start Commands

```bash
# First time setup
cd amazingdino-agents
chmod +x workflows/*.sh

# Run individual workflows
claude -p "Execute workflow: daily-prospect-scan"
claude -p "Execute workflow: daily-outreach"
claude -p "Execute workflow: weekly-research --industry healthcare"
claude -p "Execute workflow: meeting-prep --company 'ABC Corp'"
claude -p "Execute workflow: post-meeting --meeting_id 123 --notes 'Meeting notes here'"

# Check status
claude -p "Show pipeline summary"
claude -p "What's due today?"
claude -p "List stale prospects"

# Generate reports
claude -p "Create weekly pipeline report"
claude -p "Summarise this week's activity"
```
