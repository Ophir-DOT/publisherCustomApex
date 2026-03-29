/**
 * @description Test data factory for xact Content Publisher custom output classes.
 *              Provides reusable methods for creating CompSuite managed package test records.
 */
@isTest
public class xact_CP_TestDataFactory {

    /**
     * Creates a CompSuite__Environment_Settings__c record with specified package version.
     */
    public static CompSuite__Environment_Settings__c createEnvironmentSettings(String version) {
        CompSuite__Environment_Settings__c settings = new CompSuite__Environment_Settings__c(
            Name = 'TestSettings',
            CompSuite__Package_Version__c = version
        );
        insert settings;
        return settings;
    }

    /**
     * Creates a CompSuite__Aspose_Utils__c custom setting record.
     */
    public static CompSuite__Aspose_Utils__c createAsposeUtils(String name, String value) {
        CompSuite__Aspose_Utils__c setting = new CompSuite__Aspose_Utils__c(
            Name = name,
            CompSuite__value__c = value
        );
        insert setting;
        return setting;
    }

    /**
     * Creates a CompSuite__Audit__c record.
     */
    public static CompSuite__Audit__c createAudit() {
        CompSuite__Audit__c audit = new CompSuite__Audit__c();
        insert audit;
        return audit;
    }

    /**
     * Creates a CompSuite__Observation__c (Finding) record linked to an Audit.
     */
    public static CompSuite__Observation__c createObservation(Id auditId, String findingId, String description, Date obsDate) {
        CompSuite__Observation__c obs = new CompSuite__Observation__c(
            CompSuite__Audit__c = auditId,
            CompSuite__Observation_Description__c = description,
            CompSuite__Observation_Date__c = obsDate
        );
        insert obs;
        return obs;
    }

    /**
     * Creates a CompSuite__Deviation__c (NC) record linked to a Finding.
     */
    public static CompSuite__Deviation__c createDeviation(Id findingId) {
        CompSuite__Deviation__c dev = new CompSuite__Deviation__c(
            Xact_Finding__c = findingId
        );
        insert dev;
        return dev;
    }

    /**
     * Creates a CompSuite__Deviation__c without a Finding link (for junction-only scenarios).
     */
    public static CompSuite__Deviation__c createDeviationUnlinked() {
        CompSuite__Deviation__c dev = new CompSuite__Deviation__c();
        insert dev;
        return dev;
    }

    /**
     * Creates a CompSuite__Immediate_Action__c record.
     */
    public static CompSuite__Immediate_Action__c createImmediateAction() {
        CompSuite__Immediate_Action__c ia = new CompSuite__Immediate_Action__c();
        insert ia;
        return ia;
    }

    /**
     * Creates a CompSuite__CAPA_Plan__c record.
     */
    public static CompSuite__CAPA_Plan__c createCAPAPlan() {
        CompSuite__CAPA_Plan__c plan = new CompSuite__CAPA_Plan__c();
        insert plan;
        return plan;
    }

    /**
     * Creates a CompSuite__CAPA__c record linked to a CAPA Plan.
     */
    public static CompSuite__CAPA__c createCAPA(Id capaPlanId) {
        CompSuite__CAPA__c capa = new CompSuite__CAPA__c(
            CAPA_Plan__c = capaPlanId
        );
        insert capa;
        return capa;
    }

    /**
     * Creates a CompSuite__CAPA__c record without a CAPA Plan (for direct junction linking).
     */
    public static CompSuite__CAPA__c createCAPAUnlinked() {
        CompSuite__CAPA__c capa = new CompSuite__CAPA__c();
        insert capa;
        return capa;
    }

    /**
     * Creates a CompSuite__Relation4__c junction record linking source to destination.
     */
    public static CompSuite__Relation4__c createRelation4(Id sourceId, Id destId, String destObjectApi) {
        CompSuite__Relation4__c rel = new CompSuite__Relation4__c(
            CompSuite__Source_Record_ID__c = String.valueOf(sourceId),
            CompSuite__Destination_Record_ID__c = String.valueOf(destId),
            CompSuite__Destination_Object_API_Name__c = destObjectApi
        );
        insert rel;
        return rel;
    }

