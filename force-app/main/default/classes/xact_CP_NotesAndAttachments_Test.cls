/**
 * @description       : Test class for xact_CP_NotesAndAttachments
 * @author            : Ophir Peleg
 * @last modified on  : 29-03-2026
 * @last modified by  : Ophir Peleg
 **/
@isTest
private class xact_CP_NotesAndAttachments_Test {

    @isTest
    static void testGetHTML_blankRecordId() {
        Test.startTest();
        xact_CP_NotesAndAttachments gen = new xact_CP_NotesAndAttachments();
        String html = gen.getFormattedData('', null);
        Test.stopTest();

        System.assertEquals('', html, 'Should return empty string for blank record ID');
    }

    @isTest
    static void testGetHTML_noNotesNoAttachments() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        Test.startTest();
        xact_CP_NotesAndAttachments gen = new xact_CP_NotesAndAttachments();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assertEquals('', html, 'Should return empty string when no notes or attachments');
    }

    @isTest
    static void testGetHTML_withNotes() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        xact_CP_TestDataFactory.createNoteForRecord(audit.Id, 'Test Note', 'Note body text');

        Test.startTest();
        xact_CP_NotesAndAttachments gen = new xact_CP_NotesAndAttachments();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Notes'), 'Should contain Notes section header');
        System.assert(html.contains('Test Note'), 'Should contain note title');
        System.assert(html.contains('Note body text'), 'Should contain note body');
    }

    @isTest
    static void testGetHTML_withAttachments() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        xact_CP_TestDataFactory.createFileForRecord(audit.Id, 'TestFile', 'File content here');

        Test.startTest();
        xact_CP_NotesAndAttachments gen = new xact_CP_NotesAndAttachments();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Attachments'), 'Should contain Attachments section header');
        System.assert(html.contains('TestFile'), 'Should contain file name');
    }

    @isTest
    static void testGetHTML_withBothNotesAndAttachments() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        xact_CP_TestDataFactory.createNoteForRecord(audit.Id, 'My Note', 'Body');
        xact_CP_TestDataFactory.createFileForRecord(audit.Id, 'MyFile', 'Content');

        Test.startTest();
        xact_CP_NotesAndAttachments gen = new xact_CP_NotesAndAttachments();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('Notes'), 'Should contain Notes section');
        System.assert(html.contains('Attachments'), 'Should contain Attachments section');
    }

    @isTest
    static void testGetHTML_noteWithNewlines() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        xact_CP_TestDataFactory.createNoteForRecord(audit.Id, 'MultiLine', 'Line1\nLine2');

        Test.startTest();
        xact_CP_NotesAndAttachments gen = new xact_CP_NotesAndAttachments();
        String html = gen.getHTML(audit.Id, null);
        Test.stopTest();

        System.assert(html.contains('<br/>'), 'Should convert newlines to br tags in note body');
    }

    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        xact_CP_NotesAndAttachments.NotesAndAttachmentsData data = new xact_CP_NotesAndAttachments.NotesAndAttachmentsData();
        System.assertEquals(false, data.hasData(), 'Empty data should return false for hasData');

        data.notes.add(new xact_CP_NotesAndAttachments.NoteWrapper('Title', 'Body', DateTime.now(), 'User'));
        System.assertEquals(true, data.hasData(), 'Should return true when notes exist');

        xact_CP_NotesAndAttachments.AttachmentWrapper att = new xact_CP_NotesAndAttachments.AttachmentWrapper(
            'File', 'PDF', 'pdf', 1024, DateTime.now(), 'User'
        );
        System.assertEquals('File', att.title, 'Attachment title should match');
        Test.stopTest();
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        xact_CP_NotesAndAttachments gen = new xact_CP_NotesAndAttachments();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }
}
