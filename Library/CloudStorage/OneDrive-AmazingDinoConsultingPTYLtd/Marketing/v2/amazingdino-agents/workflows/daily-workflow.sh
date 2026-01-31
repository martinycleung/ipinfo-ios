#!/bin/bash
# Amazing Dino Lead Generation - Daily Automation Script
# Run this script daily or set up as cron job
#
# IMPORTANT: This script creates DRAFTS and PLANS only.
# It does NOT send emails or LinkedIn messages automatically.
# All outputs require human review before sending.
#
# Usage: ./daily-workflow.sh [scan|validate|outreach|meetings|summary|all|safe] [--direct]
#        --direct: Process data directly without external claude calls

set -e

# Configuration
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$0")/..}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"  # Resolve to absolute path
LOG_DIR="$PROJECT_DIR/logs"
OUTPUT_DIR="$PROJECT_DIR/outputs/daily"
DATA_DIR="$PROJECT_DIR/data"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOCK_FILE="$PROJECT_DIR/.daily-workflow.lock"
DIRECT_MODE=false

# Check for --direct flag
for arg in "$@"; do
    if [[ "$arg" == "--direct" ]]; then
        DIRECT_MODE=true
    fi
done

# Platform-compatible date function for tomorrow
get_tomorrow() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -v+1d +%Y-%m-%d
    else
        date -d "+1 day" +%Y-%m-%d
    fi
}

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
mkdir -p "$OUTPUT_DIR/$DATE"
mkdir -p "$OUTPUT_DIR/$DATE/outreach"
mkdir -p "$OUTPUT_DIR/$DATE/linkedin"

# Logging function
log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_DIR/$DATE.log"
}

# Error handling
handle_error() {
    log "ERROR: $1"
    # Send notification (configure your method)
    # if [ -n "$SLACK_WEBHOOK" ]; then
    #     curl -X POST "$SLACK_WEBHOOK" -H "Content-Type: application/json" \
    #         -d "$(jq -n --arg msg "$1" '{"text": ("LeadGen Error: " + $msg)}')"
    # fi
    exit 1
}

# Acquire lock before starting
acquire_lock

log "======================================"
log "Daily Lead Generation Workflow Started"
log "======================================"

# ============================================
# WORKFLOW 1: Morning Prospect Signal Scan
# ============================================
run_prospect_scan() {
    log "Starting: Prospect Signal Scan"
    
    cd "$PROJECT_DIR"
    
    # Run Claude Code for prospect scanning
    claude -p "
    Read agents/prospect-finder.md and execute daily signal scan:
    
    1. Search job boards for AI/automation hiring signals:
       - seek.com.au: 'AI implementation' OR 'process automation' Australia
       - LinkedIn Jobs: automation manager Australia
    
    2. Search news for AI announcements:
       - Australian company AI strategy 2025
       - site:afr.com AI automation
       - site:itnews.com.au digital transformation
    
    3. For each company found:
       - Check if exists in data/prospects.csv
       - If new: create brief profile
       - If existing: note new signal
    
    4. Output to outputs/daily/$DATE/prospect-signals.md:
       - List of new signals found
       - New companies identified
       - Existing prospects with new signals
    
    Keep it concise - focus on actionable signals only.
    " > "$OUTPUT_DIR/$DATE/prospect-scan.log" 2>&1 || handle_error "Prospect scan failed"
    
    log "Completed: Prospect Signal Scan"
}

