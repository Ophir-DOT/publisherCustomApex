@isTest
private class xact_CP_ExtRelFindingsOutput_Test {

    @isTest
    static void testGetHTML_noFindings() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('No noted findings'), 'Should show no findings message');
    }

    @isTest
    static void testGetHTML_findingOnly() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Test description', Date.today());

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Test description'), 'Should contain finding description');
        System.assert(html.contains('Finding'), 'Should contain Finding header');
    }

    @isTest
    static void testGetHTML_findingWithDirectNC() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        CompSuite__Observation__c obs = xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Finding with NC', Date.today());

        xact_CP_TestDataFactory.createDeviation(obs.Id);

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Finding with NC'), 'Should contain finding');
        System.assert(html.contains('Non-Conformity'), 'Should contain NC section header');
    }

    @isTest
    static void testGetHTML_findingWithNCviaRelation4() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        CompSuite__Observation__c obs = xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Finding with junction NC', Date.today());

        CompSuite__Deviation__c dev = xact_CP_TestDataFactory.createDeviationUnlinked();
        xact_CP_TestDataFactory.createRelation4(obs.Id, dev.Id, 'CompSuite__Deviation__c');

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Finding with junction NC'), 'Should contain finding');
        System.assert(html.contains('Non-Conformity'), 'Should contain NC section');
    }

    @isTest
    static void testGetHTML_findingWithIA() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        CompSuite__Observation__c obs = xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Finding with IA', Date.today());

        CompSuite__Immediate_Action__c ia = xact_CP_TestDataFactory.createImmediateAction();
        xact_CP_TestDataFactory.createRelation4(obs.Id, ia.Id, 'CompSuite__Immediate_Action__c');

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Finding with IA'), 'Should contain finding');
        System.assert(html.contains('Immediate Action'), 'Should contain IA section header');
    }

    @isTest
    static void testGetHTML_findingWithCAPAPlan() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        CompSuite__Observation__c obs = xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Finding with CAPA Plan', Date.today());

        CompSuite__CAPA_Plan__c plan = xact_CP_TestDataFactory.createCAPAPlan();
        xact_CP_TestDataFactory.createRelation4(obs.Id, plan.Id, 'CompSuite__CAPA_Plan__c');

        xact_CP_TestDataFactory.createCAPA(plan.Id);

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Finding with CAPA Plan'), 'Should contain finding');
        System.assert(html.contains('CAPA Plan'), 'Should contain CAPA Plans section header');
    }

    @isTest
    static void testGetHTML_findingWithOtherCAPA() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        CompSuite__Observation__c obs = xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Finding with Other CAPA', Date.today());

        CompSuite__CAPA__c capa = xact_CP_TestDataFactory.createCAPAUnlinked();
        xact_CP_TestDataFactory.createRelation4(obs.Id, capa.Id, 'CompSuite__CAPA__c');

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Finding with Other CAPA'), 'Should contain finding');
        System.assert(html.contains('Other Related CAPAs'), 'Should contain Other CAPAs section header');
    }

    @isTest
    static void testGetHTML_findingWithAllRelated() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        CompSuite__Observation__c obs = xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Full finding', Date.today());

        // Direct NC
        xact_CP_TestDataFactory.createDeviation(obs.Id);
        // IA via junction
        CompSuite__Immediate_Action__c ia = xact_CP_TestDataFactory.createImmediateAction();
        xact_CP_TestDataFactory.createRelation4(obs.Id, ia.Id, 'CompSuite__Immediate_Action__c');
        // CAPA Plan via junction
        CompSuite__CAPA_Plan__c plan = xact_CP_TestDataFactory.createCAPAPlan();
        xact_CP_TestDataFactory.createRelation4(obs.Id, plan.Id, 'CompSuite__CAPA_Plan__c');
        xact_CP_TestDataFactory.createCAPA(plan.Id);
        // Other CAPA via junction
        CompSuite__CAPA__c otherCapa = xact_CP_TestDataFactory.createCAPAUnlinked();
        xact_CP_TestDataFactory.createRelation4(obs.Id, otherCapa.Id, 'CompSuite__CAPA__c');

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Full finding'), 'Should contain finding description');
        System.assert(html.contains('Non-Conformity'), 'Should contain NC section');
        System.assert(html.contains('Immediate Action'), 'Should contain IA section');
        System.assert(html.contains('CAPA Plan'), 'Should contain CAPA Plan section');
        System.assert(html.contains('Other Related CAPAs'), 'Should contain Other CAPAs section');
    }

    @isTest
    static void testGetHTML_multipleFindings() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        xact_CP_TestDataFactory.createObservation(audit.Id, null, 'First finding', Date.today());
        xact_CP_TestDataFactory.createObservation(audit.Id, null, 'Second finding', Date.today());

        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('First finding'), 'Should contain first finding');
        System.assert(html.contains('Second finding'), 'Should contain second finding');
        System.assert(html.contains('page-break-before'), 'Should have page break between findings');
    }

    @isTest
    static void testFormatAnswer_date() {
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();

        Test.startTest();
        String result = gen.formatAnswer('DATE', null, Date.newInstance(2026, 6, 15), null, false);
        Test.stopTest();

        System.assertNotEquals('', result, 'Should return formatted date');
    }

    @isTest
    static void testFormatAnswer_datetime() {
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();

        Test.startTest();
        String result = gen.formatAnswer('DATETIME', null, null, DateTime.newInstance(2026, 6, 15, 14, 30, 0), false);
        Test.stopTest();

        System.assertNotEquals('', result, 'Should return formatted datetime');
    }

    @isTest
    static void testFormatAnswer_string() {
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();

        Test.startTest();
        String result = gen.formatAnswer('TEXT', 'Hello\nWorld', null, null, false);
        Test.stopTest();

        System.assert(result.contains('<br/>'), 'Should replace newlines with br');
    }

    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput.FindingWrapper fw = new xact_CP_ExtendedRelatedFindingsOutput.FindingWrapper();
        System.assertEquals(false, fw.hasRelatedRecords(), 'Empty wrapper should have no related records');

        xact_CP_ExtendedRelatedFindingsOutput.CAPAPlanWrapper cpw = new xact_CP_ExtendedRelatedFindingsOutput.CAPAPlanWrapper(
            new CompSuite__CAPA_Plan__c()
        );
        System.assertNotEquals(null, cpw.capaRecords, 'CAPA records list should be initialized');
        Test.stopTest();
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_ExtendedRelatedFindingsOutput gen = new xact_CP_ExtendedRelatedFindingsOutput();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }
}