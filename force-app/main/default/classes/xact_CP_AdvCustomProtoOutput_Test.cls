/**
 * @description       : Test class for Xact_CP_Advanced_Custom_ProtocolOutput
 * @author            : Ophir Peleg
 * @last modified on  : 29-03-2026
 * @last modified by  : Ophir Peleg
 **/
@isTest
private class xact_CP_AdvCustomProtoOutput_Test {

    @testSetup
    static void setupmethod() {
        CompSuite.Test_Common.createAllCustomSettings();
        TestDataUtility.CreateAllStates();

        CompSuite__Validation_Protocol__c protocol = new CompSuite__Validation_Protocol__c();
        protocol.Name = 'Test Protocol';
        protocol.CompSuite__Active__c = true;
        protocol.CompSuite__Under_Amendment__c = true;
        protocol.CompSuite__Elements_Per_Page__c = 1;
        protocol.CompSuite__Version__c = 1;
        insert protocol;
        update protocol;

        // Training Effectiveness PE (Advanced output takes PE Id directly, no Audit link needed)
        CompSuite__Protocol_Execution__c pex = new CompSuite__Protocol_Execution__c();
        pex.Name = 'adv train execution';
        pex.CompSuite__Exam_Date__c = System.now();
        pex.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Execution__c.getRecordTypeInfosByName().get('Training Effectiveness').getRecordTypeId();
        pex.CompSuite__Related_Protocol__c = protocol.Id;
        pex.CompSuite__Page_E_From_Protocol__c = 2;
        pex.CompSuite__Completed__c = true;
        insert pex;

        // Electronic Form/Protocol PE
        CompSuite__Protocol_Execution__c pex2 = new CompSuite__Protocol_Execution__c();
        pex2.Name = 'adv form execution';
        pex2.CompSuite__Exam_Date__c = System.now();
        pex2.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Execution__c.getRecordTypeInfosByName().get('Electronic Form/Protocol').getRecordTypeId();
        pex2.CompSuite__Related_Protocol__c = protocol.Id;
        pex2.CompSuite__Page_E_From_Protocol__c = 2;
        pex2.CompSuite__Completed__c = true;
        insert pex2;

        // Table element
        CompSuite__Protocol_Element__c peTable = new CompSuite__Protocol_Element__c();
        peTable.Name = 'table element';
        peTable.CompSuite__Validation_Protocol__c = protocol.Id;
        peTable.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Element__c.getRecordTypeInfosByName().get('Table').getRecordTypeId();
        peTable.CompSuite__Order__c = 1;
        peTable.CompSuite__Start_Version__c = 0;
        peTable.CompSuite__Test_Procedure__c = 'Table Question';
        peTable.CompSuite__Rich_Description__c = 'Table Desc';
        peTable.CompSuite__Choices__c = 'Yes\nNo\n';
        insert peTable;

        // Numeric Value child of Table
        CompSuite__Protocol_Element__c peNum = new CompSuite__Protocol_Element__c();
        peNum.Name = 'numeric child';
        peNum.CompSuite__Validation_Protocol__c = protocol.Id;
        peNum.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Element__c.getRecordTypeInfosByName().get('Numeric Value').getRecordTypeId();
        peNum.CompSuite__Order__c = 2;
        peNum.CompSuite__Start_Version__c = 0;
        peNum.CompSuite__Table_Element__c = peTable.Id;
        peNum.CompSuite__Test_Procedure__c = 'Numeric in Table';
        peNum.CompSuite__Rich_Description__c = 'Num Desc';
        peNum.CompSuite__Choices__c = 'Yes\nNo\n';
        insert peNum;

        // Multi Picklist element
        CompSuite__Protocol_Element__c peMulti = new CompSuite__Protocol_Element__c();
        peMulti.Name = 'multi element';
        peMulti.CompSuite__Validation_Protocol__c = protocol.Id;
        peMulti.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Element__c.getRecordTypeInfosByName().get('Multi Picklist').getRecordTypeId();
        peMulti.CompSuite__Order__c = 3;
        peMulti.CompSuite__Start_Version__c = 0;
        peMulti.CompSuite__Test_Procedure__c = 'Multi Q';
        peMulti.CompSuite__Rich_Description__c = 'Multi Desc';
        peMulti.CompSuite__Choices__c = 'Yes\nNo\n';
        insert peMulti;

        // Text Only element
        CompSuite__Protocol_Element__c peText = new CompSuite__Protocol_Element__c();
        peText.Name = 'text only element';
        peText.CompSuite__Validation_Protocol__c = protocol.Id;
        peText.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Element__c.getRecordTypeInfosByName().get('Text Only').getRecordTypeId();
        peText.CompSuite__Order__c = 4;
        peText.CompSuite__Start_Version__c = 0;
        peText.CompSuite__Test_Procedure__c = 'Text Only Q';
        peText.CompSuite__Rich_Description__c = 'Text Only Desc';
        peText.CompSuite__Choices__c = 'Yes\nNo\n';
        insert peText;

        // Test Step element
        CompSuite__Protocol_Element__c peStep = new CompSuite__Protocol_Element__c();
        peStep.Name = 'test step element';
        peStep.CompSuite__Validation_Protocol__c = protocol.Id;
        peStep.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Element__c.getRecordTypeInfosByName().get('Test Step').getRecordTypeId();
        peStep.CompSuite__Order__c = 5;
        peStep.CompSuite__Start_Version__c = 0;
        peStep.CompSuite__Test_Procedure__c = 'Verify step';
        peStep.CompSuite__Acceptance_Criteria__c = 'Expected result';
        peStep.CompSuite__Rich_Description__c = 'Step Desc';
        peStep.CompSuite__Choices__c = 'Yes\nNo\n';
        insert peStep;

        // Free Text element with layout, comments and signature
        CompSuite__Protocol_Element__c peFree = new CompSuite__Protocol_Element__c();
        peFree.Name = 'free text element';
        peFree.CompSuite__Validation_Protocol__c = protocol.Id;
        peFree.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Element__c.getRecordTypeInfosByName().get('Free Text').getRecordTypeId();
        peFree.CompSuite__Order__c = 6;
        peFree.CompSuite__Start_Version__c = 0;
        peFree.CompSuite__Test_Procedure__c = 'Enter text';
        peFree.CompSuite__Display_Comments__c = true;
        peFree.CompSuite__Layout__c = '1-of-2';
        peFree.CompSuite__Require_Signature__c = true;
        peFree.CompSuite__Rich_Description__c = 'Free Desc';
        peFree.CompSuite__Choices__c = 'Yes\nNo\n';
        insert peFree;

        // Single Picklist element
        CompSuite__Protocol_Element__c peSingle = new CompSuite__Protocol_Element__c();
        peSingle.Name = 'single picklist element';
        peSingle.CompSuite__Validation_Protocol__c = protocol.Id;
        peSingle.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Element__c.getRecordTypeInfosByName().get('Single Picklist').getRecordTypeId();
        peSingle.CompSuite__Order__c = 7;
        peSingle.CompSuite__Start_Version__c = 0;
        peSingle.CompSuite__Test_Procedure__c = 'Pick one';
        peSingle.CompSuite__Layout__c = '1-of-2';
        peSingle.CompSuite__Rich_Description__c = 'Single Desc';
        peSingle.CompSuite__Choices__c = 'Yes\nNo\n';
        insert peSingle;

        // Radio Button Vertical element
        CompSuite__Protocol_Element__c peRadio = new CompSuite__Protocol_Element__c();
        peRadio.Name = 'radio element';
        peRadio.CompSuite__Validation_Protocol__c = protocol.Id;
        peRadio.RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Element__c.getRecordTypeInfosByName().get('Radio Button Vertical').getRecordTypeId();
        peRadio.CompSuite__Order__c = 8;
        peRadio.CompSuite__Start_Version__c = 0;
        peRadio.CompSuite__Test_Procedure__c = 'Select radio';
        peRadio.CompSuite__Rich_Description__c = 'Radio Desc';
        peRadio.CompSuite__Choices__c = 'Yes\nNo\n';
        insert peRadio;

        // Execution Elements for Training PE (direct assignment like reference test)
        CompSuite__Execution_Element__c ee1 = new CompSuite__Execution_Element__c();
        ee1.CompSuite__Protocol_Execution__c = pex.Id;
        ee1.CompSuite__Protocol_Element__c = peTable.Id;
        ee1.CompSuite__Score__c = 1;
        ee1.CompSuite__Free_Text__c = 'Done';
        ee1.CompSuite__Selected_Multi_Options__c = 'Yes';
        insert ee1;

        CompSuite__Execution_Element__c ee2 = new CompSuite__Execution_Element__c();
        ee2.CompSuite__Protocol_Execution__c = pex.Id;
        ee2.CompSuite__Protocol_Element__c = peNum.Id;
        ee2.CompSuite__Score__c = 1;
        ee2.CompSuite__Free_Text__c = '42';
        insert ee2;

        CompSuite__Execution_Element__c ee3 = new CompSuite__Execution_Element__c();
        ee3.CompSuite__Protocol_Execution__c = pex.Id;
        ee3.CompSuite__Protocol_Element__c = peMulti.Id;
        ee3.CompSuite__Selected_Multi_Options__c = 'Yes';
        ee3.CompSuite__Score__c = 1;
        ee3.CompSuite__Free_Text__c = 'Done';
        insert ee3;

        CompSuite__Execution_Element__c ee4 = new CompSuite__Execution_Element__c();
        ee4.CompSuite__Protocol_Execution__c = pex.Id;
        ee4.CompSuite__Protocol_Element__c = peText.Id;
        ee4.CompSuite__Score__c = 1;
        ee4.CompSuite__Free_Text__c = 'Done';
        insert ee4;

        CompSuite__Execution_Element__c ee5 = new CompSuite__Execution_Element__c();
        ee5.CompSuite__Protocol_Execution__c = pex.Id;
        ee5.CompSuite__Protocol_Element__c = peStep.Id;
        ee5.CompSuite__Actual_Result__c = 'Actual result';
        ee5.CompSuite__Single_Selected_Option__c = 'Pass';
        ee5.CompSuite__Date__c = Date.today();
        ee5.CompSuite__Score__c = 1;
        ee5.CompSuite__Free_Text__c = 'Done';
        insert ee5;

        CompSuite__Execution_Element__c ee6 = new CompSuite__Execution_Element__c();
        ee6.CompSuite__Protocol_Execution__c = pex.Id;
        ee6.CompSuite__Protocol_Element__c = peFree.Id;
        ee6.CompSuite__Free_Text__c = 'Free text answer';
        ee6.CompSuite__Comments__c = 'Comment text';
        ee6.CompSuite__Score__c = 1;
        insert ee6;

        CompSuite__Execution_Element__c ee7 = new CompSuite__Execution_Element__c();
        ee7.CompSuite__Protocol_Execution__c = pex.Id;
        ee7.CompSuite__Protocol_Element__c = peSingle.Id;
        ee7.CompSuite__Single_Selected_Option__c = 'Yes';
        ee7.CompSuite__Score__c = 1;
        ee7.CompSuite__Free_Text__c = 'Done';
        insert ee7;

        CompSuite__Execution_Element__c ee8 = new CompSuite__Execution_Element__c();
        ee8.CompSuite__Protocol_Execution__c = pex.Id;
        ee8.CompSuite__Protocol_Element__c = peRadio.Id;
        ee8.CompSuite__Selected_Radio_Button__c = '1';
        ee8.CompSuite__Score__c = 1;
        ee8.CompSuite__Free_Text__c = 'Done';
        insert ee8;

        // Execution Element for Form PE
        CompSuite__Execution_Element__c ee9 = new CompSuite__Execution_Element__c();
        ee9.CompSuite__Protocol_Execution__c = pex2.Id;
        ee9.CompSuite__Protocol_Element__c = peFree.Id;
        ee9.CompSuite__Free_Text__c = 'Form answer';
        insert ee9;
    }

