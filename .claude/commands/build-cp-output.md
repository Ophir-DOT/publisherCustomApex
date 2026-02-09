# Build Content Publisher Custom HTML Output

You are an expert Salesforce Apex developer specializing in CompSuite Content Publisher custom output generators. Your task is to help build a new Apex class that generates HTML output for the Content Publisher.

## Your Mission

Guide the user through building a custom `CompSuite.CP_DynamicContentGenerator` implementation that produces formatted HTML output. Use the AskUserQuestion tool to gather all necessary requirements before writing any code.

---

## CRITICAL RULE: No Queries in Loops

**NEVER write SOQL queries inside for loops.** This is a Salesforce governor limit anti-pattern that will cause failures.

### Wrong Approach (DO NOT DO THIS):
```apex
// BAD - Query inside loop will hit governor limits!
for (CompSuite__Observation__c finding : findings) {
    List<CompSuite__Deviation__c> ncRecords = [
        SELECT Id, Name FROM CompSuite__Deviation__c
        WHERE Finding__c = :finding.Id
    ];
    // Process ncRecords...
}
```

### Correct Approach (ALWAYS DO THIS):
```apex
// GOOD - Bulk query BEFORE the loop
// Step 1: Collect all IDs first
Set<Id> findingIds = new Map<Id, CompSuite__Observation__c>(findings).keySet();

// Step 2: Query ALL related records in ONE query
Map<Id, CompSuite__Deviation__c> ncMap = new Map<Id, CompSuite__Deviation__c>([
    SELECT Id, Name, Finding__c
    FROM CompSuite__Deviation__c
    WHERE Finding__c IN :findingIds
    WITH SECURITY_ENFORCED
]);

// Step 3: Build a lookup map for efficient access
Map<Id, List<CompSuite__Deviation__c>> findingToNCMap = new Map<Id, List<CompSuite__Deviation__c>>();
for (CompSuite__Deviation__c nc : ncMap.values()) {
    if (!findingToNCMap.containsKey(nc.Finding__c)) {
        findingToNCMap.put(nc.Finding__c, new List<CompSuite__Deviation__c>());
    }
    findingToNCMap.get(nc.Finding__c).add(nc);
}

// Step 4: NOW iterate and use the pre-built map
for (CompSuite__Observation__c finding : findings) {
    List<CompSuite__Deviation__c> ncRecords = findingToNCMap.get(finding.Id);
    // Process ncRecords...
}
```

### The Pattern: Query Everything First, Then Process
1. **Query primary records** (e.g., Findings)
2. **Collect all IDs** from primary records
3. **Bulk query ALL related records** using `WHERE Id IN :idSet`
4. **Build lookup Maps** for efficient access
5. **THEN iterate** and build wrappers/HTML using the maps

---

## Step 1: Gather Requirements

Use the AskUserQuestion tool to understand what the user needs. Ask these questions in sequence (not all at once):

### Question Set 1: Data Source
Ask the user:
- **What is the primary Salesforce object** you want to display? (e.g., Protocol Execution, Audit, Finding/Observation, Custom Object)
- **What record ID will be passed** to this output? (Usually Audit ID or Protocol Execution ID)

### Question Set 2: Related Records
Based on the primary object, ask:
- **Do you need to display related records?** If yes, which relationships?
  - Parent-to-child via direct lookup (e.g., Audit → Findings)
  - **Junction object relationships via `CompSuite__Relation4__c`** (see detailed section below)
  - Standard lookups
- **Should related records be nested/indented** under their parent?

> **Important:** If the user mentions relationships that don't have direct lookups (e.g., Finding to NC, Finding to CAPA Plan), these likely use the `CompSuite__Relation4__c` junction object. See the dedicated section below for handling this pattern.

### Question Set 3: Fields to Display
For each object involved, ask:
- **Which fields should be displayed?** List specific field API names.
- **What labels should be used** for each field?
- **Are there any calculated/derived fields** needed?

### Question Set 4: Formatting Requirements
Ask about:
- **Date/DateTime format** preferences (default: `MMM dd, yyyy`)
- **Section headers** - what text and styling?
- **Layout structure** - single column, tables, nested sections?
- **Any special formatting** for specific field types?

