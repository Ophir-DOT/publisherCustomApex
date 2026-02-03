/**
 * @description       : This class generates Related Findings (Observations) Output from Content Publisher.
 *                      Receives the Audit ID directly and queries Observations related to that Audit.
 * @author            : Ceptes
 * @group             :
 * @last modified on  : 02-03-2026
 * @last modified by  : Claude
 **/
global with sharing class xact_CP_RelatedFindingsOutput implements CompSuite.CP_DynamicContentGenerator {

  public string getJSON(Id recordId, string input) {
    return null;
  }

  public string getHTML(Id recordId, string input) {
    String findingsOutputString = '';
    findingsOutputString = getFormatedData(recordId, input);
    return findingsOutputString;
  }

  public String getFormatedData(String recordId, string widthInput) {
    string strAuditId = recordId;
    string strHTMLData = '';

    // Query Observations directly using the Audit ID passed as recordId
    List<CompSuite__Observation__c> lstFinding = [
      SELECT Finding_ID__c, CompSuite__Observation_Date__c, CompSuite__Observation_Description__c
      FROM CompSuite__Observation__c
      WHERE CompSuite__Audit__c = :strAuditId
      WITH SECURITY_ENFORCED
      ORDER BY Finding_ID__c ASC
    ];

    // Findings sections
    strHTMLData += '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif; font-size: 10pt;align-content: center;width:100%;">';
    for (CompSuite__Observation__c obs : lstFinding) {
      strHTMLData += '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif; font-size: 10pt;align-content: center;width:100%;">';
      strHTMLData += '<div style="width:100%;display:table;table-layout:fixed;">';
      strHTMLData += '    <div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
      strHTMLData += '      <div style="background-color:black; color:white; font-weight:bold; padding:4px;">Findings</div>';
      strHTMLData += '    </div>';
      strHTMLData += '  </div>';

      strHTMLData += '<div style="width:100%;display:table;table-layout:fixed;">';
      strHTMLData += '  <div style="padding:4px;border:1px solid black;vertical-align: top;display:table-cell;width:100%;">';
      strHTMLData += '      <div style="padding:10px 6px 6px 10px;">';
      strHTMLData += '        <p style="margin:2px 0;"><b>Finding Name: </b>' + obs.Finding_ID__c + '</p>';
      strHTMLData += '        <p style="margin:2px 0;"><b>Finding Description: </b>' + obs.CompSuite__Observation_Description__c + '</p>';
      strHTMLData += '        <p style="margin:2px 0;"><b>Finding Date: </b>' + formatAnswer('DATE', null, obs.CompSuite__Observation_Date__c, null, false) + '</p>';
      strHTMLData += '      </div>';
      strHTMLData += '  </div>';
      strHTMLData += '</div>';
      strHTMLData += '<br/>';
    }

    strHTMLData += '</div>';

    System.debug('xact_CP_RelatedFindingsOutput strHTMLData==>' + strHTMLData);
    return strHTMLData;
  }

  public String formatAnswer(String pContentType, String pStringAnswer, Date pDateAnswer, Datetime pDateTimeAnswer, Boolean pConvertoAspose) {
    String retAnswer = '';
    if (pContentType.toUpperCase().trim() == 'DATETIME') {
      if (pDateTimeAnswer != null) {
        if (pConvertoAspose) {
          Integer timeZone = 0;
          try {
            timeZone = integer.valueof(CompSuite__Aspose_Utils__c.getValues('PdfTimeZone').CompSuite__value__c);
          } catch (exception exp) {
            timeZone = 0;
          }

          pDateTimeAnswer = pDateTimeAnswer.addHours(timeZone);
        }

        retAnswer = pDateTimeAnswer.format('MMM dd, yyyy, hh:mm a', UserInfo.getTimeZone().toString());
      }
    } else if (pContentType.toUpperCase().trim() == 'DATE') {
      //Date
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