# ============================================
# WORKFLOW 1.5: Contact Validation (REQUIRED)
# ============================================
run_validation() {
    log "Starting: Contact Validation"

    cd "$PROJECT_DIR"

    # Ensure output directory exists
    mkdir -p "$OUTPUT_DIR/$DATE"

    # Run validation script
    if [ -f "$PROJECT_DIR/scripts/validate_contacts.py" ]; then
        log "Running Python validation..."
        python3 "$PROJECT_DIR/scripts/validate_contacts.py" --report 2>&1 | tee "$OUTPUT_DIR/$DATE/validation.log"
        VALIDATION_RESULT=${PIPESTATUS[0]}
    elif [ -f "$PROJECT_DIR/scripts/validate-contacts.sh" ]; then
        log "Running shell validation..."
        bash "$PROJECT_DIR/scripts/validate-contacts.sh" --quick 2>&1 | tee "$OUTPUT_DIR/$DATE/validation.log"
        VALIDATION_RESULT=${PIPESTATUS[0]}
    else
        log "WARNING: No validation script found!"
        VALIDATION_RESULT=1
    fi

    log ""
    if [ $VALIDATION_RESULT -ne 0 ]; then
        log "========================================"
        log "ERROR: Contact validation FAILED!"
        log "========================================"
        log ""
        log "!!! OUTREACH BLOCKED - Fix contacts before sending !!!"
        log ""
        log "Common issues:"
        log "  - Fake/guessed email addresses (NEEDS_VERIFICATION)"
        log "  - Auto-generated LinkedIn URLs"
        log "  - Placeholder signal URLs (NEEDS_REAL_URL)"
        log ""
        log "To fix:"
        log "  1. Review: outputs/validation-report-$DATE.md"
        log "  2. Update contacts with REAL verified information"
        log "  3. Replace placeholder URLs with actual URLs"
        log "  4. Re-run: ./workflows/daily-workflow.sh validate"
        log ""

        # Create a block file to prevent outreach
        touch "$PROJECT_DIR/.validation-failed"
        log "Created .validation-failed flag - outreach blocked"
        return 1
    else
        log "========================================"
        log "Contact validation PASSED"
        log "========================================"
        rm -f "$PROJECT_DIR/.validation-failed"
    fi

    log "Completed: Contact Validation"
}

# ============================================
# WORKFLOW 2: Outreach Execution
# ============================================
run_outreach() {
    log "Starting: Outreach Generation"

    cd "$PROJECT_DIR"

    # CHECK: Validation must pass before outreach
    if [ -f "$PROJECT_DIR/.validation-failed" ]; then
        log "ERROR: Cannot run outreach - validation failed!"
        log "Run './daily-workflow.sh validate' first and fix issues"
        return 1
    fi

    # Double-check validation
    if [ -f "$PROJECT_DIR/scripts/validate_contacts.py" ]; then
        python3 "$PROJECT_DIR/scripts/validate_contacts.py" --quick > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            log "ERROR: Pre-outreach validation check failed!"
            log "Contacts have issues - run validation first"
            return 1
        fi
    fi

    log "Validation check passed - proceeding with outreach"

    claude -p "
    Read agents/02-outreach-sequencer-agent.md and CREATE OUTREACH DRAFTS (do not send):

    IMPORTANT: This creates DRAFTS ONLY. Do NOT send any emails or LinkedIn messages.
    All outputs require human review before manual sending.

    1. Check data/outreach-tracking.csv for touches due today

    2. For each prospect due:
       - Load their profile from data/prospects.csv
       - CHECK: Skip if validation_status is 'invalid' or email is 'NEEDS_VERIFICATION'
       - Determine sequence stage (day_0, day_3, day_7, day_14, day_21)
       - CREATE DRAFT email using templates (DO NOT SEND)

    3. Save each DRAFT to outputs/daily/$DATE/outreach/[company-name].md
       Format:
       ---
       STATUS: DRAFT - REQUIRES HUMAN REVIEW
       To: [email]
       Subject: [subject]
       Sequence Stage: [stage]
       ---
       [email body]
       ---
       ACTION REQUIRED:
       [ ] Review and personalize
       [ ] Verify contact is valid
       [ ] Send manually via email client
       [ ] Update tracking after sending

    4. For day_3 prospects, also CREATE DRAFT LinkedIn connection message
       Save to outputs/daily/$DATE/linkedin/[company-name].md
       Mark as DRAFT - DO NOT SEND

    5. Create outputs/daily/$DATE/OUTREACH-CHECKLIST.md with:

       # Outreach Drafts for Review - $DATE

       ## REMINDER: These are DRAFTS - Manual sending required

       ### Email Drafts to Review:
       - [ ] Email: [Company] - [Contact] - [Subject line]

       ### LinkedIn Drafts to Review:
       - [ ] LinkedIn: [Company] - [Contact]

       Total: X email drafts, Y LinkedIn drafts ready for review

       ## Next Steps:
       1. Review each draft in outputs/daily/$DATE/outreach/
       2. Personalize as needed
       3. Send manually via your email client
       4. Update data/outreach-tracking.csv after sending
    " > "$OUTPUT_DIR/$DATE/outreach.log" 2>&1 || handle_error "Outreach draft generation failed"
    
    log "Completed: Outreach Generation"
}

