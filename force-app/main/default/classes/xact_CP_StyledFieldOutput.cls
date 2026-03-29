/**
 * @description       : Renders a single field from a CompSuite__Audit__c record with standardized font styling.
 *                      The field API name is passed via Custom Input. Designed for textarea/HTML fields
 *                      where existing inline styles need to be overridden with consistent typography.
 * @author            : Ophir Oren
 * @last modified on  : 29-03-2026
 * @last modified by  : Ophir Peleg
 **/
global with sharing class xact_CP_StyledFieldOutput implements CompSuite.CP_DynamicContentGenerator {

    private static final String FONT_FAMILY = '\'TT Norms Pro\', \'Microsoft YaHei\', Aptos, Arial, Helvetica, sans-serif';
    private static final String FONT_SIZE = '10pt';
    private static final String RTA_IMG_TITLE = 'RichTextAreaImg';

    public String getJSON(Id recordId, String input) {
        return null;
    }

    public String getHTML(Id recordId, String input) {
        if (String.isBlank(input)) {
            return '';
        }

        String fieldApi = input.trim();

        // Dynamic SOQL to query the specified field from the Audit record
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

        String content = String.valueOf(fieldValue);
        if (String.isBlank(content)) {
            return '';
        }

        // Strip trailing blank HTML elements that rich text editors often add.
        // These include <p> tags with nested formatting tags (<strong>, <span>, etc.)
        // that contain only whitespace or &nbsp; e.g.:
        //   <p><strong style="..."> </strong></p>
        //   <p class="MsoNormal"><span style="..."> </span></p>
        //   <br/>
        content = stripTrailingEmptyElements(content);

        // Check if entire content is empty after stripping all tags
        if (String.isBlank(content.replaceAll('<[^>]*>', '').replaceAll('&nbsp;|\\u00A0', '').trim())) {
            return '';
        }

        // Replace private RTA image URLs (servlet/rtaImage) with public ContentDownloadUrls.
        // The LWC calls createRtaImgPublicLinks before PDF generation, which creates
        // ContentVersion + ContentDistribution records. We read those back here.
        content = replaceRtaImageUrls(content, recordId);

        // Wrap the HTML content with a div that enforces our font styling.
        // The CSS properties on the wrapper use !important to override any
        // inline styles that already exist within the field's HTML content.
        String html = '<div style="font-family: ' + FONT_FAMILY + ' !important; '
                    + 'font-size: ' + FONT_SIZE + ' !important; '
                    + 'width: 100%; margin: 0; padding: 0;">';
        html += content;
        html += '</div>';

        return html;
    }

    /**
     * Replaces private servlet/rtaImage URLs in RTA content with public ContentDownloadUrls.
     * The product's LWC creates temporary ContentVersion + ContentDistribution records
     * (titled 'RichTextAreaImg') linked to the record before PDF generation.
     * The original private URL is stored in ContentVersion.Description for mapping.
     */
    private String replaceRtaImageUrls(String content, Id recordId) {
        List<ContentDocumentLink> contentLinks = [
            SELECT ContentDocument.LatestPublishedVersion.Id,
                   ContentDocument.LatestPublishedVersion.Description
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
              AND ContentDocument.Title = :RTA_IMG_TITLE
            WITH SECURITY_ENFORCED
        ];

        if (contentLinks.isEmpty()) {
            return content;
        }

        Map<Id, String> versionToOriginalUrl = new Map<Id, String>();
        for (ContentDocumentLink cdl : contentLinks) {
            versionToOriginalUrl.put(
                cdl.ContentDocument.LatestPublishedVersion.Id,
                cdl.ContentDocument.LatestPublishedVersion.Description
            );
        }

        List<ContentDistribution> distributions = [
            SELECT ContentVersionId, ContentDownloadUrl
            FROM ContentDistribution
            WHERE ContentVersionId IN :versionToOriginalUrl.keySet()
            WITH SECURITY_ENFORCED
        ];

        for (ContentDistribution dist : distributions) {
            String originalUrl = versionToOriginalUrl.get(dist.ContentVersionId);
            if (String.isNotBlank(originalUrl)) {
                content = content.replace(originalUrl, dist.ContentDownloadUrl.escapeHtml4());
            }
        }

        return content;
    }

    /**
     * Repeatedly strips trailing empty block elements (<p>, <br>) from HTML content.
     * Handles nested tags inside <p> (e.g. <p><strong> </strong></p>)
     * by checking if the text content of the trailing block is only whitespace/nbsp.
     */
    private String stripTrailingEmptyElements(String html) {
        String result = html.trim();
        Boolean changed = true;

        while (changed) {
            changed = false;
            String trimmed = result.trim();

            // Strip trailing <br> tags
            String afterBr = trimmed.replaceAll('\\s*<br\\s*/?>\\s*$', '');
            if (afterBr.length() < trimmed.length()) {
                result = afterBr;
                changed = true;
                continue;
            }

            // Check for trailing </p> and find its matching <p
            if (trimmed.endsWith('</p>')) {
                Integer closeIdx = trimmed.length() - 4; // position of </p>
                Integer openIdx = trimmed.lastIndexOf('<p', closeIdx);
                if (openIdx >= 0) {
                    String block = trimmed.substring(openIdx);
                    // Strip all tags from the block and check if only whitespace/nbsp remains
                    String textOnly = block.replaceAll('<[^>]*>', '').replaceAll('&nbsp;|\\u00A0', '').trim();
                    if (String.isBlank(textOnly)) {
                        result = trimmed.substring(0, openIdx);
                        changed = true;
                    }
                }
            }
        }

        return result.trim();
    }
}
