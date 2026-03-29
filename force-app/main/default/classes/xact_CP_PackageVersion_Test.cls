@isTest
private class xact_CP_PackageVersion_Test {

    @isTest
    static void testGetHTML_withVersion() {
        xact_CP_TestDataFactory.createEnvironmentSettings('5.4.0');

        Test.startTest();
        xact_CP_PackageVersion gen = new xact_CP_PackageVersion();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        System.assertNotEquals('', html, 'HTML should not be empty when version exists');
        System.assert(html.contains('5.4.0'), 'HTML should contain the version number');
        System.assert(html.contains('<span'), 'HTML should contain a span element');
    }

    @isTest
    static void testGetHTML_noSettings() {
        Test.startTest();
        xact_CP_PackageVersion gen = new xact_CP_PackageVersion();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        System.assertEquals('', html, 'Should return empty string when no settings exist');
    }

    @isTest
    static void testGetHTML_nullVersion() {
        xact_CP_TestDataFactory.createEnvironmentSettings(null);

        Test.startTest();
        xact_CP_PackageVersion gen = new xact_CP_PackageVersion();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        System.assertEquals('', html, 'Should return empty string when version is null');
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_PackageVersion gen = new xact_CP_PackageVersion();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }
}
