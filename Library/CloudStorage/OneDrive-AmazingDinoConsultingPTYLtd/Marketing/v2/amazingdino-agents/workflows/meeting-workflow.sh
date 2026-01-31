#!/bin/bash
# Amazing Dino Lead Generation - Meeting Workflow Script
# Triggered workflows for meeting prep and post-meeting processing

set -e

# Configuration
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$0")/..}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"  # Resolve to absolute path
LOG_DIR="$PROJECT_DIR/logs"
OUTPUT_DIR="$PROJECT_DIR/outputs"
DATE=$(date +%Y-%m-%d)

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_DIR/meetings-$DATE.log"
}

# Platform-compatible date function for tomorrow
get_tomorrow() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date -v+1d +%Y-%m-%d
    else
        date -d "+1 day" +%Y-%m-%d
    fi
}

# Sanitize string for use in filenames (removes dangerous characters)
sanitize_filename() {
    echo "$1" | tr -cd '[:alnum:] ._-' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/--*/-/g'
}

# ============================================
# WORKFLOW: Meeting Prep
# ============================================
meeting_prep() {
    COMPANY="$1"
    CONTACT="$2"
    MEETING_DATE="$3"
    MEETING_TYPE="${4:-discovery}"

    if [ -z "$COMPANY" ] || [ -z "$CONTACT" ]; then
        echo "Usage: $0 prep 'Company Name' 'Contact Name' [meeting_date] [meeting_type]"
        exit 1
    fi

    MEETING_DATE="${MEETING_DATE:-$(get_tomorrow)}"
    SAFE_COMPANY=$(sanitize_filename "$COMPANY")
    
    log "======================================"
    log "Meeting Prep: $COMPANY"
    log "Contact: $CONTACT"
    log "Date: $MEETING_DATE"
    log "======================================"
    
    mkdir -p "$OUTPUT_DIR/briefings"
    
    cd "$PROJECT_DIR"
    
    claude -p "
    Read agents/meeting-prep.md and create comprehensive briefing.
    
    Meeting Details:
    - Company: $COMPANY
    - Contact: $CONTACT
    - Date: $MEETING_DATE
    - Type: $MEETING_TYPE
    
    Execute full research:
    
    1. COMPANY DEEP DIVE
       - Search for '$COMPANY' company profile, business model
       - Search for '$COMPANY' recent news 2024 2025
       - Search for '$COMPANY' technology stack, cloud platform
       - Search for '$COMPANY' competitors, market position
       - Check for AI/automation initiatives
       - Look for financial health signals
    
    2. CONTACT RESEARCH
       - Search for '$CONTACT $COMPANY LinkedIn'
       - Find career history and background
       - Look for recent posts, articles, speaking
       - Identify communication style
       - Find mutual connections if any
    
    3. INDUSTRY CONTEXT
       - AI adoption in their industry
       - Regulatory requirements
       - Common pain points
       - Competitor AI usage
    
    4. INTERNAL HISTORY
       - Check data/prospects.csv for existing info
       - Check data/outreach-tracking.csv for prior touches
       - Review any previous notes
    
    5. CREATE BRIEFING
       Save to: outputs/briefings/$MEETING_DATE-$(echo '$COMPANY' | tr ' ' '-' | tr '[:upper:]' '[:lower:]').md
       
       Include ALL sections from meeting-prep agent:
       - Quick Reference (2-min read before call)
       - Company Overview with key stats
       - Contact Profile with background
       - Pain Points with evidence
       - Relevant Use Cases (3 specific to them)
       - Competitive Context
       - Objection Handling
       - Discovery Questions (at least 10, customised)
       - Suggested Agenda
       - Next Steps options
    
    Make it comprehensive but scannable. Executive should be able to prep in 10 minutes.
    " > "$LOG_DIR/prep-$SAFE_COMPANY-$DATE.log" 2>&1

    BRIEFING_FILE="$OUTPUT_DIR/briefings/$MEETING_DATE-$SAFE_COMPANY.md"
    
    log "Briefing created: $BRIEFING_FILE"
    log "Meeting prep complete"
}