    @isTest
    static void testGetHTML_trainingEffectiveness() {
        CompSuite__Protocol_Execution__c pe = [
            SELECT Id FROM CompSuite__Protocol_Execution__c
            WHERE Name = 'adv train execution' LIMIT 1
        ];

        Test.startTest();
        Xact_CP_Advanced_Custom_ProtocolOutput gen = new Xact_CP_Advanced_Custom_ProtocolOutput();
        String html = gen.getHTML(pe.Id, null);
        Test.stopTest();

        System.assertNotEquals('', html, 'Should return HTML content');
        System.assertNotEquals(null, html, 'Should not be null');
    }

    @isTest
    static void testGetHTML_formExecution() {
        CompSuite__Protocol_Execution__c pe = [
            SELECT Id FROM CompSuite__Protocol_Execution__c
            WHERE Name = 'adv form execution' LIMIT 1
        ];

        Test.startTest();
        Xact_CP_Advanced_Custom_ProtocolOutput gen = new Xact_CP_Advanced_Custom_ProtocolOutput();
        String html = gen.getHTML(pe.Id, null);
        Test.stopTest();

        System.assertNotEquals('', html, 'Should return HTML for form execution');
    }

    @isTest
    static void testGetHTML_withWidthInput() {
        CompSuite__Protocol_Execution__c pe = [
            SELECT Id FROM CompSuite__Protocol_Execution__c
            WHERE Name = 'adv train execution' LIMIT 1
        ];

        Test.startTest();
        Xact_CP_Advanced_Custom_ProtocolOutput gen = new Xact_CP_Advanced_Custom_ProtocolOutput();
        String html = gen.getHTML(pe.Id, '900');
        Test.stopTest();

        System.assert(html.contains('900'), 'Should contain width value');
    }

    @isTest
    static void testGetJSON_returnsNull() {
        Test.startTest();
        Xact_CP_Advanced_Custom_ProtocolOutput gen = new Xact_CP_Advanced_Custom_ProtocolOutput();
        String json = gen.getJSON(null, null);
        Test.stopTest();

        System.assertEquals(null, json, 'getJSON should return null');
    }

    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        Xact_CP_Advanced_Custom_ProtocolOutput.WrpCmpContent wrp = new Xact_CP_Advanced_Custom_ProtocolOutput.WrpCmpContent();
        System.assertEquals(1, wrp.columnCount, 'Default columnCount should be 1');
        System.assertEquals(false, wrp.isTable, 'Default isTable should be false');

        Xact_CP_Advanced_Custom_ProtocolOutput.WrpSections section = new Xact_CP_Advanced_Custom_ProtocolOutput.WrpSections();
        System.assertEquals(1, section.sectionCount, 'Default sectionCount should be 1');
        System.assertNotEquals(null, section.lstwrp, 'lstwrp should be initialized');
        Test.stopTest();
    }
}
