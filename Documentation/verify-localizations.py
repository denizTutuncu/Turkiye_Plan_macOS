#!/usr/bin/env python3
"""Check source catalog coverage without requiring Xcode. Run XCTest for compiled bundles."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
app = root / 'TurkiyePlan'
catalog = json.loads((app / 'Resources/Localizable.xcstrings').read_text())['strings']
languages = {'en', 'tr', 'es', 'it', 'zh-Hans', 'hi', 'ar', 'fr', 'bn', 'pt', 'ru', 'ur'}
for key, entry in catalog.items():
    assert entry.get('generatesSymbol') is False, ('Disable unused Swift symbol generation', key)
    assert set(entry['localizations']) == languages, key
    reference = sorted(re.findall(r'\{\d+\}', entry['localizations']['en']['stringUnit']['value']))
    for language, translation in entry['localizations'].items():
        value = translation['stringUnit']['value']
        assert value, (key, language)
        assert sorted(re.findall(r'\{\d+\}', value)) == reference, (key, language)
for path in app.rglob('*.swift'):
    for match in re.finditer(r'L10n\.(?:text|format)\("((?:[^"\\]|\\.)*)"', path.read_text()):
        assert match[1] in catalog, (str(path), match[1])
    for match in re.finditer(r'"(review\.[A-Za-z]+)"', path.read_text()):
        assert match[1] in catalog, (str(path), match[1])
for filename in ('services.json', 'indicators.json'):
    for item in json.loads((app / 'Resources' / filename).read_text()):
        for field in ('name', 'unit'):
            value = item[field]
            assert value in catalog or value == 'km²', (filename, value)
navigation = (app / 'Navigation/TabRouter.swift').read_text().split(' var symbol:')[0]
assert len(re.findall(r'case \.\w+: L10n\.text\(', navigation)) == 5, 'All tab titles must use localization'
editor = (app / 'UI/PovertyProfileEditor.swift').read_text()
for status in ('observed', 'estimated', 'missing'):
    assert '.tag("' + status + '")' in editor
    assert '.tag(L10n.text("' + status + '"))' not in editor
print(f'PASS: {len(catalog)} catalog entries × {len(languages)} languages; placeholders, lookups and data labels complete.')
