/**
 * @description       : Content Publisher Dynamic Content Generator for Internal Signature Report
 * @author            : Ophir Peleg
 * @last modified on  : 29-03-2026
 * @last modified by  : Ophir Peleg
 **/
global with sharing class xact_CP_Custom_Signature_int_report implements CompSuite.CP_DynamicContentGenerator {

    public String getJSON(Id recordId, String input) {
        return null;
    }

    public String getHTML(Id recordId, String input) {
        // Input contains the VF page name (e.g., "xact_CP_Custom_Signature_int_report_VF")
        String vfPageName = String.isNotBlank(input) ? input.trim() : 'xact_CP_Custom_Signature_int_report_VF';

        // Use PageReference to render the Visualforce page
        PageReference pageRef = new PageReference('/apex/' + vfPageName);
        pageRef.getParameters().put('Id', recordId);
        pageRef.getParameters().put('pageSize', '612;792'); // Default Letter size

        String htmlContent = '';
        try {
            // Get the page content as HTML
            if (Test.isRunningTest()) {
                htmlContent = '<div>Test Mode - Signature Table</div>';
            } else {
                Blob pageBlob = pageRef.getContent();
                htmlContent = pageBlob.toString();
            }
        } catch (Exception e) {
            htmlContent = '<div style="color:red;">Error rendering signature table: ' + e.getMessage() + '</div>';
        }

        return htmlContent;
    }
}
