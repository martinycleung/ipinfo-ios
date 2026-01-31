#!/bin/bash
# Amazing Dino Lead Generation - Weekly Automation Script
# Run Monday mornings or set up as cron job

set -e

# Configuration
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$0")/..}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"  # Resolve to absolute path
LOG_DIR="$PROJECT_DIR/logs"
OUTPUT_DIR="$PROJECT_DIR/outputs/weekly"
DATE=$(date +%Y-%m-%d)
WEEK=$(date +%Y-W%V)
LOCK_FILE="$PROJECT_DIR/.weekly-workflow.lock"

# Lock file to prevent concurrent execution
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
        if kill -0 "$LOCK_PID" 2>/dev/null; then
            echo "ERROR: Another instance is running (PID: $LOCK_PID)"
            exit 1
        else
            echo "WARNING: Stale lock file found, removing"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"' EXIT
}

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "$OUTPUT_DIR/$WEEK"
mkdir -p "$OUTPUT_DIR/$WEEK/prospects"
mkdir -p "$OUTPUT_DIR/$WEEK/content"

# Logging function
log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_DIR/weekly-$WEEK.log"
}

# Acquire lock before starting
acquire_lock

log "======================================"
log "Weekly Lead Generation Workflow Started"
log "Week: $WEEK"
log "======================================"

# ============================================
# WORKFLOW 1: Deep Prospect Research
# ============================================
run_deep_research() {
    log "Starting: Deep Prospect Research"
    
    INDUSTRIES="${1:-healthcare,financial_services,professional_services}"
    PROSPECTS_PER="${2:-3}"
    
    cd "$PROJECT_DIR"
    
    claude -p "
    Read agents/prospect-finder.md and execute weekly deep research:
    
    Target Industries: $INDUSTRIES
    Prospects per industry: $PROSPECTS_PER
    
    For each industry:
    
    1. Run comprehensive search queries:
       - '[industry] Australia AI automation 2025'
       - '[industry] digital transformation Melbourne Sydney'
       - 'Australian [industry] process automation'
       - '[industry] hiring technology roles Australia'
    
    2. For each promising company found:
       a. Company Research:
          - Business model and size
          - Recent news and announcements
          - Technology stack (from job posts, case studies)
          - Funding/financial health signals
          
       b. Contact Research:
          - CEO, CTO, CIO, Head of Operations
          - LinkedIn profiles and activity
          - Recent content/speaking
          
       c. AI Readiness Assessment:
          - Current AI/automation initiatives
          - Cloud platform usage
          - Data maturity signals
          
       d. Qualification Scoring:
          - Company size fit (20%)
          - Budget signals (25%)
          - Pain point clarity (25%)
          - Decision maker access (15%)
          - Security/compliance need (15%)
    
    3. Select top $PROSPECTS_PER per industry based on score
    
    4. For each qualified prospect, create detailed profile:
       outputs/weekly/$WEEK/prospects/[company-name].md
       
       Include:
       - Full company overview
       - Key contacts with LinkedIn URLs
       - Buying signals detected
       - Pain points identified
       - Recommended approach
       - Draft initial outreach message
       - Relevant use cases for their situation
    
    5. Add to data/prospects.csv with:
       - All profile data
       - qualification_score
       - sequence_status = 'new'
       - next_touch_date = tomorrow
    
    6. Create outputs/weekly/$WEEK/RESEARCH-SUMMARY.md:
       - Total companies researched
       - Qualified prospects by industry
       - Top opportunities with rationale
       - Industry observations/trends
       - Recommended focus areas
    " > "$OUTPUT_DIR/$WEEK/research.log" 2>&1
    
    log "Completed: Deep Prospect Research"
}

# ============================================
# WORKFLOW 2: Content Calendar Generation
# ============================================
run_content_generation() {
    log "Starting: Content Calendar Generation"
    
    cd "$PROJECT_DIR"
    
    claude -p "
    Read agents/content-engine.md and create this week's content:
    
    1. Determine themes based on:
       - Current pipeline industries (check data/prospects.csv)
       - Recent meeting topics (check data/meetings.csv)
       - Current AI/security news trends
    
    2. Generate LinkedIn posts (save to outputs/weekly/$WEEK/content/linkedin/):
       
       tuesday-post.md:
       - Type: Educational
       - Topic: [Based on theme 1]
       - Hook + content + CTA
       - Hashtags
       
       wednesday-post.md:
       - Type: Insight/Opinion
       - Topic: [Based on theme 2]
       - Contrarian or thought-provoking angle
       
       thursday-post.md:
       - Type: Engagement (question or mini case study)
       - Topic: [Based on pipeline]
       - Drive comments and discussion
    
    3. Generate blog article (save to outputs/weekly/$WEEK/content/blog/):
       
       blog-article.md:
       - Topic: Aligned with top pipeline industry
       - SEO keyword target
       - 1,500-2,000 words
       - Clear structure with headings
       - Include practical examples
       - Soft CTA at end
    
    4. Create outputs/weekly/$WEEK/content/CONTENT-CALENDAR.md:
       
       | Day | Platform | Title | Status | Publish Time |
       |-----|----------|-------|--------|--------------|
       | Tue | LinkedIn | [title] | Draft | 8:30am AEST |
       | Wed | LinkedIn | [title] | Draft | 12:00pm AEST |
       | Thu | LinkedIn | [title] | Draft | 8:30am AEST |
       | Fri | Blog | [title] | Draft | 10:00am AEST |
       
       Include:
       - Themes for the week
       - Publishing instructions
       - Image requirements (if any)
    " > "$OUTPUT_DIR/$WEEK/content.log" 2>&1
    
    log "Completed: Content Calendar Generation"
}

