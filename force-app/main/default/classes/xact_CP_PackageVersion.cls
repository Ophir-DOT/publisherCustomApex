/**
 * @description       : Dynamic class to return CompSuite Package Version
 * @author            : Claude
 * @group             :
 * @last modified on  : 02-05-2026
 * @last modified by  : Claude
 **/
global with sharing class xact_CP_PackageVersion implements CompSuite.CP_DynamicContentGenerator {
    private static final String FONT_FAMILY = '\'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif';
    private static final String FONT_SIZE = '8pt';

    public string getJSON(Id recordId, String input) {
        return null;
    }

    public string getHTML(Id recordId, String input) {
        List<CompSuite__Environment_Settings__c> settings = [
            SELECT CompSuite__Package_Version__c
            FROM CompSuite__Environment_Settings__c
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (settings.isEmpty() || settings[0].CompSuite__Package_Version__c == null) {
            return '';
        }

        String version = settings[0].CompSuite__Package_Version__c;
        return '<span style="font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + ';">' + version + '</span>';
    }
}
