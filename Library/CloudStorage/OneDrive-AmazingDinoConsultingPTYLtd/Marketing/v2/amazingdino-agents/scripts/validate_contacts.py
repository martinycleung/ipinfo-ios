#!/usr/bin/env python3
"""
Contact Validation System for Amazing Dino Lead Generation

This script validates contacts before allowing outreach:
- Checks email format and detects guessed/fake patterns
- Validates LinkedIn URLs and detects auto-generated patterns
- Verifies signal URLs are not placeholders
- Optionally performs network checks to verify URLs exist

Usage:
    python validate_contacts.py --quick          # Offline pattern checks only
    python validate_contacts.py --full           # Include network verification
    python validate_contacts.py --full --update  # Update CSV with validation status
    python validate_contacts.py --report         # Generate detailed report
"""

import csv
import re
import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import Tuple, List, Dict
import urllib.request
import urllib.error
import ssl

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
DATA_DIR = PROJECT_DIR / "data"
OUTPUT_DIR = PROJECT_DIR / "outputs"

PROSPECTS_FILE = DATA_DIR / "prospects.csv"
SIGNALS_FILE = DATA_DIR / "prospect-signals.csv"

# Validation results
class ValidationStatus:
    VALID = "valid"
    SUSPICIOUS = "suspicious"
    INVALID = "invalid"
    UNVERIFIED = "unverified"


def validate_email_format(email: str) -> bool:
    """Check if email has valid format."""
    # Check for explicit "needs verification" markers
    if not email or 'needs_verification' in email.lower() or email.lower() == 'needs_verification':
        return False

    pattern = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    return bool(re.match(pattern, email))


def detect_guessed_email(email: str, contact_name: str) -> Tuple[bool, str]:
    """
    Detect if email appears to be auto-generated/guessed based on name.
    Returns (is_suspicious, reason)
    """
    email_lower = email.lower()
    local_part = email_lower.split('@')[0]

    # Parse name
    name_parts = contact_name.lower().split()
    if len(name_parts) < 2:
        return False, "OK"

    first_name = name_parts[0]
    last_name = name_parts[-1]

    # Common guessed patterns
    guessed_patterns = [
        f"{first_name}.{last_name}",
        f"{first_name}{last_name}",
        f"{first_name[0]}{last_name}",
        f"{first_name}_{last_name}",
        f"{first_name[0]}.{last_name}",
        f"{last_name}.{first_name}",
        f"{first_name}{last_name[0]}",
    ]

    for pattern in guessed_patterns:
        if local_part == pattern:
            return True, f"GUESSED_PATTERN ({pattern})"

    # Check for test emails
    if 'test' in email_lower or 'example.com' in email_lower:
        return True, "TEST_EMAIL"

    return False, "OK"


def detect_guessed_linkedin(url: str, contact_name: str) -> Tuple[bool, str]:
    """
    Detect if LinkedIn URL appears to be auto-generated.
    Returns (is_suspicious, reason)
    """
    # Check for explicit "needs verification" markers
    if not url or 'needs_verification' in url.lower():
        return True, "MISSING_LINKEDIN"

    url_lower = url.lower()

    # Extract profile slug
    if '/in/' not in url_lower:
        return True, "INVALID_LINKEDIN_FORMAT"

    slug = url_lower.split('/in/')[-1].rstrip('/')

    # Parse name
    name_parts = contact_name.lower().split()
    if len(name_parts) < 2:
        return False, "OK"

    first_name = name_parts[0]
    last_name = name_parts[-1]

    # Suspicious suffixes that suggest auto-generation
    suspicious_suffixes = [
        '-digital', '-cto', '-cdo', '-cio', '-cfo', '-ceo',
        '-ops', '-tech', '-innovation', '-fintech', '-energy',
        '-transformation', '-head', '-director', '-vp', '-lead'
    ]

    for suffix in suspicious_suffixes:
        if slug.endswith(suffix):
            return True, f"SUSPICIOUS_SUFFIX ({suffix})"

    # Check for simple name combinations
    guessed_patterns = [
        f"{first_name}{last_name}",
        f"{first_name}-{last_name}",
        f"{first_name}_{last_name}",
        f"{last_name}{first_name}",
        f"{first_name[0]}{last_name}",
    ]

    for pattern in guessed_patterns:
        if slug.startswith(pattern):
            return True, f"GUESSED_PATTERN ({pattern})"

    # Check for test profiles
    if slug == 'test' or slug.startswith('test-'):
        return True, "TEST_PROFILE"

    return False, "OK"


