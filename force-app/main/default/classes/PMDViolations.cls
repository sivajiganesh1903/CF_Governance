public class PMDViolations {
    
    public static void credRelatedViolations() {
        // Query org and related Static Code Analysis Results in a single SOQL
        List<copado__Org__c> credSCAResults = [SELECT Id, Name, 
                                               (SELECT Id, Name, copado__Critical__c, copado__Highest_Priority_Violation__c,
                                                copado__Score_v11__c, copado__Number_of_Violations__c, copado__Major__c, 
                                                copado__Minor__c FROM copado__Static_Code_Analysis_Results__r 
                                                ORDER BY CreatedDate DESC LIMIT 2) 
                                               FROM copado__Org__c WHERE Name = 'Eric Varela TrnProd2'];
        System.debug('Credential Related SCAs: ++++++ ' + credSCAResults);
        
        // Prepare to send an email with the violation comparison
        String htmlBody = 'Hi Team, <br><br>Here\'s the comparison of PMD Violations before and after deployment:<br><br>' +
            '<table border="1" style="border-collapse: collapse; text-align: center;">' +
            '<tr>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Before Prod Deployment</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">After Prod Deployment</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Priority Violation Status</th>' +
            '</tr>';
        
        // Variables to store the violation counts
        Integer totalP1CountBefore = 0, totalP2CountBefore = 0, totalP3CountBefore = 0, totalP4CountBefore = 0, totalP5CountBefore = 0;
        Integer totalP1CountAfter = 0, totalP2CountAfter = 0, totalP3CountAfter = 0, totalP4CountAfter = 0, totalP5CountAfter = 0;
        
        // Intialize the Total Vaiolations
        Decimal beforeHighestPriorityViolation = 0;
        Decimal afterHighestPriorityViolation = 0;
        
        // CSV header for before and after violations
        String beforeCSV = 'S.No,File,Line,Rule,Priority,Message\n'; 
        String afterCSV = 'S.No,File,Line,Rule,Priority,Message\n';
        
        // Process the results and calculate the violations for each priority
        for (copado__Org__c org : credSCAResults) {
            if (org.copado__Static_Code_Analysis_Results__r.size() == 2) {
                copado__Static_Code_Analysis_Result__c afterResult = org.copado__Static_Code_Analysis_Results__r[0];
                copado__Static_Code_Analysis_Result__c beforeResult = org.copado__Static_Code_Analysis_Results__r[1];
                
                afterHighestPriorityViolation = afterResult.copado__Number_of_Violations__c;
                beforeHighestPriorityViolation = beforeResult.copado__Number_of_Violations__c;
                
                // Fetch the violations for both before and after results
                Map<Id, List<copado__Static_Code_Analysis_Violation__c>> beforeViolationsMap = getViolationsByResult(new Set<Id>{beforeResult.Id});
                Map<Id, List<copado__Static_Code_Analysis_Violation__c>> afterViolationsMap = getViolationsByResult(new Set<Id>{afterResult.Id});
                
                // Count the priority violations for beforeResult
                if (beforeViolationsMap.containsKey(beforeResult.Id)) {
                    Integer sno = 1; // Serial number for CSV
                    for (copado__Static_Code_Analysis_Violation__c violation : beforeViolationsMap.get(beforeResult.Id)) {
                        beforeCSV += sno + ',' + violation.copado__File__c + ',' + violation.copado__Line__c + ',' + 
                            violation.copado__Rule__c + ',' + violation.copado__Priority__c + ',' + 
                            violation.copado__Message__c.escapeCsv() + '\n';
                        sno++;  // Increment the serial number for the next record
                        // Count priority violations
                        switch on String.valueOf(violation.copado__Priority__c) {
                            when '1' { totalP1CountBefore++; }
                            when '2' { totalP2CountBefore++; }
                            when '3' { totalP3CountBefore++; }
                            when '4' { totalP4CountBefore++; }
                            when '5' { totalP5CountBefore++; }
                        }
                    }
                }
                
                // Count the priority violations for afterResult
                if (afterViolationsMap.containsKey(afterResult.Id)) {
                    Integer sno = 1; // Serial number for CSV
                    for (copado__Static_Code_Analysis_Violation__c violation : afterViolationsMap.get(afterResult.Id)) {
                        afterCSV += sno + ',' + violation.copado__File__c + ',' + violation.copado__Line__c + ',' + 
                            violation.copado__Rule__c + ',' + violation.copado__Priority__c + ',' + 
                            violation.copado__Message__c.escapeCsv() + '\n';
                        sno++;  // Increment the serial number for the next record
                        // Count priority violations
                        switch on String.valueOf(violation.copado__Priority__c) {
                            when '1' { totalP1CountAfter++; }
                            when '2' { totalP2CountAfter++; }
                            when '3' { totalP3CountAfter++; }
                            when '4' { totalP4CountAfter++; }
                            when '5' { totalP5CountAfter++; }
                        }
                    }
                }
            }
        }
        
        // Add rows to the email body table for each priority
        htmlBody += generateViolationRow('P1', totalP1CountBefore, totalP1CountAfter);
        htmlBody += generateViolationRow('P2', totalP2CountBefore, totalP2CountAfter);
        htmlBody += generateViolationRow('P3', totalP3CountBefore, totalP3CountAfter);
        htmlBody += generateViolationRow('P4', totalP4CountBefore, totalP4CountAfter);
        htmlBody += generateViolationRow('P5', totalP5CountBefore, totalP5CountAfter);
        
        // Add Total violations for Pre-Deployment and Post-Deployments
        htmlBody += 'Total Pre-Deployment Violations = ' + beforeHighestPriorityViolation + '<br>';
        htmlBody += 'Total Post-Deployment Violations = ' + afterHighestPriorityViolation + '<br>';
        
        if (beforeHighestPriorityViolation == afterHighestPriorityViolation) {
            htmlBody += 'No Change in Number of Violations. <br><br>';
        } else if (beforeHighestPriorityViolation > afterHighestPriorityViolation) {
            htmlBody += 'Post-deployment violations have decreased. <br><br>';
        } else if (beforeHighestPriorityViolation < afterHighestPriorityViolation) {
            htmlBody += 'Post-deployment violations have increased.<br><br>';
        }
        
        htmlBody += 'Below is a detailed comparison of violations before and after the Production Deployment: <br><br> ';
        htmlBody += '</table><br><br>Best Regards,<br>DevOps Team';
        
        // Fetch the PMD Report metadata
        List<PMD_Report__mdt> pmdReportList = [SELECT Id, Org_Address__c, Public_Group__c FROM PMD_Report__mdt LIMIT 1];        
        PMD_Report__mdt pmdReport = pmdReportList[0];
        System.debug('PMD report data: +++++ ' + pmdReport);
        
        // Fetch the OrgWideEmailAddress based on the display name
        List<OrgWideEmailAddress> orgAddressList = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :pmdReport.Org_Address__c LIMIT 1];
        System.debug('Org Wide Email Address: +++++ ' + orgAddressList);
        
        if (orgAddressList.isEmpty()) {
            System.debug('No OrgWideEmailAddress found for the specified display name.');
            return; // Exit if no address found
        }
        
        OrgWideEmailAddress orgAddress = orgAddressList[0];
        
        // Prepare CSV attachments
        Messaging.EmailFileAttachment beforeAttachment = new Messaging.EmailFileAttachment();
        beforeAttachment.setFileName('Before_Violations.csv');
        beforeAttachment.setBody(Blob.valueOf(beforeCSV));
        
        Messaging.EmailFileAttachment afterAttachment = new Messaging.EmailFileAttachment();
        afterAttachment.setFileName('After_Violations.csv');
        afterAttachment.setBody(Blob.valueOf(afterCSV));
        
        // Send the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] {'sivaji.g@cloudfulcrum.com', 'dipali.m@cloudfulcrum.com'});
        email.setOrgWideEmailAddressId(orgAddress.Id);
        email.setSubject('PMD Violations Comparison Report');
        email.setHtmlBody(htmlBody);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { beforeAttachment, afterAttachment });
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
    private static String generateViolationRow(String priority, Integer beforeCount, Integer afterCount) {
        return '<tr>' +
            '<td>' + priority + '</td>' +
            '<td>' + beforeCount + '</td>' +
            '<td>' + afterCount + '</td>' +
            '<td>' + ((beforeCount > afterCount) ? 'Decreased' : (beforeCount < afterCount ? 'Increased' : 'No Change')) + '</td>' +
            '</tr>';
    }
    
    private static Map<Id, List<copado__Static_Code_Analysis_Violation__c>> getViolationsByResult(Set<Id> resultIds) {
        Map<Id, List<copado__Static_Code_Analysis_Violation__c>> violationsMap = new Map<Id, List<copado__Static_Code_Analysis_Violation__c>>();
        
        List<copado__Static_Code_Analysis_Violation__c> violations = [SELECT Id, copado__File__c, copado__Line__c, 
                                                                      copado__Rule__c, copado__Priority__c, 
                                                                      copado__Message__c, copado__Static_Code_Analysis_Result__c 
                                                                      FROM copado__Static_Code_Analysis_Violation__c 
                                                                      WHERE copado__Static_Code_Analysis_Result__c IN :resultIds];
        
        for (copado__Static_Code_Analysis_Violation__c violation : violations) {
            if (!violationsMap.containsKey(violation.copado__Static_Code_Analysis_Result__c)) {
                violationsMap.put(violation.copado__Static_Code_Analysis_Result__c, new List<copado__Static_Code_Analysis_Violation__c>());
            }
            violationsMap.get(violation.copado__Static_Code_Analysis_Result__c).add(violation);
        }
        return violationsMap;
    }
}