    /**
     * Initializes managed package custom settings and states required for Protocol tests.
     * Must be called before creating Protocol Execution records.
     */
    public static void setupProtocolTestData() {
        CompSuite.Test_Common.createAllCustomSettings();
        TestDataUtility.CreateAllStates();
    }

    /**
     * Creates a CompSuite__Validation_Protocol__c record required as parent for Protocol Executions.
     */
    public static CompSuite__Validation_Protocol__c createValidationProtocol() {
        CompSuite__Validation_Protocol__c protocol = new CompSuite__Validation_Protocol__c(
            Name = 'Test Protocol',
            CompSuite__Active__c = true,
            CompSuite__Under_Amendment__c = true,
            CompSuite__Elements_Per_Page__c = 1,
            CompSuite__Version__c = 1
        );
        insert protocol;
        update protocol;
        return protocol;
    }

    /**
     * Creates a CompSuite__Protocol_Execution__c record with proper setup.
     */
    public static CompSuite__Protocol_Execution__c createProtocolExecution(Id protocolId, String recordTypeName) {
        CompSuite__Protocol_Execution__c pe = new CompSuite__Protocol_Execution__c(
            Name = 'test execution',
            CompSuite__Related_Protocol__c = protocolId,
            CompSuite__Exam_Date__c = System.now(),
            CompSuite__Page_E_From_Protocol__c = 2,
            CompSuite__Completed__c = true,
            RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Execution__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId()
        );
        insert pe;
        return pe;
    }

    /**
     * Creates a CompSuite__Protocol_Execution__c linked to an Audit.
     */
    public static CompSuite__Protocol_Execution__c createProtocolExecution(Id protocolId, String recordTypeName, Id auditId) {
        CompSuite__Protocol_Execution__c pe = new CompSuite__Protocol_Execution__c(
            Name = 'test execution',
            CompSuite__Related_Protocol__c = protocolId,
            CompSuite__Exam_Date__c = System.now(),
            CompSuite__Page_E_From_Protocol__c = 2,
            CompSuite__Completed__c = true,
            CompSuite__Audit__c = auditId,
            RecordTypeId = Schema.SObjectType.CompSuite__Protocol_Execution__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId()
        );
        insert pe;
        return pe;
    }

    /**
     * Creates a CompSuite__Protocol_Element__c record with specified RecordType name and order.
     */
    public static CompSuite__Protocol_Element__c createProtocolElement(Id protocolId, String recordTypeName, Integer orderNum) {
        Id rtId = getProtocolElementRecordTypeId(recordTypeName);
        CompSuite__Protocol_Element__c elem = new CompSuite__Protocol_Element__c(
            Name = 'test protocol element',
            RecordTypeId = rtId,
            CompSuite__Validation_Protocol__c = protocolId,
            CompSuite__Order__c = orderNum,
            CompSuite__Start_Version__c = 0,
            CompSuite__Choices__c = 'Yes\nNo\n',
            CompSuite__Test_Procedure__c = 'Test Procedure',
            CompSuite__Rich_Description__c = 'Test Description'
        );
        insert elem;
        return elem;
    }

    /**
     * Creates a CompSuite__Protocol_Element__c with additional field values.
     */
    public static CompSuite__Protocol_Element__c createProtocolElement(Id protocolId, String recordTypeName, Integer orderNum, Map<String, Object> extras) {
        Id rtId = getProtocolElementRecordTypeId(recordTypeName);
        CompSuite__Protocol_Element__c elem = new CompSuite__Protocol_Element__c(
            Name = 'test protocol element',
            RecordTypeId = rtId,
            CompSuite__Validation_Protocol__c = protocolId,
            CompSuite__Order__c = orderNum,
            CompSuite__Start_Version__c = 0,
            CompSuite__Choices__c = 'Yes\nNo\n',
            CompSuite__Test_Procedure__c = 'Test Procedure',
            CompSuite__Rich_Description__c = 'Test Description'
        );
        if (extras != null) {
            for (String fieldName : extras.keySet()) {
                elem.put(fieldName, extras.get(fieldName));
            }
        }
        insert elem;
        return elem;
    }

