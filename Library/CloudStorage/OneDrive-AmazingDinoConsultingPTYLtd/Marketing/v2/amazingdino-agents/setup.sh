#!/bin/bash
# Amazing Dino Lead Generation - First Time Setup
# Run this once after extracting the package

set -e

echo "======================================"
echo "Amazing Dino Lead Gen - Setup"
echo "======================================"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Setting up in: $SCRIPT_DIR"

# Create all required directories
echo "Creating directories..."
mkdir -p data
mkdir -p outputs/daily
mkdir -p outputs/weekly
mkdir -p outputs/briefings
mkdir -p outputs/proposals
mkdir -p outputs/meetings
mkdir -p outputs/content
mkdir -p outputs/reports
mkdir -p templates/email-templates
mkdir -p templates/case-studies
mkdir -p logs

# Initialize data files if they don't exist
echo "Initializing data files..."

if [ ! -f "data/prospects.csv" ]; then
    echo "company_name,contact_name,contact_title,contact_email,contact_linkedin,industry,employee_count,location,cloud_platform,qualification_score,score_breakdown,buying_signals,pain_points,sequence_status,sequence_stage,last_touch_date,next_touch_date,notes" > data/prospects.csv
    echo "Created: data/prospects.csv"
fi

if [ ! -f "data/outreach-tracking.csv" ]; then
    echo "date,company_name,contact_name,channel,touch_type,sequence_stage,message_sent,response_status,response_date,response_notes,next_action" > data/outreach-tracking.csv
    echo "Created: data/outreach-tracking.csv"
fi

if [ ! -f "data/meetings.csv" ]; then
    echo "meeting_date,meeting_time,company_name,contact_name,contact_title,meeting_type,status,briefing_prepared,meeting_notes,outcome,next_steps,proposal_needed" > data/meetings.csv
    echo "Created: data/meetings.csv"
fi

if [ ! -f "data/prospect-signals.csv" ]; then
    echo "date,source,company_name,signal_type,signal_detail,url,status" > data/prospect-signals.csv
    echo "Created: data/prospect-signals.csv"
fi

if [ ! -f "data/responses-today.csv" ]; then
    echo "date,company_name,contact_name,response_type,response_content" > data/responses-today.csv
    echo "Created: data/responses-today.csv"
fi

# Make workflow scripts executable
echo "Making scripts executable..."
chmod +x workflows/*.sh 2>/dev/null || true

# Verify Claude Code is available
echo "Checking for Claude Code..."
if command -v claude &> /dev/null; then
    echo "✓ Claude Code found"
else
    echo "⚠ Claude Code not found in PATH"
    echo "  Install from: https://claude.ai/code"
    echo "  Or ensure 'claude' command is in your PATH"
fi

# Create a simple test
echo "Creating test prospect..."
echo "Test Company,Test Contact,CEO,test@example.com,https://linkedin.com/in/test,technology,100,Melbourne,AWS,3.5,\"size:4 budget:3 pain:4 access:3 compliance:4\",\"hiring AI roles\",\"manual processes\",new,day_0,$(date +%Y-%m-%d),$(date +%Y-%m-%d),Setup test entry" >> data/prospects.csv

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Test daily workflow:"
echo "   ./workflows/daily-workflow.sh"
echo ""
echo "2. Test weekly workflow:"
echo "   ./workflows/weekly-workflow.sh"
echo ""
echo "3. Test meeting prep:"
echo "   ./workflows/meeting-workflow.sh prep 'Test Company' 'Test Contact'"
echo ""
echo "4. Or use Claude Code directly:"
echo "   claude -p 'Read CLAUDE.md and show me the system overview'"
echo ""
echo "5. Set up automation (optional):"
echo "   crontab -e"
echo "   Add: 0 8 * * * cd $SCRIPT_DIR && ./workflows/daily-workflow.sh"
echo ""
echo "Documentation:"
echo "  - CLAUDE.md - System overview and commands"
echo "  - workflows/00-master-workflow.md - Detailed workflow specs"
echo "  - agents/*.md - Individual agent prompts"
echo ""
