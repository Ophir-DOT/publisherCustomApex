# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/claude-code) when working with code in this repository.

## Project Purpose

This repository contains custom Apex classes that extend the CompSuite Content Publisher OOTB (out-of-the-box) functionality. The goal is to support new Apex implementations for the Publisher that generate customized output formats.

## Architecture

### Core Interface

All custom content generators must implement `CompSuite.CP_DynamicContentGenerator`:

```apex
global with sharing class MyCustomOutput implements CompSuite.CP_DynamicContentGenerator {
    public string getJSON(Id recordId, string input) { ... }
    public string getHTML(Id recordId, string input) { ... }
}
```

### Key Objects

- **CompSuite__Protocol_Execution__c** - Main execution record containing exam/protocol data
- **CompSuite__Execution_Element__c** - Individual elements/questions within an execution
- **CompSuite__Protocol_Element__c** - Template elements defining the structure
- **CompSuite__Observation__c** - Findings/observations linked to audits

### Protocol Element Record Types

When adding new functionality, be aware of these element types:
- `Multi Picklist` - Multiple selection options
- `Single Picklist` - Single selection dropdown
- `Radio Button Vertical` / `Radio Button Horizontal` - Radio button layouts
- `Free Text` - Open text input
- `Numeric Value` - Number input
- `Table` - Tabular data with child elements
- `Test Step` - Expected/Actual result comparison
- `Text Only` - Display-only content
- `Training Effectiveness` - Exam/scoring type

## Development Commands

```bash
# Deploy to org
sf project deploy start --source-dir force-app

# Deploy to specific org
sf project deploy start --source-dir force-app --target-org <alias>

# Retrieve from org
sf project retrieve start --source-dir force-app --target-org <alias>

# Run Apex tests
sf apex run test --code-coverage --result-format human
```

## Code Conventions

- Classes are `global with sharing` to respect sharing rules
- Use `WITH SECURITY_ENFORCED` in SOQL queries for FLS enforcement
- Constants use `private static final String` pattern
- Wrapper classes are nested within the main class
- HTML output uses inline styles for PDF compatibility (no external CSS)

## Adding New Custom Outputs

1. Create a new class implementing `CompSuite.CP_DynamicContentGenerator`
2. Query the Protocol Execution and related Execution Elements
3. Process each element based on its RecordType
4. Generate HTML/JSON output
5. Deploy and configure in Content Publisher template