    /**
     * Creates a CompSuite__Execution_Element__c record linking to Protocol Execution and Protocol Element.
     */
    public static CompSuite__Execution_Element__c createExecutionElement(Id protocolExecId, Id protocolElementId) {
        CompSuite__Execution_Element__c ee = new CompSuite__Execution_Element__c(
            CompSuite__Protocol_Execution__c = protocolExecId,
            CompSuite__Protocol_Element__c = protocolElementId
        );
        insert ee;
        return ee;
    }

    /**
     * Creates a CompSuite__Execution_Element__c with additional field values.
     */
    public static CompSuite__Execution_Element__c createExecutionElement(Id protocolExecId, Id protocolElementId, Map<String, Object> extras) {
        CompSuite__Execution_Element__c ee = new CompSuite__Execution_Element__c(
            CompSuite__Protocol_Execution__c = protocolExecId,
            CompSuite__Protocol_Element__c = protocolElementId
        );
        if (extras != null) {
            for (String fieldName : extras.keySet()) {
                ee.put(fieldName, extras.get(fieldName));
            }
        }
        insert ee;
        return ee;
    }

    /**
     * Creates a CompSuite__Transition_Audit_Trail__c record.
     */
    public static CompSuite__Transition_Audit_Trail__c createTransitionAuditTrail(String objectId, String trailName) {
        CompSuite__Transition_Audit_Trail__c trail = new CompSuite__Transition_Audit_Trail__c(
            CompSuite__Object_Id__c = objectId,
            Name = trailName
        );
        try {
            insert trail;
        } catch (DmlException e) {
            // Managed package trigger may block insert; return null so tests can skip
            return null;
        }
        return trail;
    }

    /**
     * Creates a classic Note record attached to a parent record.
     */
    public static Note createNoteForRecord(Id parentId, String title, String body) {
        Note n = new Note(
            ParentId = parentId,
            Title = title,
            Body = body
        );
        insert n;
        return n;
    }

    /**
     * Creates a ContentVersion + ContentDocumentLink (File) attached to a record.
     * Returns the inserted ContentVersion (re-queried to get ContentDocumentId).
     */
    public static ContentVersion createFileForRecord(Id linkedEntityId, String title, String fileBody) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            VersionData = Blob.valueOf(fileBody),
            PathOnClient = title + '.txt'
        );
        insert cv;

        // Re-query to get ContentDocumentId
        cv = [SELECT Id, ContentDocumentId, Title, FileType, FileExtension, ContentSize, CreatedDate
              FROM ContentVersion WHERE Id = :cv.Id];

        // Create link to the record
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = linkedEntityId,
            ShareType = 'V'
        );
        insert cdl;

        return cv;
    }

    /**
     * Gets the RecordType Id for a CompSuite__Protocol_Element__c by name.
     */
    public static Id getProtocolElementRecordTypeId(String recordTypeName) {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'CompSuite__Protocol_Element__c'
            AND Name = :recordTypeName
            LIMIT 1
        ];
        if (rts.isEmpty()) {
            return null;
        }
        return rts[0].Id;
    }

    /**
     * Gets all available RecordType names for CompSuite__Protocol_Element__c.
     */
    public static Map<String, Id> getProtocolElementRecordTypes() {
        Map<String, Id> rtMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType = 'CompSuite__Protocol_Element__c']) {
            rtMap.put(rt.Name, rt.Id);
        }
        return rtMap;
    }
}
