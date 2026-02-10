/**
 * @description       : Controller for xact_CP_Custom_Signature_sup_report_VF page with xact styling
 * @author            : Ophir Peleg
 * @group             :
 * @last modified on  : 02-10-2026
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
                CompSuite__User_Title__c,
                CompSuite__Started_By__r.Name,
                Name,
                Id,
                CreatedDate
            FROM CompSuite__Transition_Audit_Trail__c
            WHERE CompSuite__Object_Id__c = :strId
            WITH SECURITY_ENFORCED
        ];

        // Find the last transition record (most recent by CreatedDate)
        CompSuite__Transition_Audit_Trail__c lastRecord = null;
        for (CompSuite__Transition_Audit_Trail__c tmpTrail : myTransitionAuditTrail) {
            if (lastRecord == null || tmpTrail.CreatedDate > lastRecord.CreatedDate) {
                lastRecord = tmpTrail;
            }
        }

        // Add only the last record to the signature list
        if (lastRecord != null) {
            signatureObjectList.add(
                new SignatureObject(lastRecord.CompSuite__Started_By__r.Name, lastRecord.CompSuite__User_Title__c, lastRecord.CreatedDate)
            );
        }
    }

    public class SignatureObject implements Comparable {
        public String userName { set; get; }
        public String userTitle { set; get; }
        public String formattedDate { set; get; }
        public DateTime signatureDate { set; get; }

        public SignatureObject(String newUserName, String newUserTitle, DateTime newSignatureDate) {
            userName = newUserName;
            userTitle = newUserTitle;
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