# ============================================
# WORKFLOW 3: Check for Scheduled Meetings
# ============================================
check_meetings() {
    log "Starting: Meeting Check"

    cd "$PROJECT_DIR"

    # Check for meetings tomorrow that need prep
    TOMORROW=$(get_tomorrow)
    
    claude -p "
    Check data/meetings.csv for meetings scheduled tomorrow ($TOMORROW).
    
    For each meeting found:
    1. Check if briefing already exists in outputs/briefings/
    2. If no briefing exists, trigger meeting prep:
       - Read agents/meeting-prep.md
       - Execute full research and briefing creation
       - Save to outputs/briefings/$TOMORROW-[company-name].md
    
    Output summary to outputs/daily/$DATE/meetings-tomorrow.md:
    - List of tomorrow's meetings
    - Briefing status (ready/in-progress/needed)
    - Any prep actions required
    " > "$OUTPUT_DIR/$DATE/meetings.log" 2>&1 || handle_error "Meeting check failed"
    
    log "Completed: Meeting Check"
}

# ============================================
# WORKFLOW 4: End of Day Summary
# ============================================
generate_summary() {
    log "Starting: Daily Summary"
    
    cd "$PROJECT_DIR"
    
    claude -p "
    Generate end-of-day summary for $DATE:
    
    1. Count from data files:
       - New prospects added today
       - Outreach touches due today
       - Responses received (if logged)
       - Meetings scheduled
    
    2. Check outputs/daily/$DATE/ for:
       - Signals found
       - Emails drafted
       - Briefings created
    
    3. Create outputs/daily/$DATE/DAILY-SUMMARY.md:
    
       # Daily Summary - $DATE
       
       ## Pipeline Activity
       - New signals: X
       - New prospects: X
       - Outreach drafted: X emails, X LinkedIn
       
       ## Meetings
       - Tomorrow: [list]
       - This week: [count]
       
       ## Action Items for Tomorrow
       - [ ] Send drafted outreach
       - [ ] Review new prospects
       - [ ] [other items]
       
       ## Notes
       [Any observations or recommendations]
    " > "$OUTPUT_DIR/$DATE/summary.log" 2>&1 || handle_error "Summary generation failed"
    
    log "Completed: Daily Summary"
}

# ============================================
# MAIN EXECUTION
# ============================================

# Parse command line arguments
WORKFLOW="${1:-all}"

case $WORKFLOW in
    "scan")
        run_prospect_scan
        ;;
    "validate")
        run_validation
        ;;
    "outreach")
        run_outreach
        ;;
    "meetings")
        check_meetings
        ;;
    "summary")
        generate_summary
        ;;
    "all")
        run_prospect_scan
        run_validation || { log "Stopping workflow - validation failed"; exit 1; }
        run_outreach
        check_meetings
        generate_summary
        ;;
    "safe")
        # Safe mode: scan + validate only, no outreach
        run_prospect_scan
        run_validation
        ;;
    *)
        echo "Usage: $0 [scan|validate|outreach|meetings|summary|all|safe]"
        echo ""
        echo "  scan      - Search for new prospect signals"
        echo "  validate  - Validate all contacts (REQUIRED before outreach)"
        echo "  outreach  - Generate outreach emails (requires validation)"
        echo "  meetings  - Check and prepare for upcoming meetings"
        echo "  summary   - Generate daily summary"
        echo "  all       - Run full workflow (includes validation gate)"
        echo "  safe      - Run scan + validate only (no outreach)"
        exit 1
        ;;
esac

log "======================================"
log "Daily Workflow Completed Successfully"
log "======================================"
log "Outputs saved to: $OUTPUT_DIR/$DATE/"

# Optional: Send completion notification
# curl -X POST "$SLACK_WEBHOOK" -d '{"text":"✅ Daily lead gen complete. Check outputs/daily/'"$DATE"'/"}'
