/**
 * @description       : Notes & Attachments Output Component for Content Publisher.
 *                      Generates HTML output displaying classic Notes (Note object)
 *                      and Files (Attachments) linked to any Salesforce record.
 * @author            : Ophir Peleg
 * @last modified on  : 02-10-2026
 * @last modified by  : Claude
 **/
global with sharing class xact_CP_NotesAndAttachments implements CompSuite.CP_DynamicContentGenerator {

  // ============================================
  // Constants
  // ============================================
  private static final String FONT_FAMILY = '\'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif';
  private static final String FONT_SIZE = '10pt';
  private static final String SECTION_HEADER_STYLE = 'background-color:#333333; color:white; font-weight:bold; padding:6px 10px;';
  private static final String TABLE_HEADER_STYLE = 'background-color:#f4f4f4; font-weight:bold; padding:6px; border:1px solid #ddd;';
  private static final String TABLE_CELL_STYLE = 'padding:6px; border:1px solid #ddd; vertical-align:top;';

  // ============================================
  // Wrapper Classes
  // ============================================

  /**
   * @description Wrapper for a Note record
   */
  public class NoteWrapper {
    public String title { get; set; }
    public String body { get; set; }
    public DateTime createdDate { get; set; }
    public String createdByName { get; set; }

    public NoteWrapper(String title, String body, DateTime createdDate, String createdByName) {
      this.title = title;
      this.body = body;
      this.createdDate = createdDate;
      this.createdByName = createdByName;
    }
  }

  /**
   * @description Wrapper for an Attachment (File) record
   */
  public class AttachmentWrapper {
    public String title { get; set; }
    public String fileType { get; set; }
    public String fileExtension { get; set; }
    public Long contentSize { get; set; }
    public DateTime createdDate { get; set; }
    public String createdByName { get; set; }

    public AttachmentWrapper(String title, String fileType, String fileExtension,
                             Long contentSize, DateTime createdDate, String createdByName) {
      this.title = title;
      this.fileType = fileType;
      this.fileExtension = fileExtension;
      this.contentSize = contentSize;
      this.createdDate = createdDate;
      this.createdByName = createdByName;
    }
  }

  /**
   * @description Container for all Notes and Attachments data
   */
  public class NotesAndAttachmentsData {
    public List<NoteWrapper> notes { get; set; }
    public List<AttachmentWrapper> attachments { get; set; }

    public NotesAndAttachmentsData() {
      this.notes = new List<NoteWrapper>();
      this.attachments = new List<AttachmentWrapper>();
    }

    public Boolean hasData() {
      return !notes.isEmpty() || !attachments.isEmpty();
    }
  }

  // ============================================
  // Interface Implementation
  // ============================================

  public String getJSON(Id recordId, String input) {
    return null;
  }

  public String getHTML(Id recordId, String input) {
    return getFormattedData(recordId, input);
  }

  // ============================================
  // Main Processing Method
  // ============================================

  public String getFormattedData(String recordId, String widthInput) {
    if (String.isBlank(recordId)) {
      return '';
    }

    NotesAndAttachmentsData data = queryNotesAndAttachments(recordId);

    if (!data.hasData()) {
      return '';
    }

    String strHTMLData = generateHTML(data);
    System.debug('xact_CP_NotesAndAttachments strHTMLData==>' + strHTMLData);
    return strHTMLData;
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * @description Queries Notes (classic Note object) and Attachments
   *              (ContentDocumentLink → ContentVersion) for the given record.
   */
  private NotesAndAttachmentsData queryNotesAndAttachments(String recordId) {
    NotesAndAttachmentsData data = new NotesAndAttachmentsData();

    // Query 1: Get all ContentDocumentLinks for this record (Attachments/Files)
    List<ContentDocumentLink> links = [
      SELECT ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :recordId
      WITH SECURITY_ENFORCED
    ];

    if (!links.isEmpty()) {
      Set<Id> contentDocIds = new Set<Id>();
      for (ContentDocumentLink link : links) {
        contentDocIds.add(link.ContentDocumentId);
      }

      List<ContentVersion> versions = [
        SELECT Id, Title, FileType, FileExtension, ContentSize,
               CreatedDate, CreatedBy.Name
        FROM ContentVersion
        WHERE ContentDocumentId IN :contentDocIds
        AND IsLatest = true
        WITH SECURITY_ENFORCED
        ORDER BY CreatedDate DESC
      ];

      for (ContentVersion cv : versions) {
        data.attachments.add(new AttachmentWrapper(
          cv.Title,
          cv.FileType,
          cv.FileExtension,
          cv.ContentSize,
          cv.CreatedDate,
          cv.CreatedBy != null ? cv.CreatedBy.Name : ''
        ));
      }
    }

    // Query 2: Get all classic Notes for this record
    List<Note> notes = [
      SELECT Id, Title, Body, CreatedDate, CreatedBy.Name
      FROM Note
      WHERE ParentId = :recordId
      WITH SECURITY_ENFORCED
      ORDER BY CreatedDate DESC
    ];

    for (Note n : notes) {
      data.notes.add(new NoteWrapper(
        n.Title,
        n.Body,
        n.CreatedDate,
        n.CreatedBy != null ? n.CreatedBy.Name : ''
      ));
    }

    return data;
  }

  // ============================================
  // HTML Generation Methods
  // ============================================

  /**
   * @description Generates the complete HTML output with Notes and Attachments tables
   */
  private String generateHTML(NotesAndAttachmentsData data) {
    String html = '';
    html += '<div style="font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + '; width:100%;">';

    if (!data.notes.isEmpty()) {
      html += buildNotesSection(data.notes);
    }

    // Spacing between sections when both exist
    if (!data.notes.isEmpty() && !data.attachments.isEmpty()) {
      html += '<br/>';
    }

    if (!data.attachments.isEmpty()) {
      html += buildAttachmentsSection(data.attachments);
    }

    html += '</div>';
    return html;
  }

  /**
   * @description Builds the Notes table section
   */
  private String buildNotesSection(List<NoteWrapper> notes) {
    String html = '';

    // Section header
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
    html += '<div style="' + SECTION_HEADER_STYLE + '">Notes</div>';
    html += '</div>';
    html += '</div>';

    // Table
    html += '<table style="width:100%; border-collapse:collapse; font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + ';">';

    // Header row
    html += '<thead>';
    html += '<tr>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:20%;">Title</th>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:40%;">Body</th>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:20%;">Created By</th>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:20%;">Created Date</th>';
    html += '</tr>';
    html += '</thead>';

    // Data rows
    html += '<tbody>';
    for (NoteWrapper note : notes) {
      html += '<tr>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + safeString(note.title) + '</td>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + formatNoteBody(note.body) + '</td>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + safeString(note.createdByName) + '</td>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + formatDateTime(note.createdDate) + '</td>';
      html += '</tr>';
    }
    html += '</tbody>';
    html += '</table>';

    return html;
  }

  /**
   * @description Builds the Attachments (Files) table section
   */
  private String buildAttachmentsSection(List<AttachmentWrapper> attachments) {
    String html = '';

    // Section header
    html += '<div style="width:100%;display:table;table-layout:fixed;">';
    html += '<div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
    html += '<div style="' + SECTION_HEADER_STYLE + '">Attachments</div>';
    html += '</div>';
    html += '</div>';

    // Table
    html += '<table style="width:100%; border-collapse:collapse; font-family: ' + FONT_FAMILY + '; font-size: ' + FONT_SIZE + ';">';

    // Header row
    html += '<thead>';
    html += '<tr>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:30%;">File Name</th>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:15%;">Type</th>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:10%;">Size</th>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:25%;">Created By</th>';
    html += '<th style="' + TABLE_HEADER_STYLE + ' width:20%;">Upload Date</th>';
    html += '</tr>';
    html += '</thead>';

    // Data rows
    html += '<tbody>';
    for (AttachmentWrapper att : attachments) {
      html += '<tr>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + safeString(att.title) + '</td>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + formatFileType(att.fileType, att.fileExtension) + '</td>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + formatFileSize(att.contentSize) + '</td>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + safeString(att.createdByName) + '</td>';
      html += '<td style="' + TABLE_CELL_STYLE + '">' + formatDateTime(att.createdDate) + '</td>';
      html += '</tr>';
    }
    html += '</tbody>';
    html += '</table>';

    return html;
  }

  // ============================================
  // Utility Methods
  // ============================================

  private String safeString(String value) {
    return String.isBlank(value) ? '' : value.escapeHtml4();
  }

  private String formatNoteBody(String body) {
    if (String.isBlank(body)) {
      return '';
    }
    return body.escapeHtml4().replace('\n', '<br/>');
  }

  private String formatDateTime(DateTime dt) {
    if (dt == null) {
      return '';
    }
    return dt.format('MMM dd, yyyy, hh:mm a', UserInfo.getTimeZone().toString());
  }

  private String formatFileSize(Long sizeInBytes) {
    if (sizeInBytes == null) {
      return '';
    }
    if (sizeInBytes < 1024) {
      return sizeInBytes + ' B';
    } else if (sizeInBytes < 1024 * 1024) {
      Decimal kb = Decimal.valueOf(sizeInBytes) / 1024;
      return kb.setScale(1, RoundingMode.HALF_UP) + ' KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      Decimal mb = Decimal.valueOf(sizeInBytes) / (1024 * 1024);
      return mb.setScale(1, RoundingMode.HALF_UP) + ' MB';
    } else {
      Decimal gb = Decimal.valueOf(sizeInBytes) / (1024 * 1024 * 1024);
      return gb.setScale(1, RoundingMode.HALF_UP) + ' GB';
    }
  }

  private String formatFileType(String fileType, String fileExtension) {
    if (String.isNotBlank(fileExtension)) {
      return safeString(fileExtension.toUpperCase());
    }
    if (String.isNotBlank(fileType)) {
      return safeString(fileType.toUpperCase());
    }
    return '';
  }
}