# ============================================
# WORKFLOW: Post-Meeting Processing
# ============================================
post_meeting() {
    COMPANY="$1"
    OUTCOME="$2"  # hot, warm, cold, lost
    PROPOSAL_NEEDED="$3"  # yes, no
    NOTES_FILE="$4"  # path to meeting notes file

    if [ -z "$COMPANY" ] || [ -z "$OUTCOME" ]; then
        echo "Usage: $0 post 'Company Name' [hot|warm|cold|lost] [yes|no] [notes_file]"
        exit 1
    fi

    SAFE_COMPANY=$(sanitize_filename "$COMPANY")

    log "======================================"
    log "Post-Meeting Processing: $COMPANY"
    log "Outcome: $OUTCOME"
    log "Proposal Needed: $PROPOSAL_NEEDED"
    log "======================================"

    mkdir -p "$OUTPUT_DIR/meetings/$DATE-$SAFE_COMPANY"
    MEETING_OUTPUT_DIR="$OUTPUT_DIR/meetings/$DATE-$SAFE_COMPANY"
    
    # Read notes if file provided
    NOTES=""
    if [ -n "$NOTES_FILE" ] && [ -f "$NOTES_FILE" ]; then
        NOTES=$(cat "$NOTES_FILE")
    fi
    
    cd "$PROJECT_DIR"
    
    # Generate follow-up email
    claude -p "
    Read agents/outreach-sequencer.md.
    
    Meeting just completed with $COMPANY.
    Outcome: $OUTCOME
    
    Meeting Notes:
    $NOTES
    
    1. Generate thank-you/follow-up email:
       - Reference specific points from the meeting
       - Summarise agreed next steps
       - Professional but warm tone
       - Include any promised follow-up items
       
    Save to: $MEETING_OUTPUT_DIR/follow-up-email.md
    
    Format:
    ---
    To: [contact email from data/prospects.csv]
    Subject: Great connecting today - [topic discussed]
    ---
    
    [Email body]
    
    ---
    Send by: [today/tomorrow]
    " > "$LOG_DIR/followup-$SAFE_COMPANY-$DATE.log" 2>&1
    
    log "Follow-up email generated"
    
    # Generate proposal if needed
    if [ "$PROPOSAL_NEEDED" = "yes" ]; then
        log "Generating proposal..."
        
        claude -p "
        Read agents/proposal-generator.md.
        
        Create proposal for $COMPANY based on meeting.
        
        Meeting Notes:
        $NOTES
        
        Meeting Outcome: $OUTCOME
        
        1. Parse meeting notes for:
           - Key pain points discussed
           - Specific requirements mentioned
           - Budget range (if discussed)
           - Timeline expectations
           - Decision makers identified
           - Use cases of interest
        
        2. Generate full proposal following the template:
           - Executive Summary
           - Understanding Your Situation
           - Proposed Solution (with components)
           - Implementation Approach
           - Investment (with options if budget unclear)
           - ROI Analysis
           - Why Amazing Dino
           - Next Steps
        
        3. Save to: $MEETING_OUTPUT_DIR/proposal.md
        
        Make it specific to their situation - not generic.
        Reference exact points from the meeting.
        " > "$LOG_DIR/proposal-$SAFE_COMPANY-$DATE.log" 2>&1
        
        log "Proposal generated"
    fi
    
    # Update tracking
    claude -p "
    Update tracking files after meeting with $COMPANY:
    
    1. In data/meetings.csv, update the row for $COMPANY:
       - status = completed
       - outcome = $OUTCOME
       - meeting_notes = [summary of notes]
       - follow_up_sent = pending
       - proposal_needed = $PROPOSAL_NEEDED
    
    2. In data/prospects.csv, update $COMPANY:
       - last_meeting_date = $DATE
       - stage = [based on outcome: $OUTCOME]
         - hot → proposal_sent or negotiating
         - warm → engaged
         - cold → nurture
         - lost → closed_lost
       - Update qualification_score based on meeting insights
    
    3. In data/outreach-tracking.csv, add entries:
       - Follow-up email: due today
       - If proposal sent: follow-up in 3 days
       - Check-in call: in 7 days
    
    4. Create $MEETING_OUTPUT_DIR/ACTIONS.md:
       
       # Post-Meeting Actions: $COMPANY
       Date: $DATE
       
       ## Immediate (Today)
       - [ ] Send follow-up email
       - [ ] Send proposal (if applicable)
       - [ ] Update CRM
       
       ## This Week
       - [ ] Proposal follow-up (Day 3)
       - [ ] Check-in call (Day 7)
       
       ## Notes for Next Touch
       [Key points to remember]
    " > "$LOG_DIR/tracking-$SAFE_COMPANY-$DATE.log" 2>&1
    
    log "Tracking updated"
    log "Post-meeting processing complete"
    log "Outputs in: $MEETING_OUTPUT_DIR/"
}

