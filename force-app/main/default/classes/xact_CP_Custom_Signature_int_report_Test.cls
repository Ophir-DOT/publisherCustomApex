@isTest
private class xact_CP_Custom_Signature_int_report_Test {

    @isTest
    static void testGetHTML_testMode() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_Custom_Signature_int_report gen = new xact_CP_Custom_Signature_int_report();
        String html = gen.getHTML(audit.Id, 'xact_CP_Custom_Signature_int_report_VF');
        Test.stopTest();

        System.assertNotEquals(null, html, 'HTML should not be null');
        System.assert(html.contains('Test Mode'), 'Should contain test mode text in test context');
    }

    @isTest
    static void testGetHTML_blankInput() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_Custom_Signature_int_report gen = new xact_CP_Custom_Signature_int_report();
        String html = gen.getHTML(audit.Id, '');
        Test.stopTest();

        System.assertNotEquals(null, html, 'HTML should not be null even with blank input');
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_Custom_Signature_int_report gen = new xact_CP_Custom_Signature_int_report();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }
}