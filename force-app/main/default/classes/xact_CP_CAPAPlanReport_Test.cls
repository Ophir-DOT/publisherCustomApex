@isTest
private class xact_CP_CAPAPlanReport_Test {

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_CAPAPlanReport gen = new xact_CP_CAPAPlanReport();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }

    @isTest
    static void testGetHTML_noPlans() {
        Test.startTest();
        xact_CP_CAPAPlanReport gen = new xact_CP_CAPAPlanReport();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        System.assert(html.contains('No open CAPA Plans found'), 'Should show empty state');
    }

    @isTest
    static void testGetHTML_planWithNoCAPAs() {
        CompSuite__CAPA_Plan__c plan = new CompSuite__CAPA_Plan__c();
        insert plan;

        Test.startTest();
        xact_CP_CAPAPlanReport gen = new xact_CP_CAPAPlanReport();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        System.assert(html.contains('CAPA Plan Report'), 'Should contain report title');
        System.assert(html.contains('CAPA Plan:'), 'Should contain plan header');
        System.assert(html.contains('No CAPAs linked to this CAPA Plan'), 'Should show no CAPAs message');
    }

    @isTest
    static void testGetHTML_planWithCAPAs() {
        CompSuite__CAPA_Plan__c plan = new CompSuite__CAPA_Plan__c();
        insert plan;

        CompSuite__CAPA__c capa = new CompSuite__CAPA__c(CAPA_Plan__c = plan.Id);
        insert capa;

        Test.startTest();
        xact_CP_CAPAPlanReport gen = new xact_CP_CAPAPlanReport();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        System.assert(html.contains('CAPA Plan:'), 'Should contain plan header');
        System.assert(html.contains('CAPA:'), 'Should contain CAPA sub-header');
    }

    @isTest
    static void testGetHTML_multiplePlans() {
        CompSuite__CAPA_Plan__c plan1 = new CompSuite__CAPA_Plan__c();
        CompSuite__CAPA_Plan__c plan2 = new CompSuite__CAPA_Plan__c();
        insert new List<CompSuite__CAPA_Plan__c>{ plan1, plan2 };

        CompSuite__CAPA__c capa1 = new CompSuite__CAPA__c(CAPA_Plan__c = plan1.Id);
        CompSuite__CAPA__c capa2 = new CompSuite__CAPA__c(CAPA_Plan__c = plan1.Id);
        CompSuite__CAPA__c capa3 = new CompSuite__CAPA__c(CAPA_Plan__c = plan2.Id);
        insert new List<CompSuite__CAPA__c>{ capa1, capa2, capa3 };

        Test.startTest();
        xact_CP_CAPAPlanReport gen = new xact_CP_CAPAPlanReport();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        System.assert(html.contains('Total Plans: 2'), 'Should show 2 plans in filter info');
    }

    @isTest
    static void testGetHTML_reportHeader() {
        Test.startTest();
        xact_CP_CAPAPlanReport gen = new xact_CP_CAPAPlanReport();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        // Even with no plans, the wrapper is returned
        System.assert(html.contains('No open CAPA Plans found'), 'Should show empty state');
    }

    @isTest
    static void testSafeString() {
        xact_CP_CAPAPlanReport gen = new xact_CP_CAPAPlanReport();

        System.assertEquals('', gen.safeString(null), 'Null returns empty');
        System.assertEquals('', gen.safeString(''), 'Empty returns empty');
        System.assertEquals('Test', gen.safeString('Test'), 'Normal string returned');
        System.assertEquals('&lt;b&gt;', gen.safeString('<b>'), 'HTML escaped');
    }

    @isTest
    static void testFormatDate() {
        xact_CP_CAPAPlanReport gen = new xact_CP_CAPAPlanReport();

        System.assertEquals('', gen.formatDate(null), 'Null date returns empty');
        String result = gen.formatDate(Date.newInstance(2026, 4, 21));
        System.assert(result.contains('2026'), 'Should contain year');
    }
}
