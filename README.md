# Publisher Custom Apex

Custom Apex classes extending the CompSuite Content Publisher functionality with out-of-the-box (OOTB) enhancements.

## Overview

This project provides custom Apex implementations for the CompSuite Content Publisher package. The classes implement the `CompSuite.CP_DynamicContentGenerator` interface to generate customized HTML/JSON output for Protocol Executions.

## Project Structure

```
force-app/
└── main/
    └── default/
        └── classes/
            └── CP_Advanced_Custom_ProtocolOutput.cls    # Enhanced Protocol Output generator
```

## Classes

### CP_Advanced_Custom_ProtocolOutput

A custom Protocol Output generator with enhanced features:

- **Width-based layout handling** - Implements bin packing algorithm for responsive element layouts
- **Multiple Protocol Element types** - Supports Table, Test Step, Text Only, Multi Picklist, Single Picklist, Radio Buttons, Free Text, Numeric Value, and more
- **Training Effectiveness support** - Special handling for exam scoring and pass/fail results
- **Findings section** - Renders observation/findings data from audits
- **Signature support** - Handles approval signatures with timestamps
- **Long word splitting** - Automatically handles text overflow in narrow columns

## Prerequisites

- Salesforce org with CompSuite package installed
- CompSuite Content Publisher license

## Deployment

Deploy using Salesforce CLI:

```bash
sf project deploy start --source-dir force-app
```

Or deploy to a specific org:

```bash
sf project deploy start --source-dir force-app --target-org <org-alias>
```

## Usage

The class implements `CompSuite.CP_DynamicContentGenerator` and can be configured in Content Publisher templates to generate custom Protocol Execution output.

## License

Proprietary - Internal use only