def detect_placeholder_url(url: str) -> Tuple[bool, str]:
    """
    Detect if URL contains placeholder IDs.
    Returns (is_placeholder, reason)
    """
    url_lower = url.lower()

    # Check for explicit "needs verification" markers
    if 'needs_real_url' in url_lower or 'needs_verification' in url_lower or url_lower == '':
        return True, "MISSING_URL"

    # Common placeholder patterns
    placeholder_ids = ['12345', '67890', '123', '456', '789', '111', '999', '000']

    # Check job posting URLs
    job_match = re.search(r'/job/(\d+)', url_lower)
    if job_match:
        job_id = job_match.group(1)
        if job_id in placeholder_ids or len(job_id) <= 3:
            return True, f"PLACEHOLDER_JOB_ID ({job_id})"

    # Check LinkedIn job URLs
    linkedin_job_match = re.search(r'/jobs/view/(\d+)', url_lower)
    if linkedin_job_match:
        job_id = linkedin_job_match.group(1)
        if job_id in placeholder_ids or len(job_id) <= 3:
            return True, f"PLACEHOLDER_JOB_ID ({job_id})"

    # Check for incomplete article URLs (no ID or date)
    if 'afr.com/article/' in url_lower or 'itnews.com.au/' in url_lower:
        # Real URLs typically have dates or IDs
        if not re.search(r'\d{4,}', url_lower):
            return True, "INCOMPLETE_URL"

    return False, "OK"


def verify_url_exists(url: str, timeout: int = 5) -> Tuple[bool, str]:
    """
    Check if URL is reachable via HTTP.
    Returns (exists, status)
    """
    try:
        # Create SSL context that doesn't verify (for simplicity)
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (compatible; validation-bot)'}
        )

        with urllib.request.urlopen(req, timeout=timeout, context=ctx) as response:
            if response.status == 200:
                return True, "EXISTS"
            return False, f"HTTP_{response.status}"
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False, "NOT_FOUND"
        return False, f"HTTP_{e.code}"
    except urllib.error.URLError as e:
        return False, f"URL_ERROR"
    except Exception as e:
        return False, f"ERROR"


def validate_prospect(row: Dict, full_check: bool = False) -> Tuple[str, List[str]]:
    """
    Validate a single prospect record.
    Returns (status, list_of_issues)
    """
    issues = []
    status = ValidationStatus.VALID

    contact_name = row.get('contact_name', '')
    contact_email = row.get('contact_email', '')
    contact_linkedin = row.get('contact_linkedin', '')

    # Email validation
    if not validate_email_format(contact_email):
        issues.append("Invalid email format")
        status = ValidationStatus.INVALID
    else:
        is_guessed, reason = detect_guessed_email(contact_email, contact_name)
        if is_guessed:
            issues.append(f"Email appears guessed: {reason}")
            if status != ValidationStatus.INVALID:
                status = ValidationStatus.SUSPICIOUS

    # LinkedIn validation
    is_guessed, reason = detect_guessed_linkedin(contact_linkedin, contact_name)
    if is_guessed:
        issues.append(f"LinkedIn URL appears fake: {reason}")
        if status != ValidationStatus.INVALID:
            status = ValidationStatus.SUSPICIOUS

    # Network verification (if requested)
    if full_check and contact_linkedin:
        exists, url_status = verify_url_exists(contact_linkedin)
        if not exists and url_status == "NOT_FOUND":
            issues.append(f"LinkedIn profile not found (404)")
            status = ValidationStatus.INVALID
        elif not exists:
            issues.append(f"LinkedIn verification failed: {url_status}")

    return status, issues


def validate_signal(row: Dict, full_check: bool = False) -> Tuple[str, List[str]]:
    """
    Validate a signal record.
    Returns (status, list_of_issues)
    """
    issues = []
    status = ValidationStatus.VALID

    url = row.get('url', '')

    # Check for placeholder URLs
    is_placeholder, reason = detect_placeholder_url(url)
    if is_placeholder:
        issues.append(f"Placeholder URL detected: {reason}")
        status = ValidationStatus.INVALID

    # Network verification (if requested)
    if full_check and url and status != ValidationStatus.INVALID:
        exists, url_status = verify_url_exists(url)
        if not exists:
            issues.append(f"URL not reachable: {url_status}")
            status = ValidationStatus.INVALID

    return status, issues


