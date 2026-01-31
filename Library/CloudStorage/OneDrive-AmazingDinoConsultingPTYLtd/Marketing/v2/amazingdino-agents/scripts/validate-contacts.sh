#!/bin/bash
# Contact Validation Script for Amazing Dino Lead Generation
# Validates contacts before allowing outreach
#
# Usage: ./validate-contacts.sh [--full | --quick] [--update]
#        --full:   Check LinkedIn URLs and email domains (slower, requires network)
#        --quick:  Only format validation and pattern checks (fast, offline)
#        --update: Update the CSV with validation results

set -e

PROJECT_DIR="${PROJECT_DIR:-$(dirname "$0")/..}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
DATA_DIR="$PROJECT_DIR/data"
PROSPECTS_FILE="$DATA_DIR/prospects.csv"
SIGNALS_FILE="$DATA_DIR/prospect-signals.csv"
VALIDATION_REPORT="$PROJECT_DIR/outputs/validation-report-$(date +%Y-%m-%d).md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
VALID=0
INVALID=0
SUSPICIOUS=0

# Mode flags
FULL_MODE=false
UPDATE_CSV=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --full) FULL_MODE=true ;;
        --quick) FULL_MODE=false ;;
        --update) UPDATE_CSV=true ;;
    esac
done

echo "======================================"
echo "Contact Validation System"
echo "======================================"
echo "Mode: $([ "$FULL_MODE" = true ] && echo "Full (network checks)" || echo "Quick (offline)")"
echo ""

# Ensure output directory exists
mkdir -p "$(dirname "$VALIDATION_REPORT")"

# Start validation report
cat > "$VALIDATION_REPORT" << 'EOF'
# Contact Validation Report

Generated: $(date)

## Summary

EOF

# ============================================
# VALIDATION FUNCTIONS
# ============================================

# Validate email format
validate_email_format() {
    local email="$1"
    # Basic email regex
    if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    fi
    return 1
}

# Check for obviously fake email patterns
check_fake_email_patterns() {
    local email="$1"
    local name="$2"

    # Convert to lowercase for checking
    local email_lower=$(echo "$email" | tr '[:upper:]' '[:lower:]')
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Extract local part of email
    local local_part="${email_lower%@*}"

    # Check for common fake patterns
    # Pattern 1: firstname.lastname format matching the name exactly
    local first_name=$(echo "$name_lower" | awk '{print $1}')
    local last_name=$(echo "$name_lower" | awk '{print $NF}')

    # Pattern 2: Test/example addresses
    if [[ "$email_lower" == *"test@"* ]] || [[ "$email_lower" == *"example.com"* ]]; then
        echo "TEST_EMAIL"
        return 1
    fi

    # Pattern 3: Generic patterns that look auto-generated
    if [[ "$local_part" == "${first_name}.${last_name}" ]] || \
       [[ "$local_part" == "${first_name}${last_name}" ]] || \
       [[ "$local_part" == "${first_name:0:1}${last_name}" ]]; then
        echo "GUESSED_PATTERN"
        return 1
    fi

    echo "OK"
    return 0
}

# Check for obviously fake LinkedIn URL patterns
check_fake_linkedin_patterns() {
    local url="$1"
    local name="$2"

    # Convert to lowercase
    local url_lower=$(echo "$url" | tr '[:upper:]' '[:lower:]')
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Extract profile slug
    local slug="${url_lower##*/}"

    # Get name parts
    local first_name=$(echo "$name_lower" | awk '{print $1}')
    local last_name=$(echo "$name_lower" | awk '{print $NF}')

    # Check for auto-generated patterns
    # Pattern 1: firstname-title or lastname-title
    if [[ "$slug" == *"-digital"* ]] || \
       [[ "$slug" == *"-cto"* ]] || \
       [[ "$slug" == *"-cdo"* ]] || \
       [[ "$slug" == *"-cio"* ]] || \
       [[ "$slug" == *"-ops"* ]] || \
       [[ "$slug" == *"-tech"* ]] || \
       [[ "$slug" == *"-innovation"* ]] || \
       [[ "$slug" == *"-fintech"* ]] || \
       [[ "$slug" == *"-energy"* ]]; then
        echo "SUSPICIOUS_SUFFIX"
        return 1
    fi

    # Pattern 2: Simple firstname+lastname combination
    if [[ "$slug" == "${first_name}${last_name}" ]] || \
       [[ "$slug" == "${first_name}-${last_name}" ]] || \
       [[ "$slug" == "${first_name}${last_name}-"* ]]; then
        echo "GUESSED_PATTERN"
        return 1
    fi

    # Pattern 3: Generic test profiles
    if [[ "$slug" == "test" ]] || [[ "$slug" == "test-"* ]]; then
        echo "TEST_PROFILE"
        return 1
    fi

    echo "OK"
    return 0
}

