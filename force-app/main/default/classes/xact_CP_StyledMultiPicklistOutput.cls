/**
 * @description       : Renders a multipicklist field from a CompSuite__Audit__c record with each
 *                      selected value on its own line. The field API name is passed via Custom Input.
 *                      Applies standardized font styling consistent with xact_CP_StyledFieldOutput.
 * @author            : Ophir Oren
 * @last modified on  : 2026-02-19
 * @last modified by  : Claude
 **/
global with sharing class xact_CP_StyledMultiPicklistOutput implements CompSuite.CP_DynamicContentGenerator {

    private static final String FONT_FAMILY = '\'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif';
    private static final String FONT_SIZE = '10pt';

    public String getJSON(Id recordId, String input) {
        return null;
    }

    public String getHTML(Id recordId, String input) {
        if (String.isBlank(input)) {
            return '';
        }

        String fieldApi = input.trim();

        String query = 'SELECT ' + String.escapeSingleQuotes(fieldApi)
                     + ' FROM CompSuite__Audit__c'
                     + ' WHERE Id = :recordId'
                     + ' WITH SECURITY_ENFORCED'
                     + ' LIMIT 1';

        List<SObject> records = Database.query(query);

        if (records.isEmpty()) {
            return '';
        }

        Object fieldValue = records[0].get(fieldApi);
        if (fieldValue == null) {
            return '';
        }

        String rawValue = String.valueOf(fieldValue);
        if (String.isBlank(rawValue)) {
            return '';
        }

        // Multipicklist values are semicolon-separated
        List<String> values = rawValue.split(';');

        String html = '<div style="font-family: ' + FONT_FAMILY + ' !important; '
                    + 'font-size: ' + FONT_SIZE + ' !important; '
                    + 'width: 100%; margin: 0; padding: 0;">';

        for (Integer i = 0; i < values.size(); i++) {
            String val = values[i].trim();
            if (String.isNotBlank(val)) {
                if (i > 0) {
                    html += '<br/>';
                }
                html += val.escapeHtml4();
            }
        }

        html += '</div>';

        return html;
    }
}