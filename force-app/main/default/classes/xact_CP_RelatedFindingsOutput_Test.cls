/**
 * @description       : Test class for xact_CP_RelatedFindingsOutput
 * @author            : Ophir Peleg
 * @last modified on  : 29-03-2026
 * @last modified by  : Ophir Peleg
 **/
@isTest
private class xact_CP_RelatedFindingsOutput_Test {

    @isTest
    static void testGetHTML_noFindings() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, html, 'Should not return null');
    }

    @isTest
    static void testGetHTML_singleFinding() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Test finding description', Date.today());

        Test.startTest();
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Test finding description'), 'Should contain finding description');
        System.assert(html.contains('Findings'), 'Should contain Findings header');
    }

    @isTest
    static void testGetHTML_multipleFindings() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        xact_CP_TestDataFactory.createObservation(audit.Id, null, 'First finding', Date.today());
        xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Second finding', Date.today().addDays(-1));

        Test.startTest();
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('First finding'), 'Should contain first finding');
        System.assert(html.contains('Second finding'), 'Should contain second finding');
        System.assert(html.contains('page-break-before'), 'Should contain page break between findings');
    }

    @isTest
    static void testFormatAnswer_date() {
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();

        Test.startTest();
        String result = gen.formatAnswer('DATE', null, Date.newInstance(2026, 3, 15), null, false);
        Test.stopTest();

        System.assertNotEquals('', result, 'Should return formatted date');
        System.assert(result.contains('2026'), 'Should contain the year');
    }

    @isTest
    static void testFormatAnswer_nullDate() {
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();

        Test.startTest();
        String result = gen.formatAnswer('DATE', null, null, null, false);
        Test.stopTest();

        System.assertEquals('', result, 'Should return empty string for null date');
    }

    @isTest
    static void testFormatAnswer_datetime() {
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();

        Test.startTest();
        String result = gen.formatAnswer('DATETIME', null, null, DateTime.newInstance(2026, 3, 15, 10, 30, 0), false);
        Test.stopTest();

        System.assertNotEquals('', result, 'Should return formatted datetime');
        System.assert(result.contains('2026'), 'Should contain the year');
    }

    @isTest
    static void testFormatAnswer_string() {
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();

        Test.startTest();
        String result = gen.formatAnswer('TEXT', 'Line1\nLine2', null, null, false);
        Test.stopTest();

        System.assert(result.contains('<br/>'), 'Should replace newlines with br tags');
    }

    @isTest
    static void testFormatAnswer_nullString() {
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();

        Test.startTest();
        String result = gen.formatAnswer('TEXT', null, null, null, false);
        Test.stopTest();

        System.assertEquals('', result, 'Should return empty string for null string');
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_RelatedFindingsOutput gen = new xact_CP_RelatedFindingsOutput();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }
}