# ============================================
# WORKFLOW 3: Pipeline Health Report
# ============================================
run_pipeline_report() {
    log "Starting: Pipeline Health Report"
    
    cd "$PROJECT_DIR"
    
    claude -p "
    Generate weekly pipeline report:
    
    1. Analyse data/prospects.csv:
       - Total active prospects
       - By stage: new, contacted, engaged, meeting_scheduled, proposal_sent, negotiating
       - By qualification: hot (>=3.5), warm (2.5-3.5), nurture (<2.5)
       - By industry breakdown
       - Week-over-week changes
    
    2. Analyse data/outreach-tracking.csv:
       - Total touches this week
       - By channel (email vs LinkedIn)
       - Response rate
       - Positive response rate
       - Best performing templates/approaches
    
    3. Analyse data/meetings.csv:
       - Meetings held this week
       - Outcomes (hot/warm/cold/lost)
       - Conversion rate from meeting to proposal
       - Upcoming meetings next week
    
    4. Identify issues:
       - Stale prospects (no activity >14 days)
       - Hot leads not contacted in >3 days
       - Proposals without follow-up >7 days
       - Sequences with poor response rates
    
    5. Create outputs/weekly/$WEEK/PIPELINE-REPORT.md:
       
       # Pipeline Report - Week $WEEK
       
       ## Executive Summary
       [2-3 sentence overview of pipeline health]
       
       ## Key Metrics
       | Metric | This Week | Last Week | Change |
       |--------|-----------|-----------|--------|
       | Active Prospects | X | X | +/-X |
       | Meetings Held | X | X | +/-X |
       | Proposals Sent | X | X | +/-X |
       | Response Rate | X% | X% | +/-X% |
       
       ## Pipeline by Stage
       [Breakdown with counts and values]
       
       ## Activity Summary
       - Outreach sent: X
       - Responses received: X
       - Meetings scheduled: X
       - Proposals created: X
       
       ## Issues & Action Items
       - [ ] [Specific action with prospect name]
       - [ ] [Specific action with prospect name]
       
       ## Wins & Highlights
       - [Any positive developments]
       
       ## Next Week Focus
       - [Priority 1]
       - [Priority 2]
       - [Priority 3]
       
       ## Recommendations
       [Strategic suggestions based on data]
    " > "$OUTPUT_DIR/$WEEK/report.log" 2>&1
    
    log "Completed: Pipeline Health Report"
}

# ============================================
# WORKFLOW 4: Nurture List Review
# ============================================
run_nurture_review() {
    log "Starting: Nurture List Review"
    
    cd "$PROJECT_DIR"
    
    claude -p "
    Review nurture list for re-engagement opportunities:
    
    1. From data/prospects.csv, find all with:
       - sequence_status = 'nurture'
       - last_touch_date > 60 days ago
    
    2. For each, research for new signals:
       - New job postings
       - Recent news
       - Leadership changes
       - Funding/growth announcements
    
    3. If new signal found:
       - Update prospect record
       - Change sequence_status to 'reactivate'
       - Draft re-engagement message referencing new signal
    
    4. Create outputs/weekly/$WEEK/NURTURE-REVIEW.md:
       
       ## Nurture List Review - $WEEK
       
       ### Prospects Reviewed: X
       
       ### Reactivation Candidates:
       
       #### [Company Name]
       - Original date added: [date]
       - New signal: [signal]
       - Recommended action: [action]
       - Draft message: [message]
       
       ### Still Nurturing: X
       [List of prospects with no new signals]
       
       ### Remove from List: X
       [Any that should be archived - company closed, etc.]
    " > "$OUTPUT_DIR/$WEEK/nurture.log" 2>&1
    
    log "Completed: Nurture List Review"
}

# ============================================
# MAIN EXECUTION
# ============================================

# Parse command line arguments
WORKFLOW="${1:-all}"
INDUSTRIES="${2:-healthcare,financial_services,professional_services}"

case $WORKFLOW in
    "research")
        run_deep_research "$INDUSTRIES" "${3:-3}"
        ;;
    "content")
        run_content_generation
        ;;
    "report")
        run_pipeline_report
        ;;
    "nurture")
        run_nurture_review
        ;;
    "all")
        run_deep_research "$INDUSTRIES" "${3:-3}"
        run_content_generation
        run_pipeline_report
        run_nurture_review
        ;;
    *)
        echo "Usage: $0 [research|content|report|nurture|all] [industries] [prospects_per_industry]"
        echo "Example: $0 research 'healthcare,fintech' 5"
        exit 1
        ;;
esac

log "======================================"
log "Weekly Workflow Completed Successfully"
log "======================================"
log "Outputs saved to: $OUTPUT_DIR/$WEEK/"

# Create week summary
cat > "$OUTPUT_DIR/$WEEK/README.md" << EOF
# Week $WEEK Outputs

Generated: $(date)

## Contents

- \`prospects/\` - Detailed profiles for new qualified prospects
- \`content/\` - LinkedIn posts and blog article for the week
- \`RESEARCH-SUMMARY.md\` - Overview of prospect research
- \`CONTENT-CALENDAR.md\` - Publishing schedule
- \`PIPELINE-REPORT.md\` - Weekly pipeline metrics
- \`NURTURE-REVIEW.md\` - Reactivation opportunities

## Quick Actions

1. Review and approve content in \`content/\`
2. Send outreach to new prospects in \`prospects/\`
3. Address action items in pipeline report
4. Follow up on reactivation candidates
EOF

log "Week $WEEK README created"