### Question Set 5: Styling
Ask about:
- **Color scheme** for headers (default: #333333 background, white text)
- **Font family** (default: 'TT Norms Pro', Aptos, Arial, Helvetica, sans-serif)
- **Font size** (default: 10pt)
- **Border styling** (default: 1px solid black)

## Step 2: Architecture Pattern

Once requirements are gathered, follow this proven architecture pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                    CLASS STRUCTURE                           │
├─────────────────────────────────────────────────────────────┤
│  1. CONSTANTS (styling, record types)                        │
│  2. WRAPPER CLASSES (for complex data relationships)         │
│  3. INTERFACE IMPLEMENTATION (getJSON, getHTML)              │
│  4. MAIN PROCESSING METHOD (getFormattedData)                │
│  5. QUERY METHODS (one per object type)                      │
│  6. WRAPPER BUILDING METHODS                                 │
│  7. HTML GENERATION METHODS (one per section type)           │
│  8. UTILITY METHODS (safeString, formatAnswer, etc.)         │
└─────────────────────────────────────────────────────────────┘
```

## Step 3: Code Template

Use this template structure when building the class:

```apex
/**
 * @description       : [DESCRIPTION FROM USER]
 * @author            : [AUTHOR]
 * @last modified on  : [DATE]
 * @last modified by  : Claude
 **/
global with sharing class [CLASS_NAME] implements CompSuite.CP_DynamicContentGenerator {

    // ============================================
    // SECTION 1: Constants for HTML styling
    // ============================================
    private static final String FONT_FAMILY = '\'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif';
    private static final String FONT_SIZE = '10pt';
    private static final String SECTION_HEADER_STYLE = 'background-color:#333333; color:white; font-weight:bold; padding:6px 10px;';
    private static final String SUBSECTION_HEADER_STYLE = 'background-color:#333333; color:white; font-weight:bold; padding:4px 10px; font-size:9pt;';

    // ============================================
    // SECTION 2: Wrapper Classes
    // ============================================

    /**
     * @description Wrapper for [PRIMARY_OBJECT] with related records
     */
    public class [Primary]Wrapper {
        public [SObject_Type] record { get; set; }
        public List<[Related_Type]> relatedRecords { get; set; }

        public [Primary]Wrapper() {
            this.relatedRecords = new List<[Related_Type]>();
        }

        public Boolean hasRelatedRecords() {
            return !relatedRecords.isEmpty();
        }
    }

    // ============================================
    // SECTION 3: Interface Implementation
    // ============================================

    public String getJSON(Id recordId, String input) {
        return null; // Return null if JSON not needed
    }

    public String getHTML(Id recordId, String input) {
        return getFormattedData(recordId, input);
    }

    // ============================================
    // SECTION 4: Main Processing Method
    // ============================================
    // CRITICAL: ALL queries happen here BEFORE any loops that build HTML!
    // This method orchestrates the "Query Everything First" pattern.

    public String getFormattedData(String recordId, String widthInput) {
        String strHTMLData = '';

        // ┌─────────────────────────────────────────────────────────────┐
        // │ PHASE 1: QUERY ALL DATA (No loops with queries!)            │
        // └─────────────────────────────────────────────────────────────┘

        // Query 1: Get primary records
        List<[PrimaryObject]> primaryRecords = queryPrimaryRecords(recordId);

        if (primaryRecords.isEmpty()) {
            return strHTMLData;
        }

        // Collect primary IDs for subsequent queries
        Set<Id> primaryIds = new Map<Id, [PrimaryObject]>(primaryRecords).keySet();

        // Query 2: If using Relation4 junction, query relations and build maps
        Map<Id, Set<Id>> primaryToRelated1Ids = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> primaryToRelated2Ids = new Map<Id, Set<Id>>();
        Set<Id> allRelated1Ids = new Set<Id>();
        Set<Id> allRelated2Ids = new Set<Id>();

        queryRelations(primaryIds, primaryToRelated1Ids, primaryToRelated2Ids,
                       allRelated1Ids, allRelated2Ids);

        // Query 3: Bulk query related object type 1
        Map<Id, [Related1Object]> related1Map = queryRelated1Records(allRelated1Ids);

        // Query 4: Bulk query related object type 2
        Map<Id, [Related2Object]> related2Map = queryRelated2Records(allRelated2Ids);

        // Query 5: If there are child records of related records, query those too
        Map<Id, List<[ChildObject]>> relatedToChildMap = queryChildRecords(allRelated1Ids);

        // ┌─────────────────────────────────────────────────────────────┐
        // │ PHASE 2: BUILD DATA STRUCTURES (Using maps, no queries!)    │
        // └─────────────────────────────────────────────────────────────┘

        List<[Primary]Wrapper> wrappers = buildWrappers(
            primaryRecords,
            primaryToRelated1Ids,
            primaryToRelated2Ids,
            related1Map,
            related2Map,
            relatedToChildMap
        );

        // ┌─────────────────────────────────────────────────────────────┐
        // │ PHASE 3: GENERATE HTML (Pure string manipulation)           │
        // └─────────────────────────────────────────────────────────────┘

        strHTMLData = generateHTML(wrappers);

        System.debug('[CLASS_NAME] strHTMLData==>' + strHTMLData);
        return strHTMLData;
    }

    // ============================================
    // SECTION 5: Query Methods
    // ============================================
    // Each method queries ONE object type. Called from getFormattedData().
    // NEVER call these methods inside a for loop!

    private List<[PrimaryObject]> queryPrimaryRecords(String recordId) {
        return [
            SELECT Id, Name, [FIELDS]
            FROM [PrimaryObject]
            WHERE [ParentField] = :recordId
            WITH SECURITY_ENFORCED
            ORDER BY [OrderField] ASC
        ];
    }

    /**
     * Query Relation4 junction records and populate mapping structures.
     * This method modifies the maps passed by reference.
     */
    private void queryRelations(
        Set<Id> sourceIds,
        Map<Id, Set<Id>> sourceToType1Ids,
        Map<Id, Set<Id>> sourceToType2Ids,
        Set<Id> allType1Ids,
        Set<Id> allType2Ids
    ) {
        // Convert to strings (Relation4 stores IDs as text!)
        Set<String> sourceIdStrings = new Set<String>();
        for (Id sourceId : sourceIds) {
            sourceIdStrings.add(String.valueOf(sourceId));
        }

        List<CompSuite__Relation4__c> relations = [
            SELECT Id, CompSuite__Source_Record_ID__c,
                   CompSuite__Destination_Record_ID__c,
                   CompSuite__Destination_Object_API_Name__c
            FROM CompSuite__Relation4__c
            WHERE CompSuite__Source_Record_ID__c IN :sourceIdStrings
            WITH SECURITY_ENFORCED
        ];

        for (CompSuite__Relation4__c rel : relations) {
            if (String.isBlank(rel.CompSuite__Source_Record_ID__c) ||
                String.isBlank(rel.CompSuite__Destination_Record_ID__c)) {
                continue;
            }

            Id sourceId;
            Id destId;
            try {
                sourceId = Id.valueOf(rel.CompSuite__Source_Record_ID__c);
                destId = Id.valueOf(rel.CompSuite__Destination_Record_ID__c);
            } catch (Exception e) {
                continue;
            }

            if (rel.CompSuite__Destination_Object_API_Name__c == '[Type1Object__c]') {
                addToSetMap(sourceToType1Ids, sourceId, destId);
                allType1Ids.add(destId);
            } else if (rel.CompSuite__Destination_Object_API_Name__c == '[Type2Object__c]') {
                addToSetMap(sourceToType2Ids, sourceId, destId);
                allType2Ids.add(destId);
            }
        }
    }

    /**
     * Query related records by ID set. Always check for empty set first!
     */
    private Map<Id, [RelatedObject]> queryRelatedRecords(Set<Id> recordIds) {
        if (recordIds.isEmpty()) {
            return new Map<Id, [RelatedObject]>();
        }

        return new Map<Id, [RelatedObject]>([
            SELECT Id, Name, [FIELDS], [LookupField__r.Name]
            FROM [RelatedObject]
            WHERE Id IN :recordIds
            WITH SECURITY_ENFORCED
        ]);
    }

    /**
     * Query child records and build a map keyed by parent ID.
     */
    private Map<Id, List<[ChildObject]>> queryChildRecords(Set<Id> parentIds) {
        Map<Id, List<[ChildObject]>> parentToChildMap = new Map<Id, List<[ChildObject]>>();

        if (parentIds.isEmpty()) {
            return parentToChildMap;
        }

        List<[ChildObject]> childRecords = [
            SELECT Id, Name, [ParentLookup__c], [FIELDS]
            FROM [ChildObject]
            WHERE [ParentLookup__c] IN :parentIds
            WITH SECURITY_ENFORCED
        ];

        // Build the map (this loop has NO queries - just organizing data)
        for ([ChildObject] child : childRecords) {
            if (!parentToChildMap.containsKey(child.[ParentLookup__c])) {
                parentToChildMap.put(child.[ParentLookup__c], new List<[ChildObject]>());
            }
            parentToChildMap.get(child.[ParentLookup__c]).add(child);
        }

        return parentToChildMap;
    }

    // ============================================
    // SECTION 6: Wrapper Building Methods
    // ============================================
    // These methods iterate through records but NEVER query the database!
    // All data comes from the pre-populated maps passed as parameters.

    private List<[Primary]Wrapper> buildWrappers(
        List<[PrimaryObject]> primaryRecords,
        Map<Id, Set<Id>> primaryToRelated1Ids,
        Map<Id, Set<Id>> primaryToRelated2Ids,
        Map<Id, [Related1Object]> related1Map,
        Map<Id, [Related2Object]> related2Map,
        Map<Id, List<[ChildObject]>> relatedToChildMap
    ) {
        List<[Primary]Wrapper> wrappers = new List<[Primary]Wrapper>();

        for ([PrimaryObject] record : primaryRecords) {
            [Primary]Wrapper wrapper = new [Primary]Wrapper();
            wrapper.record = record;

            // Add Related1 records using pre-built maps (NO QUERIES HERE!)
            if (primaryToRelated1Ids.containsKey(record.Id)) {
                for (Id related1Id : primaryToRelated1Ids.get(record.Id)) {
                    if (related1Map.containsKey(related1Id)) {
                        [Related1]Wrapper rel1Wrapper = new [Related1]Wrapper(related1Map.get(related1Id));

                        // Add child records if they exist
                        if (relatedToChildMap.containsKey(related1Id)) {
                            rel1Wrapper.childRecords = relatedToChildMap.get(related1Id);
                        }

                        wrapper.related1Records.add(rel1Wrapper);
                    }
                }
            }

            // Add Related2 records using pre-built maps
            if (primaryToRelated2Ids.containsKey(record.Id)) {
                for (Id related2Id : primaryToRelated2Ids.get(record.Id)) {
                    if (related2Map.containsKey(related2Id)) {
                        wrapper.related2Records.add(related2Map.get(related2Id));
                    }
                }
            }

            wrappers.add(wrapper);
        }

        return wrappers;
    }

    // ============================================
    // SECTION 7: HTML Generation Methods
    // ============================================

    private String generateHTML(List<[Primary]Wrapper> wrappers) {
        String html = '';
        html += '<div style="font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + '; width:100%;">';

        for ([Primary]Wrapper wrapper : wrappers) {
            html += buildPrimaryHTML(wrapper);

            if (!wrapper.relatedRecords.isEmpty()) {
                html += buildRelatedSection(wrapper.relatedRecords);
            }

            // Add spacing between records
            html += '<div style="margin-bottom:20px;"></div>';
        }

        html += '</div>';
        return html;
    }

    private String buildPrimaryHTML([Primary]Wrapper wrapper) {
        String html = '';

        // Section header
        html += '<div style="width:100%;display:table;table-layout:fixed;">';
        html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
        html += '<div style="' + SECTION_HEADER_STYLE + '">[SECTION_TITLE]</div>';
        html += '</div>';
        html += '</div>';

        // Content
        html += '<div style="width:100%;display:table;table-layout:fixed;">';
        html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
        html += '<div style="padding:10px 6px 6px 10px;">';

        // Add fields
        html += '<p style="margin:2px 0;"><b>[LABEL]: </b>' + safeString(wrapper.record.[Field]) + '</p>';
        // ... more fields ...

        html += '</div>';
        html += '</div>';
        html += '</div>';

        return html;
    }

    private String buildRelatedSection(List<[RelatedObject]> records) {
        String html = '';

        // Spacing before section
        html += '<br/>';

        // Table-based indentation for nested sections
        html += '<table style="width:100%; border-collapse:collapse; font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + ';">';
        html += '<tr>';
        html += '<td style="width:30px;"></td>'; // Indent spacer
        html += '<td style="font-size: ' + FONT_SIZE + ';">';

        // Subsection header
        html += '<div style="width:100%;display:table;table-layout:fixed;">';
        html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
        html += '<div style="' + SUBSECTION_HEADER_STYLE + '">[SUBSECTION_TITLE]</div>';
        html += '</div>';
        html += '</div>';

        // Content for each record
        for ([RelatedObject] record : records) {
            html += '<div style="width:100%;display:table;table-layout:fixed;">';
            html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
            html += '<div style="padding:10px 6px 6px 10px; font-size: ' + FONT_SIZE + ';">';

            // Add fields
            html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>[LABEL]: </b>' + safeString(record.[Field]) + '</p>';
            // ... more fields ...

            html += '</div>';
            html += '</div>';
            html += '</div>';
        }

        html += '</td>';
        html += '</tr>';
        html += '</table>';

        return html;
    }

    // ============================================
    // SECTION 8: Utility Methods
    // ============================================

    private void addToSetMap(Map<Id, Set<Id>> mapToUpdate, Id key, Id value) {
        if (!mapToUpdate.containsKey(key)) {
            mapToUpdate.put(key, new Set<Id>());
        }
        mapToUpdate.get(key).add(value);
    }

    private String safeString(String value) {
        return String.isBlank(value) ? '' : value.escapeHtml4();
    }

    public String formatAnswer(String pContentType, String pStringAnswer, Date pDateAnswer, Datetime pDateTimeAnswer, Boolean pConvertoAspose) {
        String retAnswer = '';
        if (pContentType.toUpperCase().trim() == 'DATETIME') {
            if (pDateTimeAnswer != null) {
                if (pConvertoAspose) {
                    Integer timeZone = 0;
                    try {
                        timeZone = Integer.valueOf(CompSuite__Aspose_Utils__c.getValues('PdfTimeZone').CompSuite__value__c);
                    } catch (Exception exp) {
                        timeZone = 0;
                    }
                    pDateTimeAnswer = pDateTimeAnswer.addHours(timeZone);
                }
                retAnswer = pDateTimeAnswer.format('MMM dd, yyyy, hh:mm a', UserInfo.getTimeZone().toString());
            }
        } else if (pContentType.toUpperCase().trim() == 'DATE') {
            if (pDateAnswer != null) {
                DateTime dt = DateTime.newInstance(pDateAnswer.year(), pDateAnswer.month(), pDateAnswer.day());
                retAnswer = dt.format('MMM dd, yyyy', UserInfo.getTimeZone().toString());
            }
        } else {
            retAnswer = pStringAnswer == null ? '' : pStringAnswer.replace('\n', '<br/>');
        }
        return retAnswer;
    }
}
```

## Step 4: Key Implementation Rules

### SOQL Best Practices
1. **Always use `WITH SECURITY_ENFORCED`** for FLS enforcement
2. **Bulk query** - collect all IDs first, then query related records in single queries
3. **Order queries** to maintain consistent output order
4. **Handle empty results** gracefully

### HTML/PDF Compatibility
1. **Use inline styles only** - no external CSS (PDFs don't support it)
2. **Use `display:table` and `display:table-cell`** for layouts (better PDF support than flexbox)
3. **Use `page-break-inside:avoid`** for sections that should stay together
4. **Use `<table>` with `border-collapse:collapse`** for actual tabular data
5. **Use `<br/>` for spacing** (self-closing for XHTML compatibility)

### Indentation Pattern for Nested Records
Use the table-based indentation pattern:
```apex
html += '<table style="width:100%; border-collapse:collapse;">';
html += '<tr>';
html += '<td style="width:30px;"></td>'; // Empty spacer column
html += '<td>'; // Content column
// ... nested content here ...
html += '</td>';
html += '</tr>';
html += '</table>';
```

### Null Safety
1. **Always check for null** before accessing object properties
2. **Use `safeString()` helper** for all string outputs
3. **Check relationship fields** before accessing: `record.Lookup__r != null ? record.Lookup__r.Name : ''`

### Understanding CompSuite__Relation4__c (Junction Object Without Direct Lookups)

The `CompSuite__Relation4__c` object is a **generic junction object** that links records across different objects **without using direct lookup fields**. Instead, it stores record IDs as **text fields** along with metadata about the relationship.

#### Key Fields on Relation4:
| Field | Type | Description |
|-------|------|-------------|
| `CompSuite__Source_Record_ID__c` | Text | The ID of the "parent" record (stored as String, not Lookup!) |
| `CompSuite__Destination_Record_ID__c` | Text | The ID of the "child/related" record (stored as String, not Lookup!) |
| `CompSuite__Destination_Object_API_Name__c` | Text | The API name of the destination object (e.g., `CompSuite__Deviation__c`) |
| `CompSuite__Source_Object_API_Name__c` | Text | The API name of the source object (e.g., `CompSuite__Deviation__c`) |

#### Why This Pattern Exists:
- Allows **many-to-many relationships** between any objects without schema changes
- The same Finding can link to multiple NCs, IAs, and CAPA Plans
- Relationship types are determined by `CompSuite__Destination_Object_API_Name__c` or `CompSuite__Source_Object_API_Name__c`

#### Complete Relation4 Query Pattern:

```apex
// ============================================
// STEP 1: Convert Source IDs to Strings
// ============================================
// Relation4 stores IDs as TEXT, not as Lookup fields!
// You MUST convert your Set<Id> to Set<String> for the query
Set<String> sourceIdStrings = new Set<String>();
for (Id sourceId : sourceIds) {
    sourceIdStrings.add(String.valueOf(sourceId));
}

// ============================================
// STEP 2: Query ALL Relations in ONE Query
// ============================================
List<CompSuite__Relation4__c> relations = [
    SELECT Id,
           CompSuite__Source_Record_ID__c,      // Text field - the "parent" ID
           CompSuite__Destination_Record_ID__c,  // Text field - the "child" ID
           CompSuite__Destination_Object_API_Name__c  // Which object type
    FROM CompSuite__Relation4__c
    WHERE CompSuite__Source_Record_ID__c IN :sourceIdStrings
    WITH SECURITY_ENFORCED
];

// ============================================
// STEP 3: Build Mapping Structure
// ============================================
// Create maps to track which source records link to which destination records
// Separate by destination object type
Map<Id, Set<Id>> sourceToNCIds = new Map<Id, Set<Id>>();
Map<Id, Set<Id>> sourceToIAIds = new Map<Id, Set<Id>>();
Map<Id, Set<Id>> sourceToCAPAPlanIds = new Map<Id, Set<Id>>();

// Also collect ALL destination IDs for bulk querying later
Set<Id> allNCIds = new Set<Id>();
Set<Id> allIAIds = new Set<Id>();
Set<Id> allCAPAPlanIds = new Set<Id>();

// ============================================
// STEP 4: Parse Relations and Build Maps
// ============================================
for (CompSuite__Relation4__c rel : relations) {
    // Skip invalid records
    if (String.isBlank(rel.CompSuite__Source_Record_ID__c) ||
        String.isBlank(rel.CompSuite__Destination_Record_ID__c)) {
        continue;
    }

    // Convert text fields back to Id type (with error handling)
    Id sourceId;
    Id destId;
    try {
        sourceId = Id.valueOf(rel.CompSuite__Source_Record_ID__c);
        destId = Id.valueOf(rel.CompSuite__Destination_Record_ID__c);
    } catch (Exception e) {
        continue; // Skip malformed IDs
    }

    // Route to appropriate map based on destination object type
    if (rel.CompSuite__Destination_Object_API_Name__c == 'CompSuite__Deviation__c') {
        addToSetMap(sourceToNCIds, sourceId, destId);
        allNCIds.add(destId);
    } else if (rel.CompSuite__Destination_Object_API_Name__c == 'CompSuite__Immediate_Action__c') {
        addToSetMap(sourceToIAIds, sourceId, destId);
        allIAIds.add(destId);
    } else if (rel.CompSuite__Destination_Object_API_Name__c == 'CompSuite__CAPA_Plan__c') {
        addToSetMap(sourceToCAPAPlanIds, sourceId, destId);
        allCAPAPlanIds.add(destId);
    }
}

// ============================================
// STEP 5: Bulk Query Destination Records
// ============================================
// NOW query the actual NC, IA, CAPA Plan records using collected IDs
Map<Id, CompSuite__Deviation__c> ncMap = queryNCRecords(allNCIds);
Map<Id, CompSuite__Immediate_Action__c> iaMap = queryIARecords(allIAIds);
Map<Id, CompSuite__CAPA_Plan__c> capaPlanMap = queryCAPAPlans(allCAPAPlanIds);

// ============================================
// STEP 6: Use Maps When Building Wrappers
// ============================================
for (CompSuite__Observation__c finding : findings) {
    FindingWrapper wrapper = new FindingWrapper();
    wrapper.finding = finding;

    // Get NC records for this finding (using the pre-built map)
    if (sourceToNCIds.containsKey(finding.Id)) {
        for (Id ncId : sourceToNCIds.get(finding.Id)) {
            if (ncMap.containsKey(ncId)) {
                wrapper.ncRecords.add(ncMap.get(ncId));
            }
        }
    }
    // ... repeat for IA and CAPA Plan
}
```

#### Helper Method for Building Set Maps:
```apex
private void addToSetMap(Map<Id, Set<Id>> mapToUpdate, Id key, Id value) {
    if (!mapToUpdate.containsKey(key)) {
        mapToUpdate.put(key, new Set<Id>());
    }
    mapToUpdate.get(key).add(value);
}
```

#### Visual Flow of Relation4 Pattern:
```
┌─────────────────────────────────────────────────────────────────────────┐
│                        RELATION4 QUERY FLOW                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. Query Primary Records (e.g., Findings)                              │
│         ↓                                                                │
│  2. Collect Primary IDs → Convert to Set<String>                        │
│         ↓                                                                │
│  3. Query Relation4 WHERE Source_Record_ID IN :idStrings                │
│         ↓                                                                │
│  4. Parse Relations → Build Maps by Destination Object Type             │
│     ┌──────────────────┬──────────────────┬──────────────────┐          │
│     │ sourceToNCIds    │ sourceToIAIds    │ sourceToCAPAIds  │          │
│     │ (Finding→NC)     │ (Finding→IA)     │ (Finding→CAPA)   │          │
│     └──────────────────┴──────────────────┴──────────────────┘          │
│         ↓                                                                │
│  5. Collect ALL Destination IDs (allNCIds, allIAIds, allCAPAIds)        │
│         ↓                                                                │
│  6. Bulk Query Each Destination Object Type (ONE query per type)        │
│         ↓                                                                │
│  7. Build Wrappers Using Pre-Built Maps (NO queries in loops!)          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Step 5: Create Metadata File

After creating the Apex class, also create the `-meta.xml` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

## Step 6: Deployment & Testing

Remind the user:
1. Deploy using: `sf project deploy start --source-dir force-app`
2. Configure in Content Publisher template settings
3. Test with actual record IDs in the org

## Reference Examples

Point the user to existing implementations in this repository:
- `xact_CP_ExtendedRelatedFindingsOutput.cls` - Shows nested hierarchical output with Relation4 junction relationships
- `xact_CP_ProtocolExecutionOutput.cls` - Shows complex layout handling with multiple record types

---

## Pre-Flight Checklist

Before generating code, verify you have gathered:

### Data Requirements
- [ ] Primary object API name
- [ ] Record ID type being passed (Audit ID, Protocol Execution ID, etc.)
- [ ] All fields needed from primary object with labels
- [ ] Related objects and relationship type (direct lookup vs Relation4)
- [ ] All fields needed from each related object with labels
- [ ] Child objects of related objects (if any)
- [ ] Ordering/sorting requirements

### Technical Decisions
- [ ] Which relationships use Relation4 junction vs direct lookup?
- [ ] Are there multiple levels of nesting (parent → child → grandchild)?
- [ ] How should empty related sections be handled (hide or show placeholder)?

### Styling Preferences
- [ ] Section header colors and text
- [ ] Subsection header colors and text
- [ ] Font family and size
- [ ] Border styles
- [ ] Indentation for nested sections

---

## Code Generation Checklist

When writing the code, ensure:

- [ ] **No SOQL in loops** - All queries in separate methods called from getFormattedData()
- [ ] **WITH SECURITY_ENFORCED** on all SOQL queries
- [ ] **Empty set checks** before every query (`if (ids.isEmpty()) return...`)
- [ ] **Relation4 ID conversion** - Convert `Set<Id>` to `Set<String>` for Relation4 queries
- [ ] **Null-safe field access** - Check `lookup__r != null` before accessing relationship fields
- [ ] **safeString() helper** - Use for all string outputs to prevent XSS
- [ ] **Inline styles only** - No external CSS (PDF compatibility)
- [ ] **Table-based indentation** - For nested sections in PDF output
- [ ] **Meta.xml file** - Create matching metadata file

---

**NOW BEGIN:** Use the AskUserQuestion tool to gather requirements from the user. Start with Question Set 1 about the data source.