# Check for placeholder URLs (fake job IDs, etc)
check_placeholder_url() {
    local url="$1"

    # Check for numeric placeholders like 12345, 67890, 123
    if [[ "$url" =~ /job/[0-9]{3,5}$ ]] && [[ "$url" =~ (12345|67890|123|111|999) ]]; then
        echo "PLACEHOLDER_ID"
        return 1
    fi

    # Check for incomplete URLs
    if [[ "$url" =~ afr\.com/article/[a-z-]+$ ]] && [[ ! "$url" =~ [0-9] ]]; then
        echo "INCOMPLETE_URL"
        return 1
    fi

    # Check for LinkedIn job placeholders
    if [[ "$url" =~ linkedin\.com/jobs/view/[0-9]+$ ]] && [[ "$url" =~ (123|456|789)$ ]]; then
        echo "PLACEHOLDER_ID"
        return 1
    fi

    echo "OK"
    return 0
}

# Network check: Verify LinkedIn profile exists (only in full mode)
verify_linkedin_exists() {
    local url="$1"

    if [ "$FULL_MODE" != true ]; then
        echo "SKIPPED"
        return 0
    fi

    # Use curl to check if the profile returns 200
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -L "$url" 2>/dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
        echo "EXISTS"
        return 0
    elif [ "$http_code" = "404" ]; then
        echo "NOT_FOUND"
        return 1
    else
        echo "UNKNOWN_$http_code"
        return 2
    fi
}

# Network check: Verify URL is reachable
verify_url_reachable() {
    local url="$1"

    if [ "$FULL_MODE" != true ]; then
        echo "SKIPPED"
        return 0
    fi

    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -L "$url" 2>/dev/null || echo "000")

    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        echo "REACHABLE"
        return 0
    elif [ "$http_code" = "404" ]; then
        echo "NOT_FOUND"
        return 1
    else
        echo "ERROR_$http_code"
        return 2
    fi
}

# ============================================
# VALIDATE PROSPECTS
# ============================================

echo "## Prospect Validation" >> "$VALIDATION_REPORT"
echo "" >> "$VALIDATION_REPORT"

echo -e "${YELLOW}Validating prospects...${NC}"
echo ""

# Skip header, process each line
HEADER=$(head -1 "$PROSPECTS_FILE")
tail -n +2 "$PROSPECTS_FILE" | while IFS=',' read -r company_name contact_name contact_title contact_email contact_linkedin industry employee_count location cloud_platform qualification_score score_breakdown buying_signals pain_points sequence_status sequence_stage last_touch_date next_touch_date notes; do
    ((TOTAL++)) || true

    ISSUES=""
    STATUS="VALID"

    # Validate email format
    if ! validate_email_format "$contact_email"; then
        ISSUES="${ISSUES}Invalid email format; "
        STATUS="INVALID"
    fi

    # Check for fake email patterns
    email_pattern_check=$(check_fake_email_patterns "$contact_email" "$contact_name")
    if [ "$email_pattern_check" != "OK" ]; then
        ISSUES="${ISSUES}Suspicious email pattern ($email_pattern_check); "
        if [ "$STATUS" != "INVALID" ]; then
            STATUS="SUSPICIOUS"
        fi
    fi

    # Check for fake LinkedIn patterns
    linkedin_pattern_check=$(check_fake_linkedin_patterns "$contact_linkedin" "$contact_name")
    if [ "$linkedin_pattern_check" != "OK" ]; then
        ISSUES="${ISSUES}Suspicious LinkedIn URL ($linkedin_pattern_check); "
        if [ "$STATUS" != "INVALID" ]; then
            STATUS="SUSPICIOUS"
        fi
    fi

    # Network validation (if full mode)
    if [ "$FULL_MODE" = true ]; then
        linkedin_exists=$(verify_linkedin_exists "$contact_linkedin")
        if [ "$linkedin_exists" = "NOT_FOUND" ]; then
            ISSUES="${ISSUES}LinkedIn profile not found; "
            STATUS="INVALID"
        fi
    fi

    # Output result
    case $STATUS in
        "VALID")
            echo -e "${GREEN}[VALID]${NC} $company_name - $contact_name"
            ((VALID++)) || true
            ;;
        "SUSPICIOUS")
            echo -e "${YELLOW}[SUSPICIOUS]${NC} $company_name - $contact_name: $ISSUES"
            echo "- **SUSPICIOUS**: $company_name - $contact_name ($contact_email)" >> "$VALIDATION_REPORT"
            echo "  - Issues: $ISSUES" >> "$VALIDATION_REPORT"
            ((SUSPICIOUS++)) || true
            ;;
        "INVALID")
            echo -e "${RED}[INVALID]${NC} $company_name - $contact_name: $ISSUES"
            echo "- **INVALID**: $company_name - $contact_name ($contact_email)" >> "$VALIDATION_REPORT"
            echo "  - Issues: $ISSUES" >> "$VALIDATION_REPORT"
            ((INVALID++)) || true
            ;;
    esac
