/**
 * @description       : CAPA Management Report (Branded) for Content Publisher. Generates a
 *                      Dot Compliance branded HTML report of all open CAPAs in the org,
 *                      excluding Completed and Cancelled states. Uses PDF-compatible inline
 *                      styles (no border-radius, no gradients, no rgba). The recordId parameter
 *                      is intentionally ignored — this class queries all CAPAs org-wide.
 * @author            : Ophir Peleg
 * @last modified on  : 04-20-2026
 * @last modified by  : Claude
 **/
global with sharing class xact_CP_CAPAManagementReport implements CompSuite.CP_DynamicContentGenerator {

    // Brand colors
    private static final String PURPLE_500 = '#270648';
    private static final String PURPLE_300 = '#7D32C7';
    private static final String PURPLE_100 = '#D1AAF7';
    private static final String PURPLE_50  = '#EDE3F8';
    private static final String PURPLE_20  = '#F5F3F8';
    private static final String GP_500     = '#57515C';
    private static final String GP_400     = '#847C8C';
    private static final String GP_100     = '#DACFE5';
    private static final String GP_50      = '#EDEBF2';
    private static final String PINK_500   = '#DD00B7';
    private static final String PINK_100   = '#FFE1FB';
    private static final String PINK_50    = '#FFF4FD';
    private static final String GREEN_500  = '#38C5A2';
    private static final String RED_500    = '#CF3D50';
    private static final String RED_100    = '#FFD8DD';

    // PDF-safe font stacks
    private static final String FONT_UI   = '\'TT Norms Pro\', \'Arial Unicode MS\', Aptos, Arial, Helvetica, sans-serif';
    private static final String FONT_MONO = '\'Courier New\', Courier, monospace';

    // Reusable label style
    private static final String LABEL_STYLE = 'font-family: \'Courier New\', Courier, monospace; font-size:7pt; letter-spacing:0.10em; text-transform:uppercase; color:#847C8C; font-weight:bold;';

    // ============================================
    // Interface Methods
    // ============================================

    public String getJSON(Id recordId, String input) {
        return null;
    }

    public String getHTML(Id recordId, String input) {
        return buildReport();
    }

    // ============================================
    // Report Building
    // ============================================

    private String buildReport() {
        List<CompSuite__CAPA__c> capas = queryOpenCAPAs();

        Integer totalCount = capas.size();
        Integer openCount = 0;
        Integer dueThisWeek = 0;
        Integer overdueCount = 0;
        Date today = Date.today();
        Date weekFromNow = today.addDays(7);

        for (CompSuite__CAPA__c c : capas) {
            String st = (c.CompSuite__State__r != null) ? c.CompSuite__State__r.Name : '';
            if (String.isNotBlank(st) && !st.containsIgnoreCase('Completed') && !st.containsIgnoreCase('Cancelled')) {
                openCount++;
            }
            if (c.CompSuite__Due_Date__c != null) {
                if (c.CompSuite__Due_Date__c >= today && c.CompSuite__Due_Date__c <= weekFromNow) {
                    dueThisWeek++;
                }
                if (c.CompSuite__Due_Date__c < today && c.Completion_Date__c == null) {
                    overdueCount++;
                }
            }
        }

        String html = '<div style="font-family: ' + FONT_UI + '; color: ' + PURPLE_500 + '; width:100%; font-size:10pt;">';

        html += buildHeader();
        html += buildMetaStrip();
        html += buildFilters();
        html += buildSummary(totalCount, openCount, dueThisWeek, overdueCount);
        html += buildSectionHeading(totalCount);

        if (capas.isEmpty()) {
            html += '<div style="padding:20px; text-align:center; color: ' + GP_400 + '; font-size:10pt; font-style:italic;">No open CAPAs found matching the filter criteria.</div>';
        } else {
            Integer idx = 0;
            for (CompSuite__CAPA__c capa : capas) {
                idx++;
                if (idx > 1) {
                    html += '<div style="height:12px;"></div>';
                }
                html += buildCAPACard(capa);
            }
        }

        html += buildFooter();
        html += '</div>';
        return html;
    }

    // ============================================
    // Header (purple bar)
    // ============================================

    private String buildHeader() {
        TimeZone tz = UserInfo.getTimeZone();
        DateTime now = DateTime.now();
        Integer offsetMs = tz.getOffset(now);
        DateTime localDt = now.addSeconds(offsetMs / 1000);
        String fmtDate = localDt.formatGmt('yyyy-MM-dd');
        String fmtTime = localDt.formatGmt('HH:mm:ss');
        String tzName = tz.getID();

        String h = '';
        // Purple background
        h += '<table style="width:100%; border-collapse:collapse; background-color: ' + PURPLE_500 + '; color:#FFFFFF;"><tr><td style="padding:20px 30px 18px;">';

        // Brand
        h += '<div style="font-weight:bold; font-size:13pt;">Dot Compliance</div>';
        h += '<div style="font-family: ' + FONT_MONO + '; font-size:7pt; color:#9988AA; letter-spacing:0.12em; text-transform:uppercase; margin-top:2px;">eQMS &middot; Quality Reports</div>';

        // Title + stamp row
        h += '<table style="width:100%; margin-top:16px; border-collapse:collapse;"><tr>';

        // Left: title
        h += '<td style="vertical-align:bottom; padding:0; color:#FFFFFF;">';
        h += '<div style="font-family: ' + FONT_MONO + '; font-size:7pt; letter-spacing:0.14em; text-transform:uppercase; color: ' + PINK_500 + '; font-weight:bold; margin-bottom:5px;">&mdash;&mdash; Report &middot; CAPA Management</div>';
        h += '<div style="font-weight:500; font-size:20pt; letter-spacing:-0.018em; line-height:1.1; color:#FFFFFF;">CAPA Management Report</div>';
        h += '<div style="font-size:9pt; color:#B8A0CC; margin-top:5px; font-style:italic;">Corrective &amp; Preventive Action records filtered to active items.</div>';
        h += '</td>';

        // Right: stamp box
        h += '<td style="vertical-align:bottom; text-align:right; padding:0; width:190px;">';
        h += '<table style="border-collapse:collapse; border:1px solid #4A2D6B;"><tr><td style="padding:8px 12px; color:#FFFFFF;">';
        h += '<div style="' + LABEL_STYLE + ' color:#9988AA;">Generated</div>';
        h += '<div style="font-family: ' + FONT_MONO + '; font-size:9pt; color:#FFFFFF; margin-top:2px;">' + fmtDate + ' &middot; ' + fmtTime + '</div>';
        h += '<div style="' + LABEL_STYLE + ' color:#9988AA; margin-top:4px;">Timezone</div>';
        h += '<div style="font-family: ' + FONT_MONO + '; font-size:9pt; color:#FFFFFF; margin-top:2px;">' + safeString(tzName) + '</div>';
        h += '</td></tr></table>';
        h += '</td>';

        h += '</tr></table>';
        h += '</td></tr>';

        // Accent line (pink then purple)
        h += '<tr><td style="padding:0; height:3px; background-color: ' + PINK_500 + '; font-size:0; line-height:0;">&nbsp;</td></tr>';
        h += '</table>';

        return h;
    }

    // ============================================
    // Meta Strip (4-column)
    // ============================================

    private String buildMetaStrip() {
        TimeZone tz = UserInfo.getTimeZone();
        DateTime now = DateTime.now();
        Integer offsetMs = tz.getOffset(now);
        DateTime localDt = now.addSeconds(offsetMs / 1000);
        String fmtDateTime = localDt.formatGmt('yyyy-MM-dd HH:mm:ss');
        String userName = UserInfo.getName();

        String cellSt = 'padding:10px 12px; border:1px solid ' + GP_100 + '; vertical-align:top; width:25%;';

        String h = '';
        h += '<table style="width:100%; border-collapse:collapse; margin-top:16px;">';
        h += '<tr>';
        h += '<td style="' + cellSt + '"><div style="' + LABEL_STYLE + '">Report Type</div><div style="font-size:10pt; font-weight:bold; margin-top:3px;">CAPA Management</div></td>';
        h += '<td style="' + cellSt + '"><div style="' + LABEL_STYLE + '">Generated By</div><div style="font-size:10pt; font-weight:bold; margin-top:3px;">' + safeString(userName) + '</div></td>';
        h += '<td style="' + cellSt + '"><div style="' + LABEL_STYLE + '">As Of</div><div style="font-family: ' + FONT_MONO + '; font-size:9pt; font-weight:500; margin-top:3px;">' + fmtDateTime + '</div></td>';
        h += '<td style="' + cellSt + '"><div style="' + LABEL_STYLE + '">Scope</div><div style="font-size:10pt; font-weight:bold; margin-top:3px;">All CAPAs &middot; active</div></td>';
        h += '</tr></table>';

        return h;
    }

    // ============================================
    // Filters
    // ============================================

    private String buildFilters() {
        String h = '';
        h += '<table style="width:100%; border-collapse:collapse; margin-top:12px; background-color: ' + PURPLE_20 + '; border:1px dashed ' + GP_100 + ';"><tr><td style="padding:12px 14px;">';

        h += '<div style="font-size:10pt; font-weight:bold; margin-bottom:8px;">&#9707; Filters applied</div>';

        h += '<table style="width:100%; border-collapse:collapse;">';

        // Show row
        h += '<tr>';
        h += '<td style="width:90px; padding:3px 0; vertical-align:top;"><span style="' + LABEL_STYLE + '">Show</span></td>';
        h += '<td style="padding:3px 0; vertical-align:top;">';
        h += '<span style="padding:2px 8px; background:#FFFFFF; border:1px solid ' + GP_100 + '; font-size:9pt; font-weight:500;">';
        h += '<span style="color: ' + PURPLE_300 + ';">&#9679;</span> All CAPAs</span>';
        h += '</td></tr>';

        // State row
        h += '<tr>';
        h += '<td style="width:90px; padding:3px 0; vertical-align:top;"><span style="' + LABEL_STYLE + '">State</span></td>';
        h += '<td style="padding:3px 0; vertical-align:top;">State Name does not contain ';
        h += '<span style="padding:2px 8px; background: ' + RED_100 + '; color: ' + RED_500 + '; font-size:9pt; font-weight:500;">&minus; Completed</span> ';
        h += '<span style="padding:2px 8px; background: ' + RED_100 + '; color: ' + RED_500 + '; font-size:9pt; font-weight:500;">&minus; Cancelled</span>';
        h += '</td></tr>';

        h += '</table>';
        h += '</td></tr></table>';

        return h;
    }

    // ============================================
    // Summary KPIs
    // ============================================

    private String buildSummary(Integer totalCount, Integer openCount, Integer dueThisWeek, Integer overdueCount) {
        String cellSt = 'padding:12px 14px; border:1px solid ' + GP_100 + '; vertical-align:top; width:25%;';
        String numSt = 'font-weight:500; font-size:22pt; letter-spacing:-0.02em; line-height:1; margin-top:6px;';
        String subSt = 'font-size:8pt; color: ' + GP_500 + '; margin-top:4px; font-style:italic;';

        String h = '';
        h += '<table style="width:100%; border-collapse:collapse; margin-top:12px;">';
        h += '<tr>';

        h += '<td style="' + cellSt + '"><div style="' + LABEL_STYLE + '">Total Records</div>';
        h += '<div style="' + numSt + ' color: ' + PINK_500 + ';">' + totalCount + '</div>';
        h += '<div style="' + subSt + '">matching filter criteria</div></td>';

        h += '<td style="' + cellSt + '"><div style="' + LABEL_STYLE + '">Open CAPAs</div>';
        h += '<div style="' + numSt + ' color: ' + PINK_500 + ';">' + openCount + '</div>';
        h += '<div style="' + subSt + '">in progress &middot; not yet closed</div></td>';

        h += '<td style="' + cellSt + '"><div style="' + LABEL_STYLE + '">Due This Week</div>';
        h += '<div style="' + numSt + ' color: ' + PURPLE_500 + ';">' + dueThisWeek + '</div>';
        h += '<div style="' + subSt + '">planned due within 7 days</div></td>';

        h += '<td style="' + cellSt + '"><div style="' + LABEL_STYLE + '">Overdue</div>';
        h += '<div style="' + numSt + ' color: ' + PURPLE_500 + ';">' + overdueCount + '</div>';
        h += '<div style="' + subSt + '">' + (overdueCount == 0 ? 'none past planned due date' : 'past planned due date') + '</div></td>';

        h += '</tr></table>';
        return h;
    }

    // ============================================
    // Section Heading
    // ============================================

    private String buildSectionHeading(Integer totalCount) {
        String h = '';
        h += '<table style="width:100%; border-collapse:collapse; margin:16px 0 10px;"><tr>';
        h += '<td style="padding:0; vertical-align:middle; white-space:nowrap; width:1px;">';
        h += '<span style="font-size:12pt; font-weight:bold;">CAPA Records</span>';
        h += '&nbsp;&nbsp;';
        h += '<span style="font-family: ' + FONT_MONO + '; font-size:8pt; color: ' + GP_400 + '; background:#FFFFFF; border:1px solid ' + GP_100 + '; padding:2px 8px; font-weight:500;">' + totalCount + ' record' + (totalCount != 1 ? 's' : '') + '</span>';
        h += '</td>';
        h += '<td style="padding:0 0 0 10px; vertical-align:middle;"><div style="border-top:1px solid ' + GP_100 + '; height:0;"></div></td>';
        h += '</tr></table>';
        return h;
    }

    // ============================================
    // CAPA Card
    // ============================================

    private String buildCAPACard(CompSuite__CAPA__c capa) {
        String stateName = (capa.CompSuite__State__r != null) ? capa.CompSuite__State__r.Name : '';
        String ownerName = (capa.Owner != null) ? capa.Owner.Name : '';
        String initials = getInitials(ownerName);

        String h = '';
        // Card wrapper
        h += '<table style="width:100%; border-collapse:collapse; border:1px solid ' + GP_100 + '; page-break-inside:avoid;"><tr><td style="padding:0;">';

        // Card header row (purple tint background)
        h += '<table style="width:100%; border-collapse:collapse; background-color: ' + PURPLE_50 + '; border-bottom:1px solid ' + GP_100 + ';"><tr>';

        // CAPA number pill
        h += '<td style="padding:10px 14px; vertical-align:middle; white-space:nowrap; width:1px;">';
        h += '<span style="font-family: ' + FONT_MONO + '; font-size:9pt; font-weight:bold; letter-spacing:0.04em; color: ' + PURPLE_500 + '; background:#FFFFFF; border:1px solid ' + PURPLE_100 + '; padding:4px 10px;">';
        h += safeString(capa.CAPA_Number__c) + '</span>';
        h += '</td>';

        // Name
        h += '<td style="padding:10px 4px; vertical-align:middle;">';
        h += '<span style="font-size:12pt; font-weight:bold; color: ' + PURPLE_500 + ';">' + safeString(capa.Name) + '</span>';
        h += '</td>';

        // State badge
        h += '<td style="padding:10px 14px; vertical-align:middle; text-align:right; white-space:nowrap;">';
        h += '<span style="padding:3px 10px; font-size:9pt; font-weight:bold; background: ' + PINK_50 + '; color: ' + PINK_500 + '; border:1px solid ' + PINK_100 + ';">';
        h += '<span style="color: ' + PINK_500 + ';">&#9679;</span> ' + safeString(stateName) + '</span>';
        h += '</td>';

        h += '</tr></table>';

        // Fields section
        h += '<div style="padding:12px 14px;">';
        h += '<table style="width:100%; border-collapse:separate; border-spacing:6px;">';

        // Row 1: Owner + CAPA Number
        h += '<tr>';
        h += buildFieldCell('Owner', safeString(ownerName), false);
        h += buildFieldCell('CAPA Number', safeString(capa.CAPA_Number__c), true);
        h += '</tr>';

        // Row 2: Action Plan Description (full width)
        String descVal = String.isBlank(capa.CompSuite__Action_Plan_Description__c)
            ? '<span style="color: #ABA1B5; font-style:italic;">No description provided</span>'
            : safeString(capa.CompSuite__Action_Plan_Description__c);
        h += '<tr><td colspan="2" style="background: ' + PURPLE_20 + '; border:1px solid ' + GP_50 + '; padding:8px 10px; vertical-align:top;">';
        h += '<div style="' + LABEL_STYLE + '">Action Plan Description</div>';
        h += '<div style="font-size:10pt; margin-top:3px; line-height:1.5;">' + descVal + '</div>';
        h += '</td></tr>';

        // TBD: CAPA Summary, Effective Check Required, CAPA Source
        // h += '<tr>';
        // h += buildFieldCell('CAPA Summary', ..., false);
        // h += buildFieldCell('CAPA Source', ..., false);
        // h += '</tr>';

        h += '</table>';
        h += '</div>';

        // Timeline strip
        h += buildTimeline(capa);

        h += '</td></tr></table>';

        return h;
    }

    private String buildFieldCell(String label, String value, Boolean isMono) {
        String valStyle = isMono
            ? 'font-family: ' + FONT_MONO + '; font-weight:500; font-size:9pt;'
            : 'font-size:10pt; font-weight:500;';

        return '<td style="background: ' + PURPLE_20 + '; border:1px solid ' + GP_50 + '; padding:8px 10px; vertical-align:top; width:50%;">'
             + '<div style="' + LABEL_STYLE + '">' + label + '</div>'
             + '<div style="' + valStyle + ' color: ' + PURPLE_500 + '; margin-top:3px;">' + value + '</div>'
             + '</td>';
    }

    // ============================================
    // Timeline
    // ============================================

    private String buildTimeline(CompSuite__CAPA__c capa) {
        String stateName = (capa.CompSuite__State__r != null) ? capa.CompSuite__State__r.Name : '';
        String dueDate = formatDate(capa.CompSuite__Due_Date__c);
        String compDate = formatDate(capa.Completion_Date__c);

        Date today = Date.today();
        Boolean isOverdue = (capa.CompSuite__Due_Date__c != null && capa.CompSuite__Due_Date__c < today && capa.Completion_Date__c == null);
        Boolean isDueToday = (capa.CompSuite__Due_Date__c != null && capa.CompSuite__Due_Date__c == today);

        String dueDotColor = isOverdue ? RED_500 : (isDueToday ? PINK_500 : GP_400);
        String compDotColor = String.isNotBlank(compDate) ? GREEN_500 : '#C6BDCF';

        String h = '';
        h += '<table style="width:100%; border-collapse:collapse; border-top:1px dashed ' + GP_100 + ';"><tr>';

        // Node 1: Current State
        h += '<td style="vertical-align:top; width:33%; padding:12px 14px;">';
        h += '<table style="border-collapse:collapse;"><tr>';
        h += '<td style="vertical-align:top; padding:0 8px 0 0;"><span style="color: ' + GREEN_500 + '; font-size:14pt; line-height:1;">&#9679;</span></td>';
        h += '<td style="vertical-align:top; padding:0;">';
        h += '<div style="' + LABEL_STYLE + '">Current State</div>';
        h += '<div style="font-size:10pt; font-weight:bold; margin-top:2px;">' + safeString(stateName) + '</div>';
        h += '<div style="font-size:8pt; color: ' + GP_500 + '; margin-top:2px; font-style:italic;">record active in workflow</div>';
        h += '</td></tr></table>';
        h += '</td>';

        // Node 2: Planned Due
        h += '<td style="vertical-align:top; width:33%; padding:12px 8px;">';
        h += '<table style="border-collapse:collapse;"><tr>';
        h += '<td style="vertical-align:top; padding:0 8px 0 0;"><span style="color: ' + dueDotColor + '; font-size:14pt; line-height:1;">&#9679;</span></td>';
        h += '<td style="vertical-align:top; padding:0;">';
        h += '<div style="' + LABEL_STYLE + '">Planned Due</div>';
        if (String.isNotBlank(dueDate)) {
            h += '<div style="font-size:10pt; font-weight:bold; margin-top:2px;">' + dueDate + '</div>';
            if (isDueToday) {
                h += '<div style="font-size:8pt; color: ' + PINK_500 + '; margin-top:2px; font-style:italic; font-weight:bold;">due today</div>';
            } else if (isOverdue) {
                h += '<div style="font-size:8pt; color: ' + RED_500 + '; margin-top:2px; font-style:italic; font-weight:bold;">overdue</div>';
            }
        } else {
            h += '<div style="font-size:10pt; color:#ABA1B5; margin-top:2px; font-style:italic;">No due date set</div>';
        }
        h += '</td></tr></table>';
        h += '</td>';

        // Node 3: Completed
        h += '<td style="vertical-align:top; width:33%; padding:12px 14px 12px 8px;">';
        h += '<table style="border-collapse:collapse;"><tr>';
        h += '<td style="vertical-align:top; padding:0 8px 0 0;"><span style="color: ' + compDotColor + '; font-size:14pt; line-height:1;">&#9679;</span></td>';
        h += '<td style="vertical-align:top; padding:0;">';
        h += '<div style="' + LABEL_STYLE + '">Completed</div>';
        if (String.isNotBlank(compDate)) {
            h += '<div style="font-size:10pt; font-weight:bold; margin-top:2px;">' + compDate + '</div>';
        } else {
            h += '<div style="font-size:10pt; color:#ABA1B5; margin-top:2px; font-style:italic;">Not yet completed</div>';
            h += '<div style="font-size:8pt; color: ' + GP_500 + '; margin-top:2px; font-style:italic;">date stamp will appear on closure</div>';
        }
        h += '</td></tr></table>';
        h += '</td>';

        h += '</tr></table>';
        return h;
    }

    // ============================================
    // Footer
    // ============================================

    private String buildFooter() {
        String h = '';
        h += '<table style="width:100%; border-collapse:collapse; margin-top:18px; border-top:1px solid ' + GP_100 + ';"><tr>';
        h += '<td style="padding:10px 0; vertical-align:middle; font-family: ' + FONT_MONO + '; font-size:7pt; letter-spacing:0.08em; text-transform:uppercase; color: ' + GP_400 + ';">';
        h += '<b style="color: ' + PURPLE_500 + ';">DOT</b> &middot; Dot Compliance eQMS &nbsp;&middot;&nbsp; Confidential &middot; Quality record';
        h += '</td>';
        h += '<td style="padding:10px 0; vertical-align:middle; text-align:right; font-family: ' + FONT_MONO + '; font-size:7pt; letter-spacing:0.08em; text-transform:uppercase; color: ' + GP_400 + ';">CAPA Management Report</td>';
        h += '</tr></table>';
        return h;
    }

    // ============================================
    // Query Methods
    // ============================================

    private List<CompSuite__CAPA__c> queryOpenCAPAs() {
        return [
            SELECT Id, Name, CAPA_Number__c,
                   Owner.Name,
                   CompSuite__Action_Plan_Description__c,
                   CompSuite__Due_Date__c,
                   Completion_Date__c,
                   CompSuite__State__r.Name
            FROM CompSuite__CAPA__c
            WHERE CompSuite__State__r.Name = null
               OR ((NOT CompSuite__State__r.Name LIKE '%Completed%')
                   AND (NOT CompSuite__State__r.Name LIKE '%Cancelled%'))
            WITH SECURITY_ENFORCED
            ORDER BY CAPA_Number__c ASC
        ];
    }

    // ============================================
    // Utility Methods
    // ============================================

    @TestVisible
    private String safeString(String value) {
        return String.isBlank(value) ? '' : value.escapeHtml4();
    }

    @TestVisible
    private String formatDate(Date d) {
        if (d == null) {
            return '';
        }
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day());
        return dt.format('yyyy-MM-dd');
    }

    private String getInitials(String name) {
        if (String.isBlank(name)) {
            return '';
        }
        List<String> parts = name.trim().split('\\s+');
        String initials = '';
        for (String part : parts) {
            if (String.isNotBlank(part)) {
                initials += part.substring(0, 1).toUpperCase();
            }
            if (initials.length() >= 2) {
                break;
            }
        }
        return initials;
    }
}
