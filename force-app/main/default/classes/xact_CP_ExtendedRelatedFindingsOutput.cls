/**
 * @description       : Extended Related Findings Output Component for Content Publisher.
 *                      Generates HTML output for Findings with related NC (Deviations),
 *                      Immediate Actions, and CAPA Plans with nested CAPA records.
 * @author            : Ophir Peleg
 * @last modified on  : 02-04-2026
 * @last modified by  : Claude
 **/
global with sharing class xact_CP_ExtendedRelatedFindingsOutput implements CompSuite.CP_DynamicContentGenerator {

  // Constants for HTML styling
  private static final String FONT_FAMILY = '\'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif';
  private static final String FONT_SIZE = '10pt';
  private static final String SECTION_HEADER_STYLE = 'background-color:#000000; color:white; font-weight:bold; padding:6px 10px;';
  private static final String SUBSECTION_HEADER_STYLE = 'background-color:#000000; color:white; font-weight:bold; padding:4px 10px; font-size:9pt;';

  // ============================================
  // Wrapper Classes
  // ============================================

  /**
   * @description Wrapper for Finding with all related records
   */
  public class FindingWrapper {
    public CompSuite__Observation__c finding { get; set; }
    public List<CompSuite__Deviation__c> ncRecords { get; set; }
    public List<CompSuite__Immediate_Action__c> iaRecords { get; set; }
    public List<CAPAPlanWrapper> capaPlanRecords { get; set; }

    public FindingWrapper() {
      this.ncRecords = new List<CompSuite__Deviation__c>();
      this.iaRecords = new List<CompSuite__Immediate_Action__c>();
      this.capaPlanRecords = new List<CAPAPlanWrapper>();
    }

    public Boolean hasRelatedRecords() {
      return !ncRecords.isEmpty() || !iaRecords.isEmpty() || !capaPlanRecords.isEmpty();
    }
  }

  /**
   * @description Wrapper for CAPA Plan with its child CAPA records
   */
  public class CAPAPlanWrapper {
    public CompSuite__CAPA_Plan__c capaPlan { get; set; }
    public List<CompSuite__CAPA__c> capaRecords { get; set; }

    public CAPAPlanWrapper(CompSuite__CAPA_Plan__c capaPlan) {
      this.capaPlan = capaPlan;
      this.capaRecords = new List<CompSuite__CAPA__c>();
    }
  }

  // ============================================
  // Interface Implementation
  // ============================================

  public String getJSON(Id recordId, String input) {
    return null;
  }

  public String getHTML(Id recordId, String input) {
    return getFormattedData(recordId, input);
  }

  // ============================================
  // Main Processing Method
  // ============================================

  public String getFormattedData(String recordId, String widthInput) {
    String strAuditId = recordId;
    String strHTMLData = '';

    // Query 1: Get all Findings for the Audit
    List<CompSuite__Observation__c> lstFinding = queryFindings(strAuditId);

    if (lstFinding.isEmpty()) {
      return strHTMLData;
    }

    // Collect Finding IDs for subsequent queries
    Set<Id> findingIds = new Map<Id, CompSuite__Observation__c>(lstFinding).keySet();

    // Query 2: Get relations from junction object (NC, IA, CAPA Plan)
    Map<Id, Set<Id>> findingToNCIds = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> findingToIAIds = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> findingToCAPAPlanIds = new Map<Id, Set<Id>>();
    Set<Id> allNCIds = new Set<Id>();
    Set<Id> allIAIds = new Set<Id>();
    Set<Id> allCAPAPlanIds = new Set<Id>();

    queryRelations(findingIds, findingToNCIds, findingToIAIds, findingToCAPAPlanIds, allNCIds, allIAIds, allCAPAPlanIds);

    // Query 3: Get NC (Deviation) records
    Map<Id, CompSuite__Deviation__c> ncMap = queryNCRecords(allNCIds);

    // Query 4: Get Immediate Action records
    Map<Id, CompSuite__Immediate_Action__c> iaMap = queryImmediateActions(allIAIds);

    // Query 5: Get CAPA Plan records
    Map<Id, CompSuite__CAPA_Plan__c> capaPlanMap = queryCAPAPlans(allCAPAPlanIds);

    // Query 6: Get CAPA records (children of CAPA Plans)
    Map<Id, List<CompSuite__CAPA__c>> capaPlanToCapasMap = queryCAPARecords(allCAPAPlanIds);

    // Build wrapper objects
    List<FindingWrapper> findingWrappers = buildFindingWrappers(
      lstFinding,
      findingToNCIds,
      findingToIAIds,
      findingToCAPAPlanIds,
      ncMap,
      iaMap,
      capaPlanMap,
      capaPlanToCapasMap
    );

    // Generate HTML output
    strHTMLData = generateHTML(findingWrappers);

    System.debug('xact_CP_ExtendedRelatedFindingsOutput strHTMLData==>' + strHTMLData);
    return strHTMLData;
  }

  // ============================================
  // Query Methods
  // ============================================

  private List<CompSuite__Observation__c> queryFindings(String auditId) {
    return [
      SELECT Id, Name, Finding_ID__c, CompSuite__Observation_Date__c, CompSuite__Observation_Description__c,
             CompSuite__Observation_Class__c, CompSuite__State__r.Name, Auditee_Response__c
      FROM CompSuite__Observation__c
      WHERE CompSuite__Audit__c = :auditId
      WITH SECURITY_ENFORCED
      ORDER BY Finding_ID__c ASC
    ];
  }

  private void queryRelations(
    Set<Id> findingIds,
    Map<Id, Set<Id>> findingToNCIds,
    Map<Id, Set<Id>> findingToIAIds,
    Map<Id, Set<Id>> findingToCAPAPlanIds,
    Set<Id> allNCIds,
    Set<Id> allIAIds,
    Set<Id> allCAPAPlanIds
  ) {
    // Convert Set<Id> to Set<String> for text field comparison
    Set<String> findingIdStrings = new Set<String>();
    for (Id findingId : findingIds) {
      findingIdStrings.add(String.valueOf(findingId));
    }

    List<CompSuite__Relation4__c> relations = [
      SELECT Id, CompSuite__Source_Record_ID__c, CompSuite__Destination_Record_ID__c, CompSuite__Destination_Object_API_Name__c
      FROM CompSuite__Relation4__c
      WHERE CompSuite__Source_Record_ID__c IN :findingIdStrings
      WITH SECURITY_ENFORCED
    ];

    for (CompSuite__Relation4__c rel : relations) {
      if (String.isBlank(rel.CompSuite__Source_Record_ID__c) || String.isBlank(rel.CompSuite__Destination_Record_ID__c)) {
        continue;
      }

      Id findingId;
      Id destId;
      try {
        findingId = Id.valueOf(rel.CompSuite__Source_Record_ID__c);
        destId = Id.valueOf(rel.CompSuite__Destination_Record_ID__c);
      } catch (Exception e) {
        continue;
      }

      if (rel.CompSuite__Destination_Object_API_Name__c == 'CompSuite__Deviation__c') {
        addToSetMap(findingToNCIds, findingId, destId);
        allNCIds.add(destId);
      } else if (rel.CompSuite__Destination_Object_API_Name__c == 'CompSuite__Immediate_Action__c') {
        addToSetMap(findingToIAIds, findingId, destId);
        allIAIds.add(destId);
      } else if (rel.CompSuite__Destination_Object_API_Name__c == 'CompSuite__CAPA_Plan__c') {
        addToSetMap(findingToCAPAPlanIds, findingId, destId);
        allCAPAPlanIds.add(destId);
      }
    }
  }

  private Map<Id, CompSuite__Deviation__c> queryNCRecords(Set<Id> ncIds) {
    if (ncIds.isEmpty()) {
      return new Map<Id, CompSuite__Deviation__c>();
    }

    return new Map<Id, CompSuite__Deviation__c>(
      [
        SELECT Id, Name
        FROM CompSuite__Deviation__c
        WHERE Id IN :ncIds
        WITH SECURITY_ENFORCED
      ]
    );
  }

  private Map<Id, CompSuite__Immediate_Action__c> queryImmediateActions(Set<Id> iaIds) {
    if (iaIds.isEmpty()) {
      return new Map<Id, CompSuite__Immediate_Action__c>();
    }

    return new Map<Id, CompSuite__Immediate_Action__c>(
      [
        SELECT Id, Name, Action_Description__c, Type__c, Owner.Name, CompSuite__State__r.Name, Planned_Due_Date__c, Effective_Completion_Date__c
        FROM CompSuite__Immediate_Action__c
        WHERE Id IN :iaIds
        WITH SECURITY_ENFORCED
      ]
    );
  }

  private Map<Id, CompSuite__CAPA_Plan__c> queryCAPAPlans(Set<Id> capaPlanIds) {
    if (capaPlanIds.isEmpty()) {
      return new Map<Id, CompSuite__CAPA_Plan__c>();
    }

    return new Map<Id, CompSuite__CAPA_Plan__c>(
      [
        SELECT Id, Name, CompSuite__State__r.Name
        FROM CompSuite__CAPA_Plan__c
        WHERE Id IN :capaPlanIds
        WITH SECURITY_ENFORCED
      ]
    );
  }

  private Map<Id, List<CompSuite__CAPA__c>> queryCAPARecords(Set<Id> capaPlanIds) {
    Map<Id, List<CompSuite__CAPA__c>> capaPlanToCapasMap = new Map<Id, List<CompSuite__CAPA__c>>();

    if (capaPlanIds.isEmpty()) {
      return capaPlanToCapasMap;
    }

    List<CompSuite__CAPA__c> capaList = [
      SELECT Id, CAPA_Plan__c, CompSuite__Action_Plan_Description__c, Owner.Name, CompSuite__State__r.Name, CompSuite__Due_Date__c, Extended_Due_Date__c, Completion_Date__c
      FROM CompSuite__CAPA__c
      WHERE CAPA_Plan__c IN :capaPlanIds
      WITH SECURITY_ENFORCED
    ];

    for (CompSuite__CAPA__c capa : capaList) {
      if (!capaPlanToCapasMap.containsKey(capa.CAPA_Plan__c)) {
        capaPlanToCapasMap.put(capa.CAPA_Plan__c, new List<CompSuite__CAPA__c>());
      }
      capaPlanToCapasMap.get(capa.CAPA_Plan__c).add(capa);
    }

    return capaPlanToCapasMap;
  }

  // ============================================
  // Wrapper Building Methods
  // ============================================

  private List<FindingWrapper> buildFindingWrappers(
    List<CompSuite__Observation__c> findings,
    Map<Id, Set<Id>> findingToNCIds,
    Map<Id, Set<Id>> findingToIAIds,
    Map<Id, Set<Id>> findingToCAPAPlanIds,
    Map<Id, CompSuite__Deviation__c> ncMap,
    Map<Id, CompSuite__Immediate_Action__c> iaMap,
    Map<Id, CompSuite__CAPA_Plan__c> capaPlanMap,
    Map<Id, List<CompSuite__CAPA__c>> capaPlanToCapasMap
  ) {
    List<FindingWrapper> wrappers = new List<FindingWrapper>();

    for (CompSuite__Observation__c finding : findings) {
      FindingWrapper wrapper = new FindingWrapper();
      wrapper.finding = finding;

      // Add NC records from map (via Relation4)
      if (findingToNCIds.containsKey(finding.Id)) {
        for (Id ncId : findingToNCIds.get(finding.Id)) {
          if (ncMap.containsKey(ncId)) {
            wrapper.ncRecords.add(ncMap.get(ncId));
          }
        }
      }

      // Add IA records from map
      if (findingToIAIds.containsKey(finding.Id)) {
        for (Id iaId : findingToIAIds.get(finding.Id)) {
          if (iaMap.containsKey(iaId)) {
            wrapper.iaRecords.add(iaMap.get(iaId));
          }
        }
      }

      // Add CAPA Plan wrappers with nested CAPAs
      if (findingToCAPAPlanIds.containsKey(finding.Id)) {
        for (Id capaPlanId : findingToCAPAPlanIds.get(finding.Id)) {
          if (capaPlanMap.containsKey(capaPlanId)) {
            CAPAPlanWrapper cpWrapper = new CAPAPlanWrapper(capaPlanMap.get(capaPlanId));
            if (capaPlanToCapasMap.containsKey(capaPlanId)) {
              cpWrapper.capaRecords = capaPlanToCapasMap.get(capaPlanId);
            }
            wrapper.capaPlanRecords.add(cpWrapper);
          }
        }
      }

      wrappers.add(wrapper);
    }

    return wrappers;
  }

  // ============================================
  // HTML Generation Methods
  // ============================================

  private String generateHTML(List<FindingWrapper> wrappers) {
    String html = '';
    html += '<div style="font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + '; width:100%;">';

    Boolean isFirst = true;
    for (FindingWrapper wrapper : wrappers) {
      if (!isFirst) {
        html += '<br/>';
      }
      isFirst = false;
      html += buildFindingHTML(wrapper);

      // Only show related sections if records exist
      if (!wrapper.ncRecords.isEmpty()) {
        html += buildNCSection(wrapper.ncRecords);
      }
      if (!wrapper.iaRecords.isEmpty()) {
        html += buildIASection(wrapper.iaRecords);
      }
      if (!wrapper.capaPlanRecords.isEmpty()) {
        html += buildCAPAPlanSection(wrapper.capaPlanRecords);
      }

      // Add spacing between findings
      html += '<div style="margin-bottom:20px;"></div>';
    }

    html += '</div>';
    return html;
  }

  private String buildFindingHTML(FindingWrapper wrapper) {
    String html = '';

    // Finding header
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
    html += '<div style="' + SECTION_HEADER_STYLE + '">Finding</div>';
    html += '</div>';
    html += '</div>';

    // Finding content
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
    html += '<div style="padding:10px 6px 6px 10px;">';
    html += '<p style="margin:2px 0;"><b>Finding Name: </b>' + safeString(wrapper.finding.Name) + '</p>';
    html += '<p style="margin:2px 0;"><b>Finding Description: </b>' + safeString(wrapper.finding.CompSuite__Observation_Description__c) + '</p>';
    html += '<p style="margin:2px 0;"><b>Finding Classification: </b>' + safeString(wrapper.finding.CompSuite__Observation_Class__c) + '</p>';
    html += '<p style="margin:2px 0;"><b>Finding Status: </b>' + (wrapper.finding.CompSuite__State__r != null ? safeString(wrapper.finding.CompSuite__State__r.Name) : '') + '</p>';
    html += '<p style="margin:2px 0;"><b>Auditee Response: </b>' + safeString(wrapper.finding.Auditee_Response__c) + '</p>';
    html += '</div>';
    html += '</div>';
    html += '</div>';

    return html;
  }

  private String buildNCSection(List<CompSuite__Deviation__c> ncRecords) {
    String html = '';

    // Spacing before section
    html += '<br/>';

    // Table-based indentation: empty cell + content cell
    html += '<table style="width:100%; border-collapse:collapse; font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + ';">';
    html += '<tr>';
    html += '<td style="width:30px;"></td>'; // Indent spacer
    html += '<td style="font-size: ' + FONT_SIZE + ';">';

    // NC header
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
    html += '<div style="' + SUBSECTION_HEADER_STYLE + '">NC (Non-Conformance)</div>';
    html += '</div>';
    html += '</div>';

    // NC content
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
    html += '<div style="padding:10px 6px 6px 10px; font-size: ' + FONT_SIZE + ';">';
    for (CompSuite__Deviation__c nc : ncRecords) {
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';">&bull; <b>NC Number: </b>' + safeString(nc.Name) + '</p>';
    }
    html += '</div>';
    html += '</div>';
    html += '</div>';

    html += '</td>';
    html += '</tr>';
    html += '</table>';

    return html;
  }

  private String buildIASection(List<CompSuite__Immediate_Action__c> iaRecords) {
    String html = '';

    // Spacing before section
    html += '<br/>';

    // Table-based indentation: empty cell + content cell
    html += '<table style="width:100%; border-collapse:collapse; font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + ';">';
    html += '<tr>';
    html += '<td style="width:30px;"></td>'; // Indent spacer
    html += '<td style="font-size: ' + FONT_SIZE + ';">';

    // Section header
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
    html += '<div style="' + SUBSECTION_HEADER_STYLE + '">Immediate Actions</div>';
    html += '</div>';
    html += '</div>';

    // Each IA record in its own container
    for (CompSuite__Immediate_Action__c ia : iaRecords) {
      html += '<div style="width:100%;display:table;table-layout:fixed;">';
      html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
      html += '<div style="padding:10px 6px 6px 10px; font-size: ' + FONT_SIZE + ';">';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Name: </b>' + safeString(ia.Name) + '</p>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Description: </b>' + safeString(ia.Action_Description__c) + '</p>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Type: </b>' + safeString(ia.Type__c) + '</p>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Owner: </b>' + safeString(ia.Owner.Name) + '</p>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>State: </b>' + (ia.CompSuite__State__r != null ? safeString(ia.CompSuite__State__r.Name) : '') + '</p>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Planned Due Date: </b>' + formatAnswer('DATE', null, ia.Planned_Due_Date__c, null, false) + '</p>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Effective Completion Date: </b>' + formatAnswer('DATE', null, ia.Effective_Completion_Date__c, null, false) + '</p>';
      html += '</div>';
      html += '</div>';
      html += '</div>';
    }

    html += '</td>';
    html += '</tr>';
    html += '</table>';

    return html;
  }

  private String buildCAPAPlanSection(List<CAPAPlanWrapper> capaPlanWrappers) {
    String html = '';

    // Spacing before section
    html += '<br/>';

    // Table-based indentation: empty cell + content cell
    html += '<table style="width:100%; border-collapse:collapse; font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + ';">';
    html += '<tr>';
    html += '<td style="width:30px;"></td>'; // Indent spacer
    html += '<td style="font-size: ' + FONT_SIZE + ';">';

    // CAPA Plans header
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
    html += '<div style="' + SUBSECTION_HEADER_STYLE + '">CAPA Plans</div>';
    html += '</div>';
    html += '</div>';

    // Each CAPA Plan in its own container
    for (CAPAPlanWrapper cpWrapper : capaPlanWrappers) {
      html += '<div style="width:100%;display:table;table-layout:fixed;">';
      html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
      html += '<div style="padding:10px 6px 6px 10px; font-size: ' + FONT_SIZE + ';">';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>CAPA Plan Number: </b>' + safeString(cpWrapper.capaPlan.Name) + '</p>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>State: </b>' + (cpWrapper.capaPlan.CompSuite__State__r != null ? safeString(cpWrapper.capaPlan.CompSuite__State__r.Name) : '') + '</p>';

      // Nested CAPA records
      if (!cpWrapper.capaRecords.isEmpty()) {
        html += '<br/>';
        html += '<p style="margin:2px 0; font-weight:bold; font-size: ' + FONT_SIZE + ';">CAPA Records:</p>';

        for (CompSuite__CAPA__c capa : cpWrapper.capaRecords) {
          html += '<div style="padding:5px; border:1px solid #ddd; font-size: ' + FONT_SIZE + ';">';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Description: </b>' + safeString(capa.CompSuite__Action_Plan_Description__c) + '</p>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Owner: </b>' + safeString(capa.Owner.Name) + '</p>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>State: </b>' + (capa.CompSuite__State__r != null ? safeString(capa.CompSuite__State__r.Name) : '') + '</p>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Initial Due Date: </b>' + formatAnswer('DATE', null, capa.CompSuite__Due_Date__c, null, false) + '</p>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Due Date Extension: </b>' + formatAnswer('DATE', null, capa.Extended_Due_Date__c, null, false) + '</p>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Completion Date: </b>' + formatAnswer('DATE', null, capa.Completion_Date__c, null, false) + '</p>';
          html += '</div>';
          html += '<br/>';
        }
      }

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
  // Utility Methods
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
