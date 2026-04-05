@isTest
private class xact_CP_SigSupReportCtrl_Test {

    @isTest
    static void testConstructor_withTransitions() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        String shortId = String.valueOf(audit.Id).abbreviate(15);

        CompSuite__Transition_Audit_Trail__c t1 = xact_CP_TestDataFactory.createTransitionAuditTrail(shortId, 'Trail-One');
        CompSuite__Transition_Audit_Trail__c t2 = xact_CP_TestDataFactory.createTransitionAuditTrail(shortId, 'Trail-Two');
        if (t1 == null || t2 == null) return; // Skip if managed trigger blocks insert

        PageReference pageRef = Page.xact_CP_Custom_Signature_sup_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_sup_report_Ctrl ctrl = new xact_CP_Custom_Signature_sup_report_Ctrl();
        Test.stopTest();

        System.assertEquals(1, ctrl.signatureObjectList.size(), 'Should have exactly 1 signature (last record only)');
        System.assertNotEquals(null, ctrl.pageSize, 'Page size should be set');
    }

    @isTest
    static void testConstructor_noTransitions() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_sup_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_sup_report_Ctrl ctrl = new xact_CP_Custom_Signature_sup_report_Ctrl();
        Test.stopTest();

        System.assertEquals(0, ctrl.signatureObjectList.size(), 'Should have no signatures');
    }

    @isTest
    static void testConstructor_positiveTimezone() {
        xact_CP_TestDataFactory.createAsposeUtils('PdfTimeZone', '5');
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_sup_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_sup_report_Ctrl ctrl = new xact_CP_Custom_Signature_sup_report_Ctrl();
        Test.stopTest();

        System.assertEquals(5, ctrl.intGmt, 'Should have positive timezone');
        System.assert(ctrl.strGmt.contains('GMT+5'), 'Should format positive timezone');
    }

    @isTest
    static void testConstructor_negativeTimezone() {
        xact_CP_TestDataFactory.createAsposeUtils('PdfTimeZone', '-8');
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_sup_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_sup_report_Ctrl ctrl = new xact_CP_Custom_Signature_sup_report_Ctrl();
        Test.stopTest();

        System.assertEquals(-8, ctrl.intGmt, 'Should have negative timezone');
        System.assert(ctrl.strGmt.contains('GMT-8'), 'Should format negative timezone');
    }

    @isTest
    static void testConstructor_zeroTimezone() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_sup_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_sup_report_Ctrl ctrl = new xact_CP_Custom_Signature_sup_report_Ctrl();
        Test.stopTest();

        System.assertEquals(0, ctrl.intGmt, 'Should default to 0');
        System.assertEquals('(GMT)', ctrl.strGmt, 'Should format as (GMT)');
    }

    @isTest
    static void testSignatureObject_compareTo() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();

        PageReference pageRef = Page.xact_CP_Custom_Signature_sup_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        xact_CP_Custom_Signature_sup_report_Ctrl ctrl = new xact_CP_Custom_Signature_sup_report_Ctrl();

        Test.startTest();
        DateTime fixedDate = DateTime.newInstance(2026, 1, 1, 12, 0, 0);
        xact_CP_Custom_Signature_sup_report_Ctrl.SignatureObject sig1 =
            new xact_CP_Custom_Signature_sup_report_Ctrl.SignatureObject('Action1', 'User1', 'Title1', fixedDate.addDays(-1));
        xact_CP_Custom_Signature_sup_report_Ctrl.SignatureObject sig2 =
            new xact_CP_Custom_Signature_sup_report_Ctrl.SignatureObject('Action2', 'User2', 'Title2', fixedDate);

        System.assertEquals(-1, sig1.compareTo(sig2), 'Earlier date should return -1');
        System.assertEquals(1, sig2.compareTo(sig1), 'Later date should return 1');
        System.assertEquals(0, sig1.compareTo(sig1), 'Same object should return 0');
        Test.stopTest();
    }

    @isTest
    static void testConstructor_trailWithDashInName() {
        CompSuite__Audit__c audit = xact_CP_TestDataFactory.createAudit();
        String shortId = String.valueOf(audit.Id).abbreviate(15);
        CompSuite__Transition_Audit_Trail__c trail = xact_CP_TestDataFactory.createTransitionAuditTrail(shortId, 'Action-Approved');
        if (trail == null) return;

        PageReference pageRef = Page.xact_CP_Custom_Signature_sup_report_VF;
        pageRef.getParameters().put('Id', String.valueOf(audit.Id));
        pageRef.getParameters().put('pageSize', '612;792');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        xact_CP_Custom_Signature_sup_report_Ctrl ctrl = new xact_CP_Custom_Signature_sup_report_Ctrl();
        Test.stopTest();

        System.assertEquals(1, ctrl.signatureObjectList.size(), 'Should have 1 signature');
        System.assert(ctrl.signatureObjectList[0].actionName.contains('-'), 'Should use trail Name when it contains a dash');
    }
}