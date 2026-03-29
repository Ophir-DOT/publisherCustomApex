/**
 * @description       : Extended Related Findings Output Component for Content Publisher.
 *                      Generates HTML output for Findings with related NC (Deviations),
 *                      Immediate Actions, and CAPA Plans with nested CAPA records.
 * @author            : Ophir Peleg
 * @last modified on  : 29-03-2026
 * @last modified by  : Ophir Peleg
 **/
global with sharing class xact_CP_ExtendedRelatedFindingsOutput implements CompSuite.CP_DynamicContentGenerator {

  // Constants for HTML styling
  private static final String FONT_FAMILY = '\'TT Norms Pro\', \'Arial Unicode MS\', \'Aptos\', Arial, Helvetica, sans-serif';
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
    public List<CompSuite__CAPA__c> otherCAPARecords { get; set; }

    public FindingWrapper() {
      this.ncRecords = new List<CompSuite__Deviation__c>();
      this.iaRecords = new List<CompSuite__Immediate_Action__c>();
      this.capaPlanRecords = new List<CAPAPlanWrapper>();
      this.otherCAPARecords = new List<CompSuite__CAPA__c>();
    }

    public Boolean hasRelatedRecords() {
      return !ncRecords.isEmpty() || !iaRecords.isEmpty() || !capaPlanRecords.isEmpty() || !otherCAPARecords.isEmpty();
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
      return '<div style="font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + '; width:100%;">'
        + '<p>No noted findings</p></div>';
    }

    // Collect Finding IDs for subsequent queries
    Set<Id> findingIds = new Map<Id, CompSuite__Observation__c>(lstFinding).keySet();

    // Query 2: Get relations from junction object (NC, IA, CAPA Plan)
    Map<Id, Set<Id>> findingToNCIds = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> findingToIAIds = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> findingToCAPAPlanIds = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> findingToCAPAIds = new Map<Id, Set<Id>>();
    Set<Id> allNCIds = new Set<Id>();
    Set<Id> allIAIds = new Set<Id>();
    Set<Id> allCAPAPlanIds = new Set<Id>();
    Set<Id> allCAPAIds = new Set<Id>();

    queryRelations(findingIds, findingToNCIds, findingToIAIds, findingToCAPAPlanIds, findingToCAPAIds, allNCIds, allIAIds, allCAPAPlanIds, allCAPAIds);

    // Query 3a: Also get NCs directly linked via Xact_Finding__c lookup and merge into maps
    queryDirectNCs(findingIds, findingToNCIds, allNCIds);

    // Query 3b: Get NC (Deviation) records
    Map<Id, CompSuite__Deviation__c> ncMap = queryNCRecords(allNCIds);

    // Query 4: Get Immediate Action records
    Map<Id, CompSuite__Immediate_Action__c> iaMap = queryImmediateActions(allIAIds);

    // Query 5: Get CAPA Plan records
    Map<Id, CompSuite__CAPA_Plan__c> capaPlanMap = queryCAPAPlans(allCAPAPlanIds);

    // Query 6: Get CAPA records (children of CAPA Plans)
    Map<Id, List<CompSuite__CAPA__c>> capaPlanToCapasMap = queryCAPARecords(allCAPAPlanIds);

    // Query 7: Get Other CAPA records (directly linked via Relation4)
    Map<Id, CompSuite__CAPA__c> otherCAPAMap = queryOtherCAPAs(allCAPAIds);

    // Build wrapper objects
    List<FindingWrapper> findingWrappers = buildFindingWrappers(
      lstFinding,
      findingToNCIds,
      findingToIAIds,
      findingToCAPAPlanIds,
      findingToCAPAIds,
      ncMap,
      iaMap,
      capaPlanMap,
      capaPlanToCapasMap,
      otherCAPAMap
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
    Map<Id, Set<Id>> findingToCAPAIds,
    Set<Id> allNCIds,
    Set<Id> allIAIds,
    Set<Id> allCAPAPlanIds,
    Set<Id> allCAPAIds
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
      } else if (rel.CompSuite__Destination_Object_API_Name__c == 'CompSuite__CAPA__c') {
        addToSetMap(findingToCAPAIds, findingId, destId);
        allCAPAIds.add(destId);
      }
    }
  }

  private void queryDirectNCs(
    Set<Id> findingIds,
    Map<Id, Set<Id>> findingToNCIds,
    Set<Id> allNCIds
  ) {
    List<CompSuite__Deviation__c> directNCs = [
      SELECT Id, Xact_Finding__c
      FROM CompSuite__Deviation__c
      WHERE Xact_Finding__c IN :findingIds
      WITH SECURITY_ENFORCED
    ];

    for (CompSuite__Deviation__c nc : directNCs) {
      addToSetMap(findingToNCIds, nc.Xact_Finding__c, nc.Id);
      allNCIds.add(nc.Id);
    }
  }

  private Map<Id, CompSuite__Deviation__c> queryNCRecords(Set<Id> ncIds) {
    if (ncIds.isEmpty()) {
      return new Map<Id, CompSuite__Deviation__c>();
    }

    return new Map<Id, CompSuite__Deviation__c>(
      [
        SELECT Id, Name, Deviation_Number__c
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
        SELECT Id, Name, Immediate_Action_Number__c, Action_Description__c, Type__c, Owner.Name, CompSuite__State__r.Name, Planned_Due_Date__c, Effective_Completion_Date__c
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
        SELECT Id, Name, CompSuite__State__r.Name, CompSuite__CAPA_Plan_Number__c
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
      SELECT Id, Name, CAPA_Number__c, CAPA_Plan__c, CompSuite__Action_Plan_Description__c, Owner.Name, CompSuite__State__r.Name, CompSuite__Due_Date__c, Extended_Due_Date__c, Completion_Date__c
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

  private Map<Id, CompSuite__CAPA__c> queryOtherCAPAs(Set<Id> capaIds) {
    if (capaIds.isEmpty()) {
      return new Map<Id, CompSuite__CAPA__c>();
    }

    return new Map<Id, CompSuite__CAPA__c>(
      [
        SELECT Id, Name, CAPA_Number__c, CAPA_Plan__c, CompSuite__Action_Plan_Description__c, Owner.Name, CompSuite__State__r.Name, CompSuite__Due_Date__c, Extended_Due_Date__c, Completion_Date__c
        FROM CompSuite__CAPA__c
        WHERE Id IN :capaIds
        WITH SECURITY_ENFORCED
      ]
    );
  }

  // ============================================
  // Wrapper Building Methods
  // ============================================

  private List<FindingWrapper> buildFindingWrappers(
    List<CompSuite__Observation__c> findings,
    Map<Id, Set<Id>> findingToNCIds,
    Map<Id, Set<Id>> findingToIAIds,
    Map<Id, Set<Id>> findingToCAPAPlanIds,
    Map<Id, Set<Id>> findingToCAPAIds,
    Map<Id, CompSuite__Deviation__c> ncMap,
    Map<Id, CompSuite__Immediate_Action__c> iaMap,
    Map<Id, CompSuite__CAPA_Plan__c> capaPlanMap,
    Map<Id, List<CompSuite__CAPA__c>> capaPlanToCapasMap,
    Map<Id, CompSuite__CAPA__c> otherCAPAMap
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

      // Add Other CAPA records (directly linked via Relation4)
      if (findingToCAPAIds.containsKey(finding.Id)) {
        for (Id capaId : findingToCAPAIds.get(finding.Id)) {
          if (otherCAPAMap.containsKey(capaId)) {
            wrapper.otherCAPARecords.add(otherCAPAMap.get(capaId));
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
        html += '<br style="page-break-before: always">';
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
      if (!wrapper.otherCAPARecords.isEmpty()) {
        html += buildOtherCAPASection(wrapper.otherCAPARecords);
      }
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
    html += '<p style="margin:2px 0;"><b>Finding Number: </b>' + safeString(wrapper.finding.Finding_ID__c) + '</p>';
    html += '<br/>';
    html += '<p style="margin:2px 0;"><b>Finding Description: </b>' + safeString(wrapper.finding.CompSuite__Observation_Description__c) + '</p>';
    html += '<br/>';
    html += '<p style="margin:2px 0;"><b>Finding Classification: </b>' + safeString(wrapper.finding.CompSuite__Observation_Class__c) + '</p>';
    html += '<br/>';
    html += '<p style="margin:2px 0;"><b>Finding Status: </b>' + (wrapper.finding.CompSuite__State__r != null ? safeString(wrapper.finding.CompSuite__State__r.Name) : '') + '</p>';
    html += '<br/>';
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

    // Section header
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
    html += '<div style="' + SUBSECTION_HEADER_STYLE + '">Related Non-Conformity(ies)</div>';
    html += '</div>';
    html += '</div>';

    // Each NC record in its own container with spacing between
    for (Integer i = 0; i < ncRecords.size(); i++) {
      CompSuite__Deviation__c nc = ncRecords[i];
      if (i > 0) {
        html += '<br/>';
      }
      html += '<div style="width:100%;display:table;table-layout:fixed;">';
      html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
      html += '<div style="padding:10px 6px 6px 10px; font-size: ' + FONT_SIZE + ';">';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Non-Conformity Number: </b>' + safeString(nc.Deviation_Number__c) + '</p>';
      html += '</div>';
      html += '</div>';
      html += '</div>';
    }

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
    html += '<div style="' + SUBSECTION_HEADER_STYLE + '">Related Immediate Actions</div>';
    html += '</div>';
    html += '</div>';

    // Each IA record in its own container with spacing between
    for (Integer i = 0; i < iaRecords.size(); i++) {
      CompSuite__Immediate_Action__c ia = iaRecords[i];
      if (i > 0) {
        html += '<br/>';
      }
      html += '<div style="width:100%;display:table;table-layout:fixed;">';
      html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
      html += '<div style="padding:10px 6px 6px 10px; font-size: ' + FONT_SIZE + ';">';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Immediate Action Number: </b>' + safeString(ia.Immediate_Action_Number__c) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Immediate Action Description: </b>' + safeString(ia.Action_Description__c) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Type: </b>' + safeString(ia.Type__c) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Owner: </b>' + safeString(ia.Owner.Name) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Status: </b>' + (ia.CompSuite__State__r != null ? safeString(ia.CompSuite__State__r.Name) : '') + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Planned Due Date: </b>' + formatAnswer('DATE', null, ia.Planned_Due_Date__c, null, false) + '</p>';
      html += '<br/>';
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
    html += '<div style="' + SUBSECTION_HEADER_STYLE + '">Related CAPA Plans</div>';
    html += '</div>';
    html += '</div>';

    // Each CAPA Plan in its own container with spacing between
    for (Integer i = 0; i < capaPlanWrappers.size(); i++) {
      CAPAPlanWrapper cpWrapper = capaPlanWrappers[i];
      if (i > 0) {
        html += '<br/>';
      }
      html += '<div style="width:100%;display:table;table-layout:fixed;">';
      html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
      html += '<div style="padding:10px 6px 6px 10px; font-size: ' + FONT_SIZE + ';">';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>CAPA Plan Number: </b>' + safeString(cpWrapper.capaPlan.CompSuite__CAPA_Plan_Number__c) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>CAPA Plan Status: </b>' + (cpWrapper.capaPlan.CompSuite__State__r != null ? safeString(cpWrapper.capaPlan.CompSuite__State__r.Name) : '') + '</p>';

      // Nested CAPA records
      if (!cpWrapper.capaRecords.isEmpty()) {
        html += '<p style="margin:15px 0 5px 0; font-weight:bold; font-size: ' + FONT_SIZE + ';">CAPAs included in the plan:</p>';

        for (CompSuite__CAPA__c capa : cpWrapper.capaRecords) {
          html += '<div style="margin-left:20px; padding:5px; border:1px solid #ddd; font-size: ' + FONT_SIZE + ';">';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>CAPA Number: </b>' + safeString(capa.CAPA_Number__c) + '</p>';
          html += '<br/>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Description: </b>' + safeString(capa.CompSuite__Action_Plan_Description__c) + '</p>';
          html += '<br/>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Owner: </b>' + safeString(capa.Owner.Name) + '</p>';
          html += '<br/>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Status: </b>' + (capa.CompSuite__State__r != null ? safeString(capa.CompSuite__State__r.Name) : '') + '</p>';
          html += '<br/>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Initial Due Date: </b>' + formatAnswer('DATE', null, capa.CompSuite__Due_Date__c, null, false) + '</p>';
          html += '<br/>';
          html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Due Date Extension: </b>' + formatAnswer('DATE', null, capa.Extended_Due_Date__c, null, false) + '</p>';
          html += '<br/>';
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

  private String buildOtherCAPASection(List<CompSuite__CAPA__c> capaRecords) {
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
    html += '<div style="' + SUBSECTION_HEADER_STYLE + '">Other Related CAPAs</div>';
    html += '</div>';
    html += '</div>';

    // Each CAPA record in its own container with spacing between
    for (Integer i = 0; i < capaRecords.size(); i++) {
      CompSuite__CAPA__c capa = capaRecords[i];
      if (i > 0) {
        html += '<br/>';
      }

      html += '<div style="width:100%;display:table;table-layout:fixed;">';
      html += '<div style="padding:4px;border:1px solid black;vertical-align:top;display:table-cell;width:100%;">';
      html += '<div style="padding:10px 6px 6px 10px; font-size: ' + FONT_SIZE + ';">';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>CAPA Number: </b>' + safeString(capa.CAPA_Number__c) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Description: </b>' + safeString(capa.CompSuite__Action_Plan_Description__c) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Owner: </b>' + safeString(capa.Owner.Name) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Status: </b>' + (capa.CompSuite__State__r != null ? safeString(capa.CompSuite__State__r.Name) : '') + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Initial Due Date: </b>' + formatAnswer('DATE', null, capa.CompSuite__Due_Date__c, null, false) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Due Date Extension: </b>' + formatAnswer('DATE', null, capa.Extended_Due_Date__c, null, false) + '</p>';
      html += '<br/>';
      html += '<p style="margin:2px 0; font-size: ' + FONT_SIZE + ';"><b>Completion Date: </b>' + formatAnswer('DATE', null, capa.Completion_Date__c, null, false) + '</p>';
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
    if (String.isBlank(value)) {
      return '';
    }
    return value.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;');
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
