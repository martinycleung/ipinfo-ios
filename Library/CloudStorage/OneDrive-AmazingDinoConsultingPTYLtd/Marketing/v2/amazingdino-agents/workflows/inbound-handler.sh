#!/bin/bash
# Inbound Lead Handler
# Called when new lead comes in via webhook/form/email

set -e

PROJECT_DIR="${PROJECT_DIR:-$(dirname "$0")/..}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"  # Resolve to absolute path
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Sanitize string for use in filenames (removes dangerous characters)
sanitize_filename() {
    echo "$1" | tr -cd '[:alnum:] ._-' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/--*/-/g'
}

# Escape a value for CSV (handle commas, quotes, newlines)
csv_escape() {
    local val="$1"
    # If value contains comma, quote, or newline, wrap in quotes and escape internal quotes
    if echo "$val" | grep -qE '[,"\n\r]'; then
        val="${val//\"/\"\"}"  # Escape quotes by doubling them
        echo "\"$val\""
    else
        echo "$val"
    fi
}

# Parse input (expects JSON via stdin or as argument)
if [ -n "$1" ]; then
    INPUT="$1"
else
    INPUT=$(cat)
fi

# Extract fields (using jq if available, otherwise basic parsing)
if command -v jq &> /dev/null; then
    SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')
    COMPANY=$(echo "$INPUT" | jq -r '.company // "Unknown Company"')
    CONTACT_NAME=$(echo "$INPUT" | jq -r '.contact_name // "Unknown"')
    EMAIL=$(echo "$INPUT" | jq -r '.email // ""')
    MESSAGE=$(echo "$INPUT" | jq -r '.message // ""')
else
    # Basic extraction without jq - attempt to parse simple JSON
    # Extract value for a key: grep for "key": "value" pattern
    extract_json_value() {
        echo "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*: *"\([^"]*\)"/\1/' | head -1
    }

    SOURCE=$(extract_json_value "source")
    SOURCE="${SOURCE:-unknown}"
    COMPANY=$(extract_json_value "company")
    COMPANY="${COMPANY:-Unknown Company}"
    CONTACT_NAME=$(extract_json_value "contact_name")
    CONTACT_NAME="${CONTACT_NAME:-Unknown}"
    EMAIL=$(extract_json_value "email")
    EMAIL="${EMAIL:-}"
    MESSAGE=$(extract_json_value "message")
    MESSAGE="${MESSAGE:-}"
fi

# Create safe filename version of company
SAFE_COMPANY=$(sanitize_filename "$COMPANY")

echo "======================================"
echo "Inbound Lead Received"
echo "Source: $SOURCE"
echo "Company: $COMPANY"
echo "Contact: $CONTACT_NAME"
echo "Email: $EMAIL"
echo "======================================"

mkdir -p "$PROJECT_DIR/outputs/inbound"
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/data"

cd "$PROJECT_DIR"

# Log the inbound lead with proper CSV escaping
CSV_DATE=$(csv_escape "$DATE")
CSV_SOURCE=$(csv_escape "$SOURCE")
CSV_COMPANY=$(csv_escape "$COMPANY")
CSV_CONTACT=$(csv_escape "$CONTACT_NAME")
CSV_EMAIL=$(csv_escape "$EMAIL")
echo "$CSV_DATE,$CSV_SOURCE,$CSV_COMPANY,$CSV_CONTACT,$CSV_EMAIL" >> data/inbound-leads.csv

# Process with Claude Code
claude -p "
New inbound lead received. Process immediately.

Lead Details:
- Source: $SOURCE
- Company: $COMPANY
- Contact: $CONTACT_NAME
- Email: $EMAIL
- Message: $MESSAGE

Execute:

1. IMMEDIATE ACKNOWLEDGMENT
   Generate quick response (send within 1 hour):
   
   Subject: Thanks for reaching out, $CONTACT_NAME
   
   Body should:
   - Thank them for contacting Amazing Dino
   - Acknowledge their specific inquiry
   - Promise follow-up within 24 hours
   - Offer a relevant resource if appropriate
   
   Save to: outputs/inbound/$DATE-$COMPANY-ack.md

2. QUICK RESEARCH
   Search for:
   - '$COMPANY' company overview
   - '$COMPANY' industry
   - '$COMPANY' size employees
   - '$CONTACT_NAME $COMPANY' LinkedIn
   
   Determine:
   - Company size (employee count)
   - Industry
   - Likely pain points
   - Initial qualification score

3. ADD TO PIPELINE
   Add to data/prospects.csv:
   - company_name = $COMPANY
   - contact_name = $CONTACT_NAME
   - contact_email = $EMAIL
   - source = inbound_$SOURCE
   - sequence_status = inbound_hot
   - next_touch_date = today
   - priority = high
   
4. PREPARE FOLLOW-UP
   Generate personalised response:
   - Reference their specific inquiry
   - Show understanding of their situation
   - Propose next step (call, demo, more info)
   - Include relevant case study or resource
   
   Save to: outputs/inbound/$DATE-$COMPANY-response.md

5. CREATE ALERT
   Save to: outputs/inbound/$DATE-$COMPANY-ALERT.md
   
   # 🚨 NEW INBOUND LEAD
   
   **Company:** $COMPANY
   **Contact:** $CONTACT_NAME ($EMAIL)
   **Source:** $SOURCE
   **Received:** $TIMESTAMP
   
   ## Quick Assessment
   [Initial qualification]
   
   ## Immediate Actions
   - [ ] Send acknowledgment email (within 1 hour)
   - [ ] Review and send detailed response (within 24 hours)
   - [ ] Schedule follow-up call
   
   ## Prepared Responses
   - Acknowledgment: outputs/inbound/$DATE-$COMPANY-ack.md
   - Detailed response: outputs/inbound/$DATE-$COMPANY-response.md

Inbound leads are highest priority - they came to us.
" > "$PROJECT_DIR/logs/inbound-$SAFE_COMPANY-$DATE.log" 2>&1

echo ""
echo "Lead processed. Check outputs/inbound/ for prepared responses."
echo ""

# Optional: Send notification
# Uncomment and configure your preferred method:

# Slack notification
# curl -X POST "$SLACK_WEBHOOK" -H 'Content-type: application/json' \
#   -d "{\"text\":\"🚨 New inbound lead: $COMPANY - $CONTACT_NAME\\nSource: $SOURCE\\nCheck outputs/inbound/ for responses\"}"

# Email notification
# echo "New inbound lead: $COMPANY from $CONTACT_NAME ($EMAIL)" | \
#   mail -s "🚨 Inbound Lead: $COMPANY" martin@amazingdino.au

# macOS notification
# osascript -e "display notification \"$COMPANY - $CONTACT_NAME\" with title \"New Inbound Lead\""

echo "Done."
