#!/usr/bin/env python3
"""Convert SQLFluff JSON output to SonarQube Generic Issue format (v2)."""
import json
import sys

SKIP_RULES = {'PRS', 'CP01'}
SKIP_PATHS = {'sources/definitions/', '/out/', '/.scannerwork/'}

IMPACT_MAP = {
    'LT01': 'LOW', 'LT02': 'LOW', 'LT06': 'LOW',
    'LT08': 'LOW', 'LT09': 'LOW', 'LT10': 'LOW',
    'LT12': 'LOW', 'LT14': 'LOW',
    'CP02': 'LOW', 'CP04': 'LOW',
    'AL01': 'LOW', 'AL02': 'LOW', 'AL08': 'LOW',
    'AM01': 'LOW', 'AM03': 'LOW', 'AM04': 'MEDIUM',
    'AM05': 'MEDIUM', 'AM09': 'LOW',
    'RF02': 'LOW', 'RF03': 'LOW', 'RF04': 'MEDIUM',
    'ST06': 'LOW', 'ST07': 'LOW', 'ST09': 'LOW',
    'CV06': 'LOW',
}

RULE_DESCRIPTIONS = {}

with open(sys.argv[1]) as f:
    data = json.load(f)

issues = []
rules_seen = {}
for file_result in data:
    filepath = file_result.get('filepath', '')
    if any(s in filepath for s in SKIP_PATHS):
        continue
    for v in file_result.get('violations', []):
        code = v.get('code', '')
        if code in SKIP_RULES:
            continue
        desc = v.get('description', '')
        if code not in rules_seen:
            rules_seen[code] = desc
        issues.append({
            'ruleId': code,
            'primaryLocation': {
                'message': desc,
                'filePath': filepath,
                'textRange': {'startLine': v.get('start_line_no', 1)}
            }
        })

rules = []
for code in sorted(rules_seen.keys()):
    severity = IMPACT_MAP.get(code, 'LOW')
    rules.append({
        'id': code,
        'name': code,
        'description': rules_seen[code] or f'SQLFluff rule {code}',
        'engineId': 'sqlfluff',
        'cleanCodeAttribute': 'FORMATTED',
        'impacts': [{'softwareQuality': 'MAINTAINABILITY', 'severity': severity}]
    })

with open(sys.argv[2], 'w') as f:
    json.dump({'rules': rules, 'issues': issues}, f, indent=2)

print(f'SQLFluff: {len(issues)} issues written to {sys.argv[2]}')
