@isTest
private class xact_CP_StyledMultiPicklistOutput_Test {

    @isTest
    static void testGetHTML_blankInput() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_StyledMultiPicklistOutput gen = new xact_CP_StyledMultiPicklistOutput();
        String html = gen.getHTML(audit.Id, '');
        Test.stopTest();

        System.assertEquals('', html, 'Should return empty string for blank input');
    }

    @isTest
    static void testGetHTML_nullInput() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_StyledMultiPicklistOutput gen = new xact_CP_StyledMultiPicklistOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assertEquals('', html, 'Should return empty string for null input');
    }

    @isTest
    static void testGetHTML_validField() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        // Use Name field as a text proxy for testing - set it to semicolon-separated values
        audit.Name = 'ValueA;ValueB;ValueC';
        update audit;

        Test.startTest();
        xact_CP_StyledMultiPicklistOutput gen = new xact_CP_StyledMultiPicklistOutput();
        String html = gen.getHTML(audit.Id, 'Name');
        Test.stopTest();

        System.assert(html.contains('ValueA'), 'Should contain first value');
        System.assert(html.contains('ValueB'), 'Should contain second value');
        System.assert(html.contains('ValueC'), 'Should contain third value');
        System.assert(html.contains('<br/>'), 'Should contain line breaks between values');
        System.assert(html.contains('<div'), 'Should be wrapped in a div');
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_StyledMultiPicklistOutput gen = new xact_CP_StyledMultiPicklistOutput();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }
}