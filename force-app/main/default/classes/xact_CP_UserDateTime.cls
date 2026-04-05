/**
 * @description       : Dynamic class to return the current date/time in the running user's timezone
 * @author            : Ophir Peleg
 * @group             :
 * @last modified on  : 05-04-2026
 * @last modified by  : Ophir Peleg
 **/
global with sharing class xact_CP_UserDateTime implements CompSuite.CP_DynamicContentGenerator {
    private static final String FONT_FAMILY = '\'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif';
    private static final String FONT_SIZE = '8pt';

    public string getJSON(Id recordId, String input) {
        return null;
    }

    public string getHTML(Id recordId, String input) {
        TimeZone tz = UserInfo.getTimeZone();
        DateTime now = DateTime.now();
        Integer offsetMs = tz.getOffset(now);
        DateTime localDt = now.addSeconds(offsetMs / 1000);

        String formatted = localDt.formatGmt('yyyy-MM-dd') + ' \u2013 '
            + localDt.formatGmt('HH:mm:ss') + ' \u2013 '
            + tz.getID();

        return '<span style="font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + ';">' + formatted + '</span>';
    }
}
