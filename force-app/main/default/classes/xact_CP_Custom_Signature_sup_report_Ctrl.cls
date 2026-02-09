/**
 * @description       : Controller for xact_CP_Custom_Signature_sup_report_VF page with xact styling
 * @author            : Claude
 * @group             :
 * @last modified on  : 02-09-2026
 * @last modified by  : Claude
 **/
public with sharing class xact_CP_Custom_Signature_sup_report_Ctrl {
    public List<SignatureObject> signatureObjectList { set; get; }
    public String strGmt { set; get; }
    public Integer intGmt { set; get; }
    public String pageSize { set; get; }

    public static String orgTimeZone {
        get {
            if (orgTimeZone == null) {
                orgTimeZone = [SELECT TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
            }
            return orgTimeZone;
        }
        private set;
    }

    public xact_CP_Custom_Signature_sup_report_Ctrl() {
        try {
            intGmt = integer.valueof(CompSuite__Aspose_Utils__c.getValues('PdfTimeZone').CompSuite__value__c);
        } catch (exception e) {
            intGmt = 0;
        }

        if (intGmt > 0) {
            strGmt = '(GMT+' + intGmt + ')';
        } else if (intGmt < 0) {
            strGmt = '(GMT' + intGmt + ')';
        } else {
            strGmt = '(GMT)';
        }

        string strId = ApexPages.currentPage().getParameters().get('Id').abbreviate(15);
        pageSize = ApexPages.currentPage().getParameters().get('pageSize');
        String width = pageSize.split(';')[0];
        String height = pageSize.split(';')[1];
        Integer intWidth = Integer.valueOf(width);
        Integer intHeight = Integer.valueOf(height);
        intWidth = (intWidth * 96) / 72;
        intHeight = (intHeight * 96) / 72;
        pageSize = intWidth + 'px ' + intHeight + 'px';
        signatureObjectList = new List<SignatureObject>();

        List<CompSuite__Transition_Audit_Trail__c> myTransitionAuditTrail = [
            SELECT
                CompSuite__State_Transition__c,
                CompSuite__User_Title__c,
                CompSuite__Started_By__c,
                CompSuite__Started_By__r.Name,
                CompSuite__State_Transition__r.Name,
                Name,
                Id,
                CreatedDate
            FROM CompSuite__Transition_Audit_Trail__c
            WHERE CompSuite__Object_Id__c = :strId
            WITH SECURITY_ENFORCED
        ];

        // Find the last "Complete" record (most recent by CreatedDate)
        CompSuite__Transition_Audit_Trail__c lastCompleteRecord = null;
        for (CompSuite__Transition_Audit_Trail__c tmpTrail : myTransitionAuditTrail) {
            String actionName = tmpTrail.CompSuite__State_Transition__r.Name;
            if (tmpTrail.Name.contains('-')) {
                actionName = tmpTrail.Name;
            }

            // Check if this is a "Complete" action
            if (actionName != null && actionName.equalsIgnoreCase('Response Provided')) {
                // Keep the most recent Complete record
                if (lastCompleteRecord == null || tmpTrail.CreatedDate > lastCompleteRecord.CreatedDate) {
                    lastCompleteRecord = tmpTrail;
                }
            }
        }

        // Add only the last Complete record to the signature list
        if (lastCompleteRecord != null) {
            String swapAction = lastCompleteRecord.CompSuite__State_Transition__r.Name;
            if (lastCompleteRecord.Name.contains('-')) {
                swapAction = lastCompleteRecord.Name;
            }
            signatureObjectList.add(
                new SignatureObject(lastCompleteRecord.CompSuite__Started_By__r.Name, lastCompleteRecord.CompSuite__User_Title__c, swapAction, lastCompleteRecord.CreatedDate)
            );
        }
    }

    public class SignatureObject implements Comparable {
        public String userName { set; get; }
        public String userTitle { set; get; }
        public String actionName { set; get; }
        public String formattedDate { set; get; }
        public DateTime signatureDate { set; get; }

        public SignatureObject(String newUserName, String newUserTitle, String newActionName, DateTime newSignatureDate) {
            userName = newUserName;
            userTitle = newUserTitle;
            actionName = newActionName;
            signatureDate = newSignatureDate;
            formattedDate = newSignatureDate.format('dd-MMM-yyyy HH:mm', orgTimeZone);
        }

        public Integer compareTo(Object compareTo) {
            SignatureObject compareToApa = (SignatureObject) compareTo;

            Integer returnValue = 0;
            if (signatureDate > compareToApa.signatureDate) {
                returnValue = 1;
            } else if (signatureDate < compareToApa.signatureDate) {
                returnValue = -1;
            }
            return returnValue;
        }
    }
}