done

# ============================================
# VALIDATE SIGNALS
# ============================================

echo ""
echo -e "${YELLOW}Validating signal URLs...${NC}"
echo ""

echo "" >> "$VALIDATION_REPORT"
echo "## Signal URL Validation" >> "$VALIDATION_REPORT"
echo "" >> "$VALIDATION_REPORT"

SIGNAL_TOTAL=0
SIGNAL_INVALID=0

tail -n +2 "$SIGNALS_FILE" 2>/dev/null | while IFS=',' read -r date source company_name signal_type signal_detail url status; do
    ((SIGNAL_TOTAL++)) || true

    # Check for placeholder URLs
    url_check=$(check_placeholder_url "$url")
    if [ "$url_check" != "OK" ]; then
        echo -e "${RED}[INVALID URL]${NC} $company_name: $url ($url_check)"
        echo "- **INVALID URL**: $url ($url_check)" >> "$VALIDATION_REPORT"
        ((SIGNAL_INVALID++)) || true
    else
        # Network check if in full mode
        if [ "$FULL_MODE" = true ]; then
            url_reachable=$(verify_url_reachable "$url")
            if [ "$url_reachable" = "NOT_FOUND" ]; then
                echo -e "${RED}[UNREACHABLE]${NC} $company_name: $url"
                echo "- **UNREACHABLE**: $url" >> "$VALIDATION_REPORT"
                ((SIGNAL_INVALID++)) || true
            else
                echo -e "${GREEN}[VALID]${NC} $company_name: $url"
            fi
        else
            echo -e "${GREEN}[FORMAT OK]${NC} $company_name: $url"
        fi
    fi
done

# ============================================
# SUMMARY
# ============================================

echo ""
echo "======================================"
echo "Validation Summary"
echo "======================================"
echo ""

# Note: Due to subshell, we need to recount
TOTAL=$(tail -n +2 "$PROSPECTS_FILE" | wc -l | tr -d ' ')
SIGNAL_TOTAL=$(tail -n +2 "$SIGNALS_FILE" 2>/dev/null | wc -l | tr -d ' ')

# Count issues from the report
ISSUES_COUNT=$(grep -c "INVALID\|SUSPICIOUS" "$VALIDATION_REPORT" 2>/dev/null || echo "0")

echo "Prospects checked: $TOTAL"
echo "Signal URLs checked: $SIGNAL_TOTAL"
echo "Issues found: $ISSUES_COUNT"
echo ""

if [ "$ISSUES_COUNT" -gt 0 ]; then
    echo -e "${RED}WARNING: Validation failed!${NC}"
    echo "Review the issues above before proceeding with outreach."
    echo ""
    echo "Full report saved to: $VALIDATION_REPORT"
    echo ""
    echo "Recommended actions:"
    echo "  1. Remove or update contacts marked as INVALID"
    echo "  2. Manually verify contacts marked as SUSPICIOUS"
    echo "  3. Replace placeholder URLs with real URLs"
    echo "  4. Re-run validation before outreach"
    exit 1
else
    echo -e "${GREEN}All contacts passed validation!${NC}"
    exit 0
fi
