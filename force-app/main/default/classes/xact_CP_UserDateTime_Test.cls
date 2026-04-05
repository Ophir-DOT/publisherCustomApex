/**
 * @description       : Test class for xact_CP_UserDateTime
 * @author            : Ophir Peleg
 * @last modified on  : 05-04-2026
 * @last modified by  : Ophir Peleg
 **/
@isTest
private class xact_CP_UserDateTime_Test {

    @isTest
    static void testGetHTML_returnsFormattedDateTime() {
        Test.startTest();
        xact_CP_UserDateTime gen = new xact_CP_UserDateTime();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        System.assert(html.contains('<span'), 'HTML should contain a span element');
        System.assert(html.contains('\u2013'), 'HTML should contain en-dash separators');
        System.assert(html.contains(UserInfo.getTimeZone().getID()), 'HTML should contain the user timezone ID');
    }

    @isTest
    static void testGetHTML_matchesExpectedFormat() {
        Test.startTest();
        xact_CP_UserDateTime gen = new xact_CP_UserDateTime();
        String html = gen.getHTML(null, null);
        Test.stopTest();

        // Extract text between span tags
        String content = html.substringAfter('>').substringBefore('</span>');
        // Format: yyyy-MM-dd – HH:mm:ss – TimeZoneId
        String[] parts = content.split(' \u2013 ');
        System.assertEquals(3, parts.size(), 'Should have 3 parts separated by en-dashes: ' + content);
        // Date part should match yyyy-MM-dd pattern (10 chars)
        System.assertEquals(10, parts[0].trim().length(), 'Date part should be 10 characters');
        // Time part should match HH:mm:ss pattern (8 chars)
        System.assertEquals(8, parts[1].trim().length(), 'Time part should be 8 characters');
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_UserDateTime gen = new xact_CP_UserDateTime();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }
}
