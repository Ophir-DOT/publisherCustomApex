/**
 * @description       : Controller for xact_CP_Custom_Signature_VF page with xact styling
 * @author            : Claude
 * @group             :
 * @last modified on  : 02-03-2026
 * @last modified by  : Claude
 **/
public with sharing class xact_CP_Custom_Signature_Ctrl {
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

    public xact_CP_Custom_Signature_Ctrl() {
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

        Map<String, String> title2signatureMapTime = new Map<String, String>();

        List<CompSuite__Transition_Audit_Trail__c> myTransitionAuditTrail = new List<CompSuite__Transition_Audit_Trail__c>(
            [
                SELECT
                    CompSuite__State_Transition__c,
                    CompSuite__User_Title__c,
                    CompSuite__Started_By__c,
                    CompSuite__Started_By__r.Name,
                    CompSuite__Started_By__r.Title,
                    CompSuite__Source__c,
                    CompSuite__Signed__c,
                    CompSuite__Object_Id__c,
                    CompSuite__State_Transition__r.Name,
                    Name,
                    Id,
                    CompSuite__Destination__c,
                    CreatedDate
                FROM CompSuite__Transition_Audit_Trail__c
                WHERE CompSuite__Object_Id__c = :strId
            ]
        );

        List<CompSuite__Transition_Audit_Trail__c> newTransitionAuditTrail = new List<CompSuite__Transition_Audit_Trail__c>();
        for (CompSuite__Transition_Audit_Trail__c tmpTrail : myTransitionAuditTrail) {
            if (tmpTrail.CompSuite__Object_Id__c.equals(strId)) {
                newTransitionAuditTrail.add(tmpTrail);
            }
        }

        CompSuite__Transition_Audit_Trail__c comAT;
        String swapAction;
        for (CompSuite__Transition_Audit_Trail__c tmpTrail : myTransitionAuditTrail) {
            comAT = tmpTrail;
            swapAction = comAT.CompSuite__State_Transition__r.Name;
            if (comAT.Name.contains('-')) {
                swapAction = comAT.Name;
            }
            signatureObjectList.add(
                new SignatureObject(comAT.CompSuite__Started_By__r.Name, comAT.CompSuite__User_Title__c, swapAction, comAT.CreatedDate)
            );
        }

        signatureObjectList.sort();
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
