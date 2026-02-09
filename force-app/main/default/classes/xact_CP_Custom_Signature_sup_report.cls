/**
 * @description       : Dynamic class to generate Signature table with xact styling
 * @author            : Claude
 * @group             :
 * @last modified on  : 02-09-2026
 * @last modified by  : Claude
 **/
global class xact_CP_Custom_Signature_sup_report implements CompSuite.CP_DynamicContentGenerator {
    public string getJSON(Id recordId, String input) {
        return null;
    }

    public string getHTML(Id recordId, String input) {
        String vfSignatureName = input;
        String pageSize = '612;792';
        PageReference pageref = new PageReference('/apex/' + vfSignatureName);
        pageref.getParameters().put('pageSize', pageSize);
        pageref.getParameters().put('Id', String.valueOf(recordId).left(15));

        blob signaturePage;
        if (Test.isRunningTest()) {
            signaturePage = blob.valueOf('Unit.Test');
        } else {
            signaturePage = pageref.getContent();
        }

        String signaturePageString = signaturePage.toString();
        signaturePageString = signaturePageString.replace('http://www.w3.org/TR/html4/loose.dtd">', '');
        return signaturePageString;
    }
}