# ============================================
# WORKFLOW: Quick Meeting Notes
# ============================================
quick_notes() {
    COMPANY="$1"

    if [ -z "$COMPANY" ]; then
        echo "Usage: $0 notes 'Company Name'"
        echo "Opens editor for quick meeting notes entry"
        exit 1
    fi

    SAFE_COMPANY=$(sanitize_filename "$COMPANY")
    # Use mktemp for secure temp file, or fall back to project temp dir
    if command -v mktemp &> /dev/null; then
        NOTES_FILE=$(mktemp "${TMPDIR:-/tmp}/meeting-notes-$SAFE_COMPANY-XXXXXX.md")
    else
        mkdir -p "$PROJECT_DIR/tmp"
        NOTES_FILE="$PROJECT_DIR/tmp/meeting-notes-$SAFE_COMPANY-$DATE.md"
    fi
    
    cat > "$NOTES_FILE" << 'EOF'
# Meeting Notes

## Attendees
- 

## Key Discussion Points
- 

## Pain Points Identified
- 

## Budget Discussed
- 

## Timeline
- 

## Decision Makers
- 

## Next Steps Agreed
- 

## Objections/Concerns Raised
- 

## Specific Requirements
- 

## Our Recommended Solution
- 

## Outcome (hot/warm/cold/lost)

EOF
    
    # Open in default editor
    ${EDITOR:-nano} "$NOTES_FILE"
    
    echo "Notes saved to: $NOTES_FILE"
    echo "To process: $0 post '$COMPANY' [outcome] [proposal_needed] '$NOTES_FILE'"
}

# ============================================
# MAIN EXECUTION
# ============================================

ACTION="${1:-help}"

case $ACTION in
    "prep")
        meeting_prep "$2" "$3" "$4" "$5"
        ;;
    "post")
        post_meeting "$2" "$3" "$4" "$5"
        ;;
    "notes")
        quick_notes "$2"
        ;;
    "help"|*)
        echo "Meeting Workflow Commands:"
        echo ""
        echo "  $0 prep 'Company' 'Contact' [date] [type]"
        echo "    Create meeting briefing document"
        echo "    Example: $0 prep 'ABC Corp' 'John Smith' '2025-02-01' 'discovery'"
        echo ""
        echo "  $0 post 'Company' [outcome] [proposal] [notes_file]"
        echo "    Process completed meeting"
        echo "    Example: $0 post 'ABC Corp' 'hot' 'yes' './notes.md'"
        echo ""
        echo "  $0 notes 'Company'"
        echo "    Open editor for quick meeting notes"
        echo "    Example: $0 notes 'ABC Corp'"
        echo ""
        ;;
esac