def update_csv_with_validation(prospects_file: Path, results: List[Dict]):
    """Update prospects CSV with validation status."""
    # Read existing data
    with open(prospects_file, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    # Add validation columns if not present
    if 'validation_status' not in fieldnames:
        fieldnames = list(fieldnames) + ['validation_status', 'validation_issues', 'validated_date']

    # Update rows with validation results
    for row, result in zip(rows, results):
        row['validation_status'] = result['status']
        row['validation_issues'] = '; '.join(result['issues']) if result['issues'] else ''
        row['validated_date'] = datetime.now().strftime('%Y-%m-%d')

    # Write back
    with open(prospects_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def generate_report(prospect_results: List[Dict], signal_results: List[Dict], output_path: Path):
    """Generate a detailed validation report."""
    report = []
    report.append(f"# Contact Validation Report")
    report.append(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("")

    # Summary
    prospect_valid = sum(1 for r in prospect_results if r['status'] == ValidationStatus.VALID)
    prospect_suspicious = sum(1 for r in prospect_results if r['status'] == ValidationStatus.SUSPICIOUS)
    prospect_invalid = sum(1 for r in prospect_results if r['status'] == ValidationStatus.INVALID)

    signal_valid = sum(1 for r in signal_results if r['status'] == ValidationStatus.VALID)
    signal_invalid = sum(1 for r in signal_results if r['status'] == ValidationStatus.INVALID)

    report.append("## Summary")
    report.append("")
    report.append(f"### Prospects ({len(prospect_results)} total)")
    report.append(f"- Valid: {prospect_valid}")
    report.append(f"- Suspicious: {prospect_suspicious}")
    report.append(f"- Invalid: {prospect_invalid}")
    report.append("")
    report.append(f"### Signal URLs ({len(signal_results)} total)")
    report.append(f"- Valid: {signal_valid}")
    report.append(f"- Invalid: {signal_invalid}")
    report.append("")

    # Detailed issues
    if prospect_suspicious + prospect_invalid > 0:
        report.append("## Prospect Issues")
        report.append("")
        for r in prospect_results:
            if r['status'] != ValidationStatus.VALID:
                status_emoji = "!" if r['status'] == ValidationStatus.SUSPICIOUS else "X"
                report.append(f"### [{status_emoji}] {r['company_name']} - {r['contact_name']}")
                report.append(f"- Email: `{r['email']}`")
                report.append(f"- LinkedIn: `{r['linkedin']}`")
                report.append(f"- Status: **{r['status'].upper()}**")
                report.append("- Issues:")
                for issue in r['issues']:
                    report.append(f"  - {issue}")
                report.append("")

    if signal_invalid > 0:
        report.append("## Signal URL Issues")
        report.append("")
        for r in signal_results:
            if r['status'] != ValidationStatus.VALID:
                report.append(f"- **{r['company_name']}**: `{r['url']}`")
                for issue in r['issues']:
                    report.append(f"  - {issue}")

    # Recommendations
    report.append("")
    report.append("## Recommendations")
    report.append("")
    if prospect_invalid > 0:
        report.append("### Critical (Must Fix)")
        report.append("1. Remove or replace all INVALID contacts before outreach")
        report.append("2. Do NOT send emails to unverified addresses")
        report.append("")

    if prospect_suspicious > 0:
        report.append("### Warning (Should Verify)")
        report.append("1. Manually verify SUSPICIOUS contacts via LinkedIn")
        report.append("2. Use email verification service (e.g., Hunter.io, NeverBounce)")
        report.append("3. Check company websites for accurate contact information")
        report.append("")

    if signal_invalid > 0:
        report.append("### Signal URLs")
        report.append("1. Replace placeholder URLs with actual job posting/article URLs")
        report.append("2. Remove signals with invalid sources")
        report.append("")

    # Write report
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('\n'.join(report))

    return output_path


def main():
    parser = argparse.ArgumentParser(description='Validate contacts before outreach')
    parser.add_argument('--full', action='store_true', help='Include network verification')
    parser.add_argument('--quick', action='store_true', help='Quick pattern checks only (default)')
    parser.add_argument('--update', action='store_true', help='Update CSV with validation status')
    parser.add_argument('--report', action='store_true', help='Generate detailed report')
    parser.add_argument('--strict', action='store_true', help='Fail on any suspicious contacts')
    args = parser.parse_args()

    full_check = args.full and not args.quick

    print("=" * 50)
    print("Contact Validation System")
    print("=" * 50)
    print(f"Mode: {'Full (network checks)' if full_check else 'Quick (offline)'}")
    print()

    # Validate prospects
    print("Validating prospects...")
    prospect_results = []

    if not PROSPECTS_FILE.exists():
        print(f"ERROR: Prospects file not found: {PROSPECTS_FILE}")
        sys.exit(1)

    with open(PROSPECTS_FILE, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            status, issues = validate_prospect(row, full_check)
            result = {
                'company_name': row.get('company_name', 'Unknown'),
                'contact_name': row.get('contact_name', 'Unknown'),
                'email': row.get('contact_email', ''),
                'linkedin': row.get('contact_linkedin', ''),
                'status': status,
                'issues': issues
            }
            prospect_results.append(result)

            # Print result
            if status == ValidationStatus.VALID:
                print(f"  [VALID] {result['company_name']} - {result['contact_name']}")
            elif status == ValidationStatus.SUSPICIOUS:
                print(f"  [SUSPICIOUS] {result['company_name']} - {result['contact_name']}")
                for issue in issues:
                    print(f"      - {issue}")
            else:
                print(f"  [INVALID] {result['company_name']} - {result['contact_name']}")
                for issue in issues:
                    print(f"      - {issue}")

    print()

    # Validate signals
    print("Validating signal URLs...")
    signal_results = []

    if SIGNALS_FILE.exists():
        with open(SIGNALS_FILE, 'r', newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                status, issues = validate_signal(row, full_check)
                result = {
                    'company_name': row.get('company_name', 'Unknown'),
                    'url': row.get('url', ''),
                    'status': status,
                    'issues': issues
                }
                signal_results.append(result)

                if status == ValidationStatus.VALID:
                    print(f"  [VALID] {result['company_name']}: {result['url'][:50]}...")
                else:
                    print(f"  [INVALID] {result['company_name']}: {result['url']}")
                    for issue in issues:
                        print(f"      - {issue}")

    print()

    # Summary
    print("=" * 50)
    print("Validation Summary")
    print("=" * 50)

    prospect_valid = sum(1 for r in prospect_results if r['status'] == ValidationStatus.VALID)
    prospect_suspicious = sum(1 for r in prospect_results if r['status'] == ValidationStatus.SUSPICIOUS)
    prospect_invalid = sum(1 for r in prospect_results if r['status'] == ValidationStatus.INVALID)

    signal_valid = sum(1 for r in signal_results if r['status'] == ValidationStatus.VALID)
    signal_invalid = sum(1 for r in signal_results if r['status'] == ValidationStatus.INVALID)

    print(f"\nProspects: {len(prospect_results)} total")
    print(f"  - Valid:      {prospect_valid}")
    print(f"  - Suspicious: {prospect_suspicious}")
    print(f"  - Invalid:    {prospect_invalid}")

    print(f"\nSignal URLs: {len(signal_results)} total")
    print(f"  - Valid:   {signal_valid}")
    print(f"  - Invalid: {signal_invalid}")

    # Update CSV if requested
    if args.update:
        print("\nUpdating prospects CSV with validation status...")
        update_csv_with_validation(PROSPECTS_FILE, prospect_results)
        print(f"  Updated: {PROSPECTS_FILE}")

    # Generate report if requested
    if args.report or prospect_invalid + prospect_suspicious + signal_invalid > 0:
        report_path = OUTPUT_DIR / f"validation-report-{datetime.now().strftime('%Y-%m-%d')}.md"
        generate_report(prospect_results, signal_results, report_path)
        print(f"\nReport saved to: {report_path}")

    # Exit with appropriate code
    has_issues = prospect_invalid > 0 or signal_invalid > 0
    has_suspicious = prospect_suspicious > 0

    if has_issues:
        print("\n" + "!" * 50)
        print("VALIDATION FAILED: Invalid contacts detected!")
        print("Do NOT proceed with outreach until issues are fixed.")
        print("!" * 50)
        sys.exit(1)
    elif has_suspicious and args.strict:
        print("\n" + "!" * 50)
        print("VALIDATION FAILED (strict mode): Suspicious contacts detected!")
        print("Manually verify these contacts before outreach.")
        print("!" * 50)
        sys.exit(1)
    elif has_suspicious:
        print("\nWARNING: Suspicious contacts detected.")
        print("Consider verifying before outreach.")
        sys.exit(0)
    else:
        print("\nAll contacts passed validation!")
        sys.exit(0)


if __name__ == '__main__':
    main()
