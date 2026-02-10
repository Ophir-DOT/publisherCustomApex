/**
 * @description       : This class is used to generate Protocol Output from Content Publisher with enhanced Width based layout handling
 * @author            : Ophir Peleg
 * @group             :
 * @last modified on  : 12-17-2025
 * @last modified by  : Ceptes
 **/
global with sharing class Xact_CP_Advanced_Custom_ProtocolOutput implements CompSuite.CP_DynamicContentGenerator {
  private static final String RT_PE_MULTI_PICKLIST = 'Multi Picklist';
  private static final String RT_PE_TRAINEFFECT = 'Training Effectiveness';
  private static final String RT_PE_TABLE = 'Table';
  private static final String RT_PE_TEST_STEP = 'Test Step';
  private static final String RT_PE_TEXT_ONLY = 'Text Only';
  private static final String RT_PE_SINGLE_PICKLIST = 'Single Picklist';
  private static final String DATETYPE_DATETIME = 'DATETIME';
  private static final String DATETYPE_DATE = 'DATE';
  private static final String RT_PE_NUMERIC_VALUE = 'Numeric Value';
  private static final String RT_PE_RADIO_BUTTON_VERTICAL = 'Radio Button Vertical';
  private static final String RT_PE_FREE_TEXT = 'Free Text';
  private static final String RT_PE_RADIO_BUTON_HORIZONTAL = 'Radio Button Horizontal';
  private static final Map<Integer, Integer> MAX_WORD_LENGTH = new Map<Integer, Integer>{ 25 => 18, 33 => 40, 50 => 45, 100 => 89 };
  private static string protocolExecutionNumber;

  public string getJSON(Id recordId, string input) {
    return null;
  }

  public string getHTML(Id recordId, string input) {
    String protocolOutputString = '';
    protocolOutputString = getFormatedData(recordId, input);
    return protocolOutputString;
  }

  public String getFormatedData(String recordId, string widthInput) {
    string strId = recordId;
    string strHTMLData = '';
    string proExeRecordType;
    Decimal score;
    Decimal passingScore;
    Datetime completionDate;
    lstwrp = new List<WrpCmpContent>();
    lstwrpSections = new List<WrpSections>();

    CompSuite__Protocol_Execution__c proExe = [
      SELECT Id, Name, RecordTypeId, RecordType.Name, CompSuite__Protocol_Execution_Number__c, CompSuite__Passing_Score__c, CompSuite__Result__c, CompSuite__Exam_Date__c, CompSuite__Audit__c
      FROM CompSuite__Protocol_Execution__c
      WHERE Id = :strId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];

    proExeRecordType = proExe.RecordType.Name;
    score = proExe.CompSuite__Result__c;
    passingScore = proExe.CompSuite__Passing_Score__c;
    protocolExecutionNumber = proExe.CompSuite__Protocol_Execution_Number__c;

    if (proExe.CompSuite__Exam_Date__c != null) {
      completionDate = proExe.CompSuite__Exam_Date__c;
    }

    map<id, CompSuite__Execution_Element__c> mapofEE = new Map<id, CompSuite__Execution_Element__c>(
      [
        SELECT
          Id,
          CompSuite__Selected_Radio_Button__c,
          CompSuite__Numeric_Value__c,
          CompSuite__Expected_Value__c,
          CompSuite__Expected_Numerical_Range__c,
          CompSuite__Comments__c,
          CompSuite__Protocol_Execution__r.RecordType.Name,
          CompSuite__Approved_On__c,
          CompSuite__Approver__r.Name,
          CompSuite__Single_Selected_Option__c,
          CompSuite__Date__c,
          CompSuite__Datetime__c,
          CompSuite__Performed_By__r.Username,
          CompSuite__Actual_Result__c,
          CompSuite__Protocol_Execution__c,
          CompSuite__Protocol_Element__c,
          CompSuite__Protocol_Element__r.CompSuite__Choices__c,
          CompSuite__Selected_Multi_Options__c,
          CompSuite__Protocol_Element__r.CompSuite__Test_Procedure__c,
          CompSuite__Score__c,
          Is_Correct_Answer__c,
          Employee_Answer__c,
          CompSuite__Free_Text__c
        FROM CompSuite__Execution_Element__c
        WHERE CompSuite__Protocol_Execution__c = :strId
        ORDER BY CompSuite__Protocol_Element__r.CompSuite__Order__c, CompSuite__Protocol_Element__r.CompSuite__Protocol_Element_Number__c, CompSuite__Row_Index__c
      ]
    );

    set<String> pEIds = new Set<String>();
    for (CompSuite__Execution_Element__c ee : mapofEE.Values()) {
      if (ee.CompSuite__Protocol_Element__c != null) {
        pEIds.add(ee.CompSuite__Protocol_Element__c);
      }
    }

    map<id, CompSuite__Protocol_Element__c> mapPE = new Map<id, CompSuite__Protocol_Element__c>(
      [
        SELECT
          Id,
          CompSuite__Is_Critical__c,
          CompSuite__Skip_Numbering__c,
          CompSuite__Order__c,
          CompSuite__Display_Comments__c,
          CompSuite__Rich_Description__c,
          CompSuite__Require_Signature__c,
          CompSuite__Acceptance_Criteria__c,
          CompSuite__Layout__c,
          CompSuite__Table_Element__c,
          CompSuite__Choices__c,
          RecordType.Name,
          CompSuite__Test_Procedure__c,
          CompSuite__Validation_Protocol__c
        FROM CompSuite__Protocol_Element__c
        WHERE Id IN :pEIds
        ORDER BY CompSuite__Order__c, CompSuite__Protocol_Element_Number__c
      ]
    );

    Integer sectionCount = 1;
    Integer cmpCount = 1;
    Integer orderNumber = 0;
    WrpSections wrpsections = new WrpSections();

    // Iterate through Protocol Elements in order, then find matching Execution Elements
    for (CompSuite__Protocol_Element__c pe : mapPE.Values()) {
      for (CompSuite__Execution_Element__c ee : mapofEE.Values()) {
        if (ee.CompSuite__Protocol_Element__c == pe.id) {
          WrpCmpContent wrp = new WrpCmpContent();
          wrp.contentType = pe.RecordType.Name;
          wrp.isCritical = pe.CompSuite__Is_Critical__c;
          wrp.isSkipNumbering = pe.CompSuite__Skip_Numbering__c;
          wrp.orderNumber = (integer) pe.CompSuite__Order__c;
          if (pe.CompSuite__Rich_Description__c != null) {
            wrp.description = pe.CompSuite__Rich_Description__c;
          }

          wrp.datetimeData = ee.CompSuite__Datetime__c;
          wrp.dateData = ee.CompSuite__Date__c;
          wrp.examType = ee.CompSuite__Protocol_Execution__r.RecordType.Name;
          wrp.expectedValue = ee.CompSuite__Expected_Value__c;
          wrp.expectedNumericalRange = ee.CompSuite__Expected_Numerical_Range__c;

          if (ee.CompSuite__Score__c != null) {
            wrp.score = ee.CompSuite__Score__c + '';
          }

          wrp.isCorrect = ee.Is_Correct_Answer__c;
          //Seems there is a issue for proExeRecordType == 'Training Effectiveness') and Mutli select;
          if (proExeRecordType == RT_PE_TRAINEFFECT && ee.CompSuite__Score__c > 0) {
            wrp.isCorrect = true;
          }

          if (pe.RecordType.Name == RT_PE_TABLE) {
            wrp.isTable = true;
            wrp.tableName = pe.CompSuite__Test_Procedure__c;

            String strTableid = pe.id;
            set<String> setOfQuestion = new Set<String>();
            map<String, list<String>> mapofqueAns = new Map<string, list<string>>();
            for (CompSuite__Execution_Element__c e : mapofEE.Values()) {
              for (CompSuite__Protocol_Element__c p : mapPE.Values()) {
                if (e.CompSuite__Protocol_Element__c == p.id) {
                  WrpCmpContent tableElement = new WrpCmpContent();
                  if (p.CompSuite__Table_Element__c == strTableid) {
                    if (p.CompSuite__Test_Procedure__c != null) {
                      setOfQuestion.add(p.CompSuite__Test_Procedure__c);
                    }
                    tableElement.question = p.CompSuite__Test_Procedure__c;
                    tableElement.choice = p.CompSuite__Choices__c;
                    if (p.RecordType.Name == RT_PE_MULTI_PICKLIST) {
                      tableElement.answer = e.CompSuite__Selected_Multi_Options__c;
                    } else if (p.RecordType.Name == RT_PE_FREE_TEXT) {
                      tableElement.answer = e.CompSuite__Free_Text__c;
                    } else if (p.RecordType.Name == RT_PE_RADIO_BUTTON_VERTICAL || p.RecordType.Name == RT_PE_RADIO_BUTON_HORIZONTAL) {
                      tableElement.answer = String.valueOf(e.CompSuite__Selected_Radio_Button__c);
                    } else if (p.RecordType.Name == RT_PE_SINGLE_PICKLIST) {
                      tableElement.answer = e.CompSuite__Single_Selected_Option__c;
                    } else {
                      tableElement.answer = formatAnswer(p.RecordType.Name, e.CompSuite__Free_Text__c, e.CompSuite__Date__c, e.CompSuite__Datetime__c, true);
                    }
                    wrp.tableElement.add(tableElement);
                  }
                }
              }
            }

            wrp.tableQuetionSet.addAll(setOfQuestion);
            //To store Ans
            Integer questionCount = 0;
            List<String> lstrowAns = new List<String>();
            for (String strques : setOfQuestion) {
              list<string> lsttemp = new List<string>();
              for (CompSuite__Execution_Element__c e : mapofEE.Values()) {
                for (CompSuite__Protocol_Element__c p : mapPE.Values()) {
                  if (e.CompSuite__Protocol_Element__c == p.id) {
                    WrpCmpContent tableElement = new WrpCmpContent();
                    if (p.CompSuite__Table_Element__c == strTableid) {
                      if (strques == p.CompSuite__Test_Procedure__c) {
                        if (p.RecordType.Name == RT_PE_MULTI_PICKLIST) {
                          if (e.CompSuite__Selected_Multi_Options__c != null) {
                            String input = e.CompSuite__Selected_Multi_Options__c;
                            String[] values = input.split('\n');
                            lsttemp.add(String.join(values, '<br/>'));
                          } else {
                            lsttemp.add('');
                          }
                        } else if (p.RecordType.Name == RT_PE_FREE_TEXT) {
                          if (e.CompSuite__Free_Text__c != null) {
                            lsttemp.add(String.valueOf(e.CompSuite__Free_Text__c));
                          } else {
                            lsttemp.add('');
                          }
                        } else if (p.RecordType.Name == RT_PE_RADIO_BUTTON_VERTICAL || p.RecordType.Name == RT_PE_RADIO_BUTON_HORIZONTAL) {
                          if (e.CompSuite__Selected_Radio_Button__c != null) {
                            lsttemp.add(String.valueOf(e.CompSuite__Selected_Radio_Button__c));
                          } else {
                            lsttemp.add('');
                          }
                        } else if (p.RecordType.Name == RT_PE_SINGLE_PICKLIST) {
                          if (e.CompSuite__Single_Selected_Option__c != null) {
                            lsttemp.add(e.CompSuite__Single_Selected_Option__c);
                          } else {
                            lsttemp.add('');
                          }
                        } else {
                          if (e.Employee_Answer__c != null || e.CompSuite__Date__c != null || e.CompSuite__Datetime__c != null) {
                            lsttemp.add(formatAnswer(p.RecordType.Name, e.Employee_Answer__c, e.CompSuite__Date__c, e.CompSuite__Datetime__c, true));
                          } else {
                            lsttemp.add('');
                          }
                        }
                      }
                      if (e.CompSuite__Free_Text__c != null) {
                        lstrowAns.add(e.CompSuite__Free_Text__c);
                      } else {
                        lstrowAns.add('');
                      }
                    }
                  }
                }
              }
              mapofqueAns.put(strques, lsttemp);
            }

            if (setOfQuestion.size() > 0) {
              if (setOfQuestion != null) {
                questionCount = setOfQuestion.Size();
              }

              lstrowAns = new List<String>();
              wrp.maptabledata = mapofqueAns;
              integer lstIndexCount = 0;
              list<string> lsttemp = new List<string>();

              Integer loopSize = 1;
              for (lstIndexCount = 0; lstIndexCount < loopSize; lstIndexCount++) {
                for (String strkey : mapofqueAns.KeySet()) {
                  loopSize = mapofqueAns.get(strkey).size();
                  lsttemp.add(mapofqueAns.get(strkey)[lstIndexCount]);
                }

                if (lsttemp.size() > 0) {
                  wrp.lstAns.add(lsttemp);
                  lsttemp = new List<String>();
                }
              }
            }
          } else {
            //Since all table element already cosidered in Table Type
            if (pe.CompSuite__Table_Element__c != null) {
              continue;
            }

            wrp.question = pe.CompSuite__Test_Procedure__c;
            wrp.choice = pe.CompSuite__Choices__c;
            if (pe.RecordType.Name == RT_PE_MULTI_PICKLIST) {
              wrp.answer = ee.CompSuite__Selected_Multi_Options__c;
            } else if (pe.RecordType.Name == RT_PE_FREE_TEXT) {
              wrp.answer = ee.CompSuite__Free_Text__c;
            } else if (pe.RecordType.Name == RT_PE_SINGLE_PICKLIST) {
              wrp.answer = ee.CompSuite__Single_Selected_Option__c;
            } else if (pe.RecordType.Name == RT_PE_NUMERIC_VALUE) {
              wrp.answer = ee.Employee_Answer__c;
            } else if (pe.RecordType.Name == RT_PE_RADIO_BUTON_HORIZONTAL || pe.RecordType.Name == RT_PE_RADIO_BUTTON_VERTICAL) {
              wrp.answer = String.valueOf(ee.CompSuite__Selected_Radio_Button__c);
            } else if (pe.RecordType.Name == RT_PE_TEST_STEP) {
              wrp.actualResult = ee.CompSuite__Actual_Result__c;
              wrp.exceptedResult = pe.CompSuite__Acceptance_Criteria__c;
              wrp.answer = ee.CompSuite__Single_Selected_Option__c;

              if (ee.CompSuite__Performed_By__r.Username != null) {
                wrp.username = ee.CompSuite__Performed_By__r.Username;
              }

              if (ee.CompSuite__Date__c != null) {
                wrp.dateData = ee.CompSuite__Date__c;
              }
            } else {
              wrp.answer = ee.Employee_Answer__c;
            }

            if (pe.CompSuite__Require_Signature__c) {
              if (ee.CompSuite__Approver__r.Name != null) {
                wrp.approveBy = ee.CompSuite__Approver__r.Name;
              }

              if (ee.CompSuite__Approved_On__c != null) {
                wrp.approveOn = ee.CompSuite__Approved_On__c;
              }
              wrp.isApproveRequired = pe.CompSuite__Require_Signature__c;
            }

            if (pe.CompSuite__Display_Comments__c) {
              wrp.comment = ee.CompSuite__Comments__c;
              wrp.isDisplaycomment = pe.CompSuite__Display_Comments__c;
            }
          }

          // WIDTH-BASED BIN PACKING ALGORITHM
          String strLayout = pe.CompSuite__Layout__c;
          Integer elementColumns = 1;

          // Check if this is a full-width element that should be in its own row
          Boolean isFullWidthElement = false;
          if (pe.RecordType.Name == RT_PE_TABLE || pe.RecordType.Name == RT_PE_TEST_STEP) {
            isFullWidthElement = true;
          } else if (pe.RecordType.Name == RT_PE_TEXT_ONLY && (String.isEmpty(strLayout) || strLayout == '1-of-1')) {
            // Text Only with no layout or 1-of-1 should be full width
            isFullWidthElement = true;
          }

          if (isFullWidthElement) {
            // Close current section if not empty
            if (!wrpsections.lstwrp.isEmpty()) {
              wrpsections.sectionCount = wrpsections.lstwrp.size();
              if (!wrpsections.lstwrp.isEmpty()) {
                wrpsections.maxColumns = wrpsections.lstwrp[0].columnCount;
              }
              lstwrpSections.add(wrpsections);
              wrpsections = new WrpSections();
            }

            // Add element to its own section
            wrp.columnCount = 1;
            wrpsections.lstwrp.add(wrp);
            wrpsections.sectionCount = 1;
            wrpsections.maxColumns = 1;
            lstwrpSections.add(wrpsections);
            wrpsections = new WrpSections();
            lstwrp.add(wrp);
          } else {
            // Extract how many columns this element needs (1-of-X means it needs 1 slot out of X)
            if (String.isNotEmpty(strLayout)) {
              String strSecCount = strLayout.substringAfter('1-of-');
              if (String.isNotBlank(strSecCount)) {
                elementColumns = Integer.valueOf(strSecCount);
              }
            }

            // Store column count for width calculation
            wrp.columnCount = elementColumns;

            // Calculate width percentage: 1-of-4 = 100/4 = 25%
            Decimal elementWidth = 100.0 / elementColumns;
            Decimal currentRowWidth = 0;

            // Calculate current row width
            for (WrpCmpContent existingWrp : wrpsections.lstwrp) {
              currentRowWidth += (100.0 / existingWrp.columnCount);
            }

            // Check if adding this element exceeds 100%
            if (
              !wrpsections.lstwrp.isEmpty() &&
              (currentRowWidth + elementWidth) > 100.1 // 0.1 tolerance for rounding
            ) {
              // Close current section - row is full
              wrpsections.sectionCount = wrpsections.lstwrp.size();
              // Track max columns from first element in section
              if (!wrpsections.lstwrp.isEmpty()) {
                wrpsections.maxColumns = wrpsections.lstwrp[0].columnCount;
              }
              lstwrpSections.add(wrpsections);
              wrpsections = new WrpSections();
            }

            wrpsections.lstwrp.add(wrp);
            lstwrp.add(wrp);
          }

          // Break inner loop after processing this execution element
          break;
        }
      }
    }

    List<CompSuite__Observation__c> lstFinding = [
      SELECT Finding_ID__c, CompSuite__Observation_Date__c, CompSuite__Observation_Description__c
      FROM CompSuite__Observation__c
      WHERE CompSuite__Audit__c = :proExe.CompSuite__Audit__c
      ORDER BY Finding_ID__c ASC
    ];
    // strHTMLData += '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif;font-size: 10pt;page-break-inside:avoid;width:100%;display:table;">';
    // strHTMLData += '<table style="-fs-table-paginate: paginate;padding:0px;margin:0px;border-collapse: collapse;min-width: 100% !important;">';
    // strHTMLData += '   <thead>';
    // strHTMLData += '     <th style="padding:2px;border:1px solid black;width:50%">Findings</th>';
    // strHTMLData += '   </thead>';
    // strHTMLData += '   <tbody>';
    // for (CompSuite__Observation__c obs : lstFinding) {
    //   strHTMLData += '     <tr><td><div>';
    //   strHTMLData += '       <p style="padding:2px;"><b>Finding Name: </b>' + obs.Finding_ID__c + '</p>';
    //   strHTMLData += '       <p style="padding:2px;"><b>Finding Description: </b>' + obs.CompSuite__Observation_Description__c + '</p>';
    //   strHTMLData += '       <p style="padding:2px;"><b>Finding Date: </b>' + formatAnswer('DATE', null, obs.CompSuite__Observation_Date__c, null, false) + '</p>';
    //   strHTMLData += '     </div></td></tr>';
    // }
    // strHTMLData += '   </tbody>';
    // strHTMLData += '</table>';
    // strHTMLData += '</div>';

    // Findings sections

    strHTMLData += '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif; font-size: 10pt;align-content: center;width:100%;">';
    for (CompSuite__Observation__c obs : lstFinding) {
      strHTMLData += '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif; font-size: 10pt;align-content: center;width:100%;">';
      strHTMLData += '<div style="width:100%;display:table;table-layout:fixed;">';
      strHTMLData += '    <div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
      strHTMLData += '      <div style="background-color:black; color:white; font-weight:bold; padding:4px;">Findings</div>';
      strHTMLData += '    </div>';
      strHTMLData += '  </div>';

      strHTMLData += '<div style="width:100%;display:table;table-layout:fixed;">';
      strHTMLData += '  <div style="padding:4px;border:1px solid black;vertical-align: top;display:table-cell;width:100%;">';
      // strHTMLData += '    <div style="border:1px solid black; margin-bottom:10px; page-break-inside:avoid;">';
      strHTMLData += '      <div style="padding:10px 6px 6px 10px;">';
      strHTMLData += '        <p style="margin:2px 0;"><b>Finding Name: </b>' + obs.Finding_ID__c + '</p>';
      strHTMLData += '        <p style="margin:2px 0;"><b>Finding Description: </b>' + obs.CompSuite__Observation_Description__c + '</p>';
      strHTMLData += '        <p style="margin:2px 0;"><b>Finding Date: </b>' + formatAnswer('DATE', null, obs.CompSuite__Observation_Date__c, null, false) + '</p>';
      strHTMLData += '      </div>';
      // strHTMLData += '    </div>';
      strHTMLData += '  </div>';
      strHTMLData += '</div>';
      strHTMLData += '<br/>';
    }

    strHTMLData += '</div>';

    // Handle any remaining incomplete section
    if (!wrpsections.lstwrp.isEmpty()) {
      wrpsections.sectionCount = wrpsections.lstwrp.size();
      if (!wrpsections.lstwrp.isEmpty()) {
        wrpsections.maxColumns = wrpsections.lstwrp[0].columnCount;
      }
      lstwrpSections.add(wrpsections);
    }
    if (String.isNotEmpty(widthInput))
      strHTMLData += '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif;font-size: 10pt;align-content: center;width:' + widthInput + 'px"> ';
    else {
      strHTMLData += '<div>';
    }
    if (proExeRecordType == RT_PE_TRAINEFFECT) {
      strHTMLData += '<BR/><div style="width:60%">'; //display:inline-block;
      //  strHTMLData+='<table style="-fs-table-paginate: paginate;padding:0px;margin:0px;border-collapse: collapse;min-width: 100% !important;"> ';//border: 1px solid black;
      strHTMLData += '<table style="-fs-table-paginate: paginate;padding:0px;margin:0px;border-collapse: collapse;min-width: 100% !important;width:60%"> '; //border: 1px solid black;
      strHTMLData += '   <thead>';
      strHTMLData += '     <th colspan=2 style="padding:2px;border: 1px solid black;width:50%">Exam Summary</th>';
      strHTMLData += '   </thead>';
      strHTMLData += '   <tr>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">Pass/Fail</td>';
      Double tempScore = Double.valueOf(score);
      Double tempPassingScore = Double.valueOf(passingScore);
      if (tempScore >= tempPassingScore) {
        strHTMLData += '     <td style="padding:2px;border: 1px solid black;">Pass</td>';
      } else {
        strHTMLData += '     <td style="padding:2px;border: 1px solid black;">Fail</td>';
      }

      strHTMLData += '   </tr>';
      strHTMLData += '   <tr>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">Score</td>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + (score == null ? '' : score + '') + '</td>';
      strHTMLData += '   </tr>';
      strHTMLData += '   <tr>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">Passing Score</td>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + (passingScore == null ? '' : passingScore + '') + '</td>';
      strHTMLData += '   </tr>';
      strHTMLData += '   <tr>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">Completion Date</td>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + formatAnswer('DATETIME', null, null, completionDate, false) + '</td>';
      strHTMLData += '   </tr>';
      strHTMLData += '   <tr>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">Protocol Execution Number</td>';
      strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + (protocolExecutionNumber == null ? '' : protocolExecutionNumber + '') + '</td>';
      strHTMLData += '   </tr>';
      strHTMLData += '</table> ';
      strHTMLData += '</div>';
      strHTMLData += '<div style="display:inline-block;width:100%">';
      strHTMLData += '</div> ';
    }

    // page-break-inside:avoid;
    strHTMLData += '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif;font-size: 10pt;page-break-inside:avoid;width:100%;display:table;">';
    boolean avoidcode = false;
    for (WrpSections sec : lstwrpSections) {
      if (proExeRecordType != RT_PE_TRAINEFFECT) {
        strHTMLData += '<br/>';
        strHTMLData += '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif;width:100%;display:table;table-layout:fixed;">';
      }
      for (WrpCmpContent wrp : sec.lstwrp) {
        system.debug('wrp' + wrp.contentType);
        system.debug('wrp and' + wrp.answer);
        system.debug('wrp.examType' + wrp.examType);
        if (wrp.contentType != 'Table' && wrp.contentType != 'Test Step' && wrp.contentType != 'Text Only') {
          if (wrp.examType == RT_PE_TRAINEFFECT) {
            if (!avoidcode) {
              strHTMLData += '<div style=" width:100%">';
              strHTMLData += '<br/>';
              strHTMLData += '</div>';
              strHTMLData += '<div style="width:100%">';
              strHTMLData += '<table style="padding:0px;margin:0px;border-collapse: collapse; min-width: 100% !important;"> ';
              strHTMLData += '   <thead>';
              strHTMLData += '     <th style="padding:5px;border: 1px solid black;width:60px">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th>';
              strHTMLData += '     <th style="padding:2px;border: 1px solid black;width:35%">Question</th>';
              strHTMLData += '     <th style="padding:2px;border: 1px solid black;width:35%">answer</th>';
              strHTMLData += '     <th style="padding:2px;border: 1px solid black;">Correct answer</th>';
              strHTMLData += '     <th style="padding:2px;border: 1px solid black;">Score</th>';
              strHTMLData += '     <th style="padding:2px;border: 1px solid black;">Is Critical</th>';
              strHTMLData += '     <th style="padding:2px;border: 1px solid black;">Correct</th>';
              strHTMLData += '   </thead>';
              avoidcode = true;
            }

            strHTMLData += ' <tr> ';
            strHTMLData += '     <td style="text-align: center;padding:5px;border: 1px solid black; width:60px">' + (++orderNumber) + '</td>';
            strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + wrp.question + '</td>';
            strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + (wrp.answer == null ? '' : wrp.answer) + '<br/>';

            if (wrp.isDisplaycomment && string.isNotEmpty(wrp.comment)) {
              strHTMLData += ' <b>Comments</b><br/>  ';
              strHTMLData += wrp.comment;
            }

            if (wrp.isApproveRequired && string.isNotEmpty(wrp.approveBy)) {
              strHTMLData += '<br/>';
              strHTMLData += '<span class="x-line:503">Signature</span>';
              strHTMLData += '<br/>';
              strHTMLData += ' Signed by ' + wrp.approveBy + ' at ' + formatAnswer('DATETIME', null, null, wrp.approveOn, false) + '' + '<br/>';
            }

            strHTMLData += '</td>';
            strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + (wrp.expectedValue != null ? wrp.expectedValue : wrp.expectedNumericalRange) + '</td>';
            strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + wrp.score + '</td>';
            strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + (wrp.isCritical ? 'Yes' : 'No') + '</td>';
            strHTMLData += '     <td style="padding:2px;border: 1px solid black;">' + (wrp.isCorrect ? 'Yes' : 'No') + '</td>';
            strHTMLData += '</tr> ';
          } else {
            Integer cellWidth = 100 / sec.sectionCount;
            strHTMLData += '<div class="x-line:516" style="padding:4px;border:1px solid black;vertical-align: top;display:table-cell;width:' + cellWidth + '%">';

            strHTMLData += '<div class="x-line:518"><strong>' + (wrp.isSkipNumbering ? wrp.question : ((++orderNumber) + '. ' + wrp.question)) + '</strong></div>';
            // strHTMLData += '<br/>';
            strHTMLData += '<div class="x-line:520">' + (String.isBlank(wrp.description) ? '' : wrp.description) + '</div>';

            //  strHTMLData+=''+formatAnswer(wrp.contentType,wrp.answer,wrp.dateData,wrp.datetimeData,true) + '<br/>';
            String formattedAnswer = formatAnswer(wrp.contentType, wrp.answer, wrp.dateData, wrp.datetimeData, true);
            system.debug('wrpcellWidth' + cellWidth);
            system.debug('wrpformattedAnswer.length()' + formattedAnswer.length());
            Integer maxWordLength = MAX_WORD_LENGTH.get(cellWidth);
            if (maxWordLength != null && formattedAnswer.length() > maxWordLength) {
              String splittedAnswer = splitLongWords(formattedAnswer, maxWordLength);
              if (formattedAnswer.startsWith('https://') || formattedAnswer.startsWith('http://')) {
                formattedAnswer = '<a href="' + formattedAnswer + '">' + splittedAnswer + '</a>';
              } else {
                formattedAnswer = splittedAnswer;
              }
            }

            strHTMLData += '<div class="x-line:533" style="font-size: 10pt;overflow-wrap: break-word;">' + formattedAnswer.replace('\n', '<br/>') + '</div>';

            if (wrp.isDisplaycomment && string.isNotEmpty(wrp.comment)) {
              strHTMLData += ' <b>Comments</b><br/>  ';
              strHTMLData += wrp.comment;
            }

            if (wrp.isApproveRequired && string.isNotEmpty(wrp.approveBy)) {
              strHTMLData += '<br/><span>Signature</span><br/>  ';
              strHTMLData += ' Signed by ' + wrp.approveBy + ' at ' + formatAnswer('DATETIME', null, null, wrp.approveOn, false) + '<br/> ';
            }

            strHTMLData += ' </div>';
          }
        } else if (wrp.contentType == RT_PE_TEXT_ONLY) {
          if (avoidcode) {
            strHTMLData += '</table><br/>';
            strHTMLData += '</div>';
            avoidcode = false;
          }
          //strHTMLData+='<div style=" width:100%">' ; margin:4px;
          /*   strHTMLData+='<div style="border-top:0px solid black;display:table; width:100%">' ; 
                    strHTMLData+= '<br/>' ;
                    strHTMLData+= '</div>' ;*/
          //  strHTMLData+='<div style="padding:4px;margin:0px;border: 1px solid black;"  >' ;
          strHTMLData += '<div style="padding:4px;margin:0px;vertical-align: top;border: 1px solid black;display:table-cell;width:' + (100 / sec.sectionCount) + '%"  >';

          //strHTMLData+=String.isBlank(wrp.description)? '':wrp.description ;
          strHTMLData += '<b>' + (wrp.isSkipNumbering ? wrp.question : ((++orderNumber) + '. ' + wrp.question)) + '</b>';
          strHTMLData += '<div >';
          strHTMLData += String.isBlank(wrp.description) ? '' : wrp.description;
          strHTMLData += '</div >';
          strHTMLData += '</div>';
        } else if ((wrp.contentType == 'Test Step')) {
          if (avoidcode) {
            strHTMLData += '</table><br/>';
            strHTMLData += '</div>';
            // strHTMLData+='<div style="display:inline-block;width:100%">' ;
            // strHTMLData+= '</div>' ;
            avoidcode = false;
          }
          //strHTMLData+='<div style=" width:100%">' ;
          strHTMLData += '<div style="border-top:0px solid black;margin:4px;display:table; width:100%">';
          strHTMLData += '<br/>';
          strHTMLData += '</div>';
          strHTMLData += '<div style=" width:' + (100 / sec.sectionCount) + '%">'; //display:inline-block;//border:1px solid black;

          //strHTMLData+='<table style="border-collapse: collapse; padding:0px;margin:0px;min-width: 100% !important; width:100%"> ';
          strHTMLData += '<table style="border-collapse: collapse; padding:0px;margin:0px;min-width: ' + (100 / sec.sectionCount) + '% !important; width:' + (100 / sec.sectionCount) + '%"> ';

          strHTMLData += '   <tr> ';
          strHTMLData +=
            '  <td  style="text-align: center; padding:4px;margin:0px;border:1px solid black;" colspan="6"><b>' +
            (wrp.isSkipNumbering ? wrp.question : ((++orderNumber) + '. ' + wrp.question)) +
            '</b>';
          strHTMLData += String.isBlank(wrp.description) ? '' : '<br/>' + wrp.description;
          strHTMLData += '  </td>';
          strHTMLData += '   </tr>';
          strHTMLData += '   <tr>';
          strHTMLData += '     <th style="padding:2px;border:1px solid black;" colspan="3"> <b> Excepted Result  </b>  </th>'; //width:50%
          strHTMLData += '     <th style="padding:2px;border:1px solid black;" colspan="3"> <b> Actual Result </b>   </th>';
          strHTMLData += '   </tr>';
          strHTMLData += '   <tr>';
          strHTMLData += '     <td style="padding:2px;border:1px solid black;" colspan="3"> ' + wrp.exceptedResult + ' </td>';
          strHTMLData += '     <td style="padding:2px;border:1px solid black;" colspan="3">' + wrp.actualResult + ' </td>';
          strHTMLData += '   </tr>';
          strHTMLData += '   <tr>';
          strHTMLData += '        <th style="padding:2px;border:1px solid black;" colspan="2"> <b> Step Result  </b> </th>';
          strHTMLData += '        <th style="padding:2px;border:1px solid black;" colspan="2"> <b> Date  </b> </th> ';
          strHTMLData += '        <th style="padding:2px;border:1px solid black;" colspan="2"> <b> Username  </b> </th> ';
          strHTMLData += '    </tr>';
          strHTMLData += '   <tr>';
          strHTMLData += '       <td style="padding:2px;border:1px solid black;" colspan="2">' + wrp.answer + '  </td> ';
          strHTMLData += '       <td style="padding:2px;border:1px solid black;" colspan="2">' + (wrp.dateData == null ? '' : wrp.dateData + '') + ' </td> ';
          strHTMLData += '       <td style="padding:2px;border:1px solid black;" colspan="2">' + wrp.username + '</td>  </tr>  ';
          strHTMLData += '</table>';
          strHTMLData += '</div>';
        } else if ((wrp.contentType == 'Table')) {
          Integer tableNumbering = 1;
          if (avoidcode) {
            strHTMLData += '</table><br/>';
            strHTMLData += '</div>';
            // strHTMLData+='<div style="dis   play:inline-block;width:100%">' ;
            // strHTMLData+='</div>' ;
            avoidcode = false;
          }
          //strHTMLData+='<div style=" width:100%">' ;
          strHTMLData += '<div style="border-top:0px solid black;margin:4px;display:table; width:100%">';

          strHTMLData += '<br/>';
          strHTMLData += '</div>';
          // strHTMLData+='<div style=" border: 1px solid black;width:'+ (100/sec.sectionCount)+'%">' ;
          strHTMLData +=
            '<div style="font-family: \'TT Norms Pro\', Aptos, Arial, Helvetica, sans-serif;font-size: 10pt;padding:0px  !important;border:1px solid black; width:' +
            (100 / sec.sectionCount) +
            '%">';

          /* strHTMLData+='     <div style=" padding:4px;margin:0px; ">';
                    strHTMLData+='     <div>';
                    strHTMLData+='         <b>'+  (wrp.isSkipNumbering ? wrp.tableName :((++orderNumber )+ '. ' + wrp.tableName)) +'</b>';
                    strHTMLData+='     </div>';
                    strHTMLData+='<div >';
                    strHTMLData+=''+wrp.description+'';
                    strHTMLData+='     </div>'; 
                    strHTMLData+='     </div>';                  
*/

          // strHTMLData+='<table  style="border-collapse: collapse; padding:0px;margin:0px ; min-width: 100% !important;">';
          strHTMLData += '<table  style="-fs-table-paginate: paginate;border-collapse: collapse; padding:0px;margin:0px  !important; min-width: 100% !important;width: 100%">';

          strHTMLData += '         <tr>';
          strHTMLData += '         <td style="font-size: 10pt;padding:2px;border: 1px solid black;" colspan="' + wrp.tableQuetionSet.size() + 1 + '">';
          strHTMLData += '     <div style=" padding:4px;margin:0px; ">';
          strHTMLData += '     <div>';
          strHTMLData += '         <div>' + (wrp.isSkipNumbering ? wrp.tableName : ((++orderNumber) + '. ' + wrp.tableName)) + '</div>';
          strHTMLData += '     </div>';
          strHTMLData += '<div >';
          strHTMLData += '' + wrp.description + '';
          strHTMLData += '     </div>';
          strHTMLData += '     </div>';
          strHTMLData += '         </td>';
          strHTMLData += '         </tr>';

          strHTMLData += '     <tr>'; //thead
          strHTMLData += '     <td style="font-size: 10pt;text-align: center;padding:5px;border: 1px solid black; width:3px!important">&nbsp;</td>'; //th
          for (string qu : wrp.tableQuetionSet) {
            strHTMLData += '     <td style="font-size: 10pt;padding:2px;border: 1px solid black;padding-left: 4pt;"><span>' + qu + '</span></td>'; //th added bold
          }

          strHTMLData += '</tr>'; //thead
          for (List<string> ans : wrp.lstAns) {
            strHTMLData += '         <tr>';
            strHTMLData += '         <td style="font-size: 10pt;text-align: center;padding:5px!important;border: 1px solid black;width:30px!important">' + tableNumbering + '</td> ';
            tableNumbering++;
            for (string an : ans) {
              strHTMLData += '         <td style="font-size: 10pt;padding:2px;border: 1px solid black;padding-left: 5pt;">';
              strHTMLData += an.replace('\n', '<br/>');
              strHTMLData += '         </td>';
            }
            strHTMLData += '         </tr>';
          }
          strHTMLData += '</table> ';

          strHTMLData += '</div>';
        }
      }

      if (proExeRecordType != 'Training Effectiveness') {
        strHTMLData += '</div>';
      }
    }

    if (avoidcode) {
      strHTMLData += '</table> ';
      strHTMLData += '</div>';
      // strHTMLData+='<div style="display:inline-block;width:100%">' ;
      // strHTMLData+= '</div>' ;
      avoidcode = false;
    }

    strHTMLData += '</div></div>';
    System.debug('strHTMLDatastrHTMLData==>' + strHTMLData);
    return strHTMLData;
  }

  public String formatAnswer(String pContentType, String pStringAnswer, Date pDateAnswer, Datetime pDateTimeAnswer, Boolean pConvertoAspose) {
    String retAnswer = '';
    if (pContentType.toUpperCase().trim() == 'DATETIME') {
      if (pDateTimeAnswer != null) {
        if (pConvertoAspose) {
          Integer timeZone = 0;
          try {
            timeZone = integer.valueof(CompSuite__Aspose_Utils__c.getValues('PdfTimeZone').CompSuite__value__c);
          } catch (exception exp) {
            timeZone = 0;
          }

          pDateTimeAnswer = pDateTimeAnswer.addHours(timeZone);
        }

        retAnswer = pDateTimeAnswer.format('MMM dd, yyyy, hh:mm a', UserInfo.getTimeZone().toString());
      }
    } else if (pContentType.toUpperCase().trim() == 'DATE') {
      //Date
      if (pDateAnswer != null) {
        DateTime dt = DateTime.newInstance(pDateAnswer.year(), pDateAnswer.month(), pDateAnswer.day());
        retAnswer = dt.format('MMM dd, yyyy', UserInfo.getTimeZone().toString());
      }
    } else {
      retAnswer = pStringAnswer == null ? '' : pStringAnswer.replace('\n', '<br/>');
    }

    return retAnswer;
  }
  private static String splitLongWords(String str, Integer maxLength) {
    if (str == null || str.length() <= maxLength) {
      return str;
    }
    String[] words = str.split(' ');
    Boolean hasLongWord = false;

    for (Integer i = 0; i < words.size(); i++) {
      if (words[i].length() > maxLength) {
        hasLongWord = true;
        words[i] = splitWord(words[i], maxLength, '- ');
      }
    }
    if (hasLongWord) {
      return String.join(words, ' ');
    } else {
      return str;
    }
  }

  private static String splitWord(String str, Integer maxLength, String delimiter) {
    if (str == null || str.length() <= maxLength) {
      return str;
    }
    List<String> parts = new List<String>();
    while (str.length() > maxLength) {
      parts.add(str.left(maxLength));
      str = str.substring(maxLength);
    }
    if (str.length() > 0) {
      parts.add(str);
    }

    return String.join(parts, delimiter);
  }

  public List<WrpSections> lstwrpSections { get; set; }
  public List<WrpCmpContent> lstwrp { get; set; }

  // Wrapper Class
  public class WrpCmpContent {
    @AuraEnabled
    public Integer columnCount { get; set; } // NEW FIELD for width-based layout
    @AuraEnabled
    public boolean isCorrect { get; set; }
    @AuraEnabled
    public boolean isCritical { get; set; }
    @AuraEnabled
    public string expectedValue { get; set; }
    @AuraEnabled
    public string expectedNumericalRange { get; set; }
    @AuraEnabled
    public string score { get; set; }
    @AuraEnabled
    public boolean isDisplaycomment { get; set; }
    @AuraEnabled
    public string examType { get; set; }
    @AuraEnabled
    public boolean isSkipNumbering { get; set; }
    @AuraEnabled
    public Integer orderNumber { get; set; }
    @AuraEnabled
    public string comment { get; set; }
    @AuraEnabled
    public String username { get; set; }
    @AuraEnabled
    public date dateData { get; set; }
    @AuraEnabled
    public datetime datetimeData { get; set; }
    @AuraEnabled
    public String approveBy { get; set; }
    @AuraEnabled
    public datetime approveOn { get; set; }
    @AuraEnabled
    public String question { get; set; }
    @AuraEnabled
    public String choice { get; set; }
    @AuraEnabled
    public String actualResult { get; set; }
    @AuraEnabled
    public String exceptedResult { get; set; }
    @AuraEnabled
    public String answer { get; set; }
    @AuraEnabled
    public String description { get; set; }
    @AuraEnabled
    public String contentType { get; set; }
    @AuraEnabled
    public String tableName { get; set; }
    @AuraEnabled
    public boolean isTable { get; set; }
    @AuraEnabled
    public boolean isApproveRequired { get; set; }
    @AuraEnabled
    public list<string> tableQuetionSet { get; set; }
    @AuraEnabled
    public List<list<string>> lstAns { get; set; }
    @AuraEnabled
    public Map<String, list<String>> maptabledata { get; set; }
    @AuraEnabled
    public List<WrpCmpContent> tableElement { get; set; }
    public WrpCmpContent() {
      columnCount = 1;
      tableElement = new List<WrpCmpContent>();
      expectedValue = '';
      expectedNumericalRange = '';
      isCritical = false;
      score = '';
      examType = '';
      orderNumber = 0;
      exceptedResult = '';
      actualResult = '';
      contentType = '';
      description = '';
      question = '';
      approveBy = '';
      username = '';
      choice = '';
      answer = '';
      tableName = '';
      isApproveRequired = false;
      isSkipNumbering = false;
      isTable = false;
      isDisplaycomment = false;
      maptabledata = new Map<String, list<String>>();
      lstAns = new List<list<string>>();
      tableQuetionSet = new List<string>();
    }
  }
  public class WrpSections {
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public Integer sectionCount { get; set; }
    @AuraEnabled
    public Integer maxColumns { get; set; } // NEW FIELD for tracking grid columns
    @AuraEnabled
    public List<WrpCmpContent> lstwrp { get; set; }
    public WrpSections() {
      lstwrp = new List<WrpCmpContent>();
      sectionCount = 1;
      maxColumns = 1;
      name = '';
    }
  }
}