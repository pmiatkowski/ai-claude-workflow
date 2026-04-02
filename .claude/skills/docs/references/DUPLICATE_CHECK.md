# Duplicate Detection Protocol

Before adding documentation, check for existing similar content.

## Detection (run all three)

1. **Title match**: Grep README.md and ./docs/*.md for topic keywords (case-insensitive).
   Threshold: any match with >70% title similarity.
2. **Content overlap**: Search existing docs for 3+ key terms from proposed content.
   Threshold: 3+ terms found in single file.
3. **Code symbol check**: Grep for function/class names referenced in proposed content.
   Threshold: 2+ symbols found in existing doc.

## On Match Found

Present to user:
- Existing file path and section
- Overlap details (which terms/symbols matched)
- Options: **Merge** into existing, **Create separate** with cross-reference, **Cancel**

## Not a Duplicate If

- Different audience (users vs developers)
- Different scope (overview vs deep-dive)
- Different format (tutorial vs API reference)
