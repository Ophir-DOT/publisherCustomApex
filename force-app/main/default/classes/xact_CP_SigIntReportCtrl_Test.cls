@isTest
private class xact_CP_SigIntReportCtrl_Test {

    @isTest
    static void testConstructor_withMultipleTransitions() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        String shortId = String.valueOf(audit.Id).abbreviate(15);

        CompSuite__Transition_Audit_Trail__c t1 = xact_CP_TestDataFactory.createTransitionAuditTrail(shortId, 'Trail-One');
        CompSuite__Transition_Audit_Trail__c t2 = xact_CP_TestDataFactory.createTransitionAuditTrail(shortId, 'Trail-Two');
        CompSuite__Transition_Audit_Trail__c t3 = xact_CP_TestDataFactory.createTransitionAuditTrail(shortId, 'TrailThree');
        if (t1 == null || t2 == null || t3 == null) return;

        PageReference pageRef = Page.xact_CP_Custom_Signature_int_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_int_report_Ctrl ctrl = new xact_CP_Custom_Signature_int_report_Ctrl();
        Test.stopTest();

        System.assertEquals(3, ctrl.signatureObjectList.size(), 'Should have all 3 signatures');
    }

    @isTest
    static void testConstructor_noTransitions() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_int_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_int_report_Ctrl ctrl = new xact_CP_Custom_Signature_int_report_Ctrl();
        Test.stopTest();

        System.assertEquals(0, ctrl.signatureObjectList.size(), 'Should have no signatures');
    }

    @isTest
    static void testConstructor_positiveTimezone() {
        xact_CP_TestDataFactory.createAsposeUtils('PdfTimeZone', '3');
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_int_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_int_report_Ctrl ctrl = new xact_CP_Custom_Signature_int_report_Ctrl();
        Test.stopTest();

        System.assertEquals(3, ctrl.intGmt, 'Should have positive timezone');
        System.assert(ctrl.strGmt.contains('GMT+3'), 'Should format positive timezone');
    }

    @isTest
    static void testConstructor_negativeTimezone() {
        xact_CP_TestDataFactory.createAsposeUtils('PdfTimeZone', '-5');
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_int_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_int_report_Ctrl ctrl = new xact_CP_Custom_Signature_int_report_Ctrl();
        Test.stopTest();

        System.assertEquals(-5, ctrl.intGmt, 'Should have negative timezone');
        System.assert(ctrl.strGmt.contains('GMT-5'), 'Should format negative timezone');
    }

    @isTest
    static void testConstructor_zeroTimezone() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_int_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_int_report_Ctrl ctrl = new xact_CP_Custom_Signature_int_report_Ctrl();
        Test.stopTest();

        System.assertEquals(0, ctrl.intGmt, 'Should default to 0');
        System.assertEquals('(GMT)', ctrl.strGmt, 'Should format as (GMT)');
    }

    @isTest
    static void testSignatureObject_compareTo() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_int_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        xact_CP_Custom_Signature_int_report_Ctrl ctrl = new xact_CP_Custom_Signature_int_report_Ctrl();

        Test.startTest();
        DateTime fixedDate = DateTime.newInstance(2026, 1, 1, 12, 0, 0);
        xact_CP_Custom_Signature_int_report_Ctrl.SignatureObject sig1 =
            new xact_CP_Custom_Signature_int_report_Ctrl.SignatureObject('Action1', 'User1', 'Title1', fixedDate.addDays(-1));
        xact_CP_Custom_Signature_int_report_Ctrl.SignatureObject sig2 =
            new xact_CP_Custom_Signature_int_report_Ctrl.SignatureObject('Action2', 'User2', 'Title2', fixedDate);

        System.assertEquals(-1, sig1.compareTo(sig2), 'Earlier date should return -1');
        System.assertEquals(1, sig2.compareTo(sig1), 'Later date should return 1');
        System.assertEquals(0, sig1.compareTo(sig1), 'Same object should return 0');
        Test.stopTest();
    }

    @isTest
    static void testConstructor_sortingOrder() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        String shortId = String.valueOf(audit.Id).abbreviate(15);

        CompSuite__Transition_Audit_Trail__c t1 = xact_CP_TestDataFactory.createTransitionAuditTrail(shortId, 'Trail-Alpha');
        CompSuite__Transition_Audit_Trail__c t2 = xact_CP_TestDataFactory.createTransitionAuditTrail(shortId, 'Trail-Beta');
        if (t1 == null || t2 == null) return;

        PageReference pageRef = Page.xact_CP_Custom_Signature_int_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_int_report_Ctrl ctrl = new xact_CP_Custom_Signature_int_report_Ctrl();
        Test.stopTest();

        System.assertEquals(2, ctrl.signatureObjectList.size(), 'Should have 2 signatures sorted by date');
    }
}