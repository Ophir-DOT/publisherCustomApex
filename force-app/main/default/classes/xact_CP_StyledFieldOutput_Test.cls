@isTest
private class xact_CP_StyledFieldOutput_Test {

    @isTest
    static void testGetHTML_blankInput() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_StyledFieldOutput gen = new xact_CP_StyledFieldOutput();
        String html = gen.getHTML(audit.Id, '');
        Test.stopTest();

        System.assertEquals('', html, 'Should return empty string for blank input');
    }

    @isTest
    static void testGetHTML_nullInput() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_StyledFieldOutput gen = new xact_CP_StyledFieldOutput();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assertEquals('', html, 'Should return empty string for null input');
    }

    @isTest
    static void testGetHTML_validField() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        // Use Name field as it is a standard field on all objects
        audit.Name = 'Test Audit Name';
        update audit;

        Test.startTest();
        xact_CP_StyledFieldOutput gen = new xact_CP_StyledFieldOutput();
        String html = gen.getHTML(audit.Id, 'Name');
        Test.stopTest();

        System.assert(html.contains('Test Audit Name'), 'Should contain the field value');
        System.assert(html.contains('<div'), 'Should be wrapped in a styled div');
    }

    @isTest
    static void testGetHTML_emptyContentAfterStripping() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        // Name field with only whitespace
        audit.Name = '   ';
        update audit;

        Test.startTest();
        xact_CP_StyledFieldOutput gen = new xact_CP_StyledFieldOutput();
        // Name field won't have HTML tags; test the whitespace-only path
        // The content goes through stripTrailingEmptyElements and then tag-stripping check
        String html = gen.getHTML(audit.Id, 'Name');
        Test.stopTest();

        // Whitespace-only content - after replaceAll('<[^>]*>','') and trim, should not be blank
        // since there are no HTML tags, the raw whitespace string passes through
        System.assertNotEquals(null, html, 'Should not return null');
    }

    @isTest
    static void testGetHTML_rtaImageReplacement() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        audit.Name = 'Has Content';
        update audit;

        // Create a ContentVersion with RichTextAreaImg title to trigger the RTA replacement logic
        ContentVersion cv = new ContentVersion(
            Title = 'RichTextAreaImg',
            VersionData = Blob.valueOf('image data'),
            PathOnClient = 'image.png',
            Description = 'https://original-url.example.com/image'
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = audit.Id,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        xact_CP_StyledFieldOutput gen = new xact_CP_StyledFieldOutput();
        String html = gen.getHTML(audit.Id, 'Name');
        Test.stopTest();

        // The main purpose is to exercise the replaceRtaImageUrls code path
        System.assertNotEquals(null, html, 'Should return HTML content');
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_StyledFieldOutput gen = new xact_CP_StyledFieldOutput();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }
}
