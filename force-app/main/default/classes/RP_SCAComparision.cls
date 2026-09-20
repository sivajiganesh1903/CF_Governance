public class RP_SCAComparision {
    
    @AuraEnabled
    public static String comparisionResults(Id recordId) {
        try {
            // Query the Release Playbook record
            Release_Playbook__c playBook = [SELECT Id, Name FROM Release_Playbook__c WHERE Id = :recordId LIMIT 1];
            System.debug('Release Playbook: ' + playBook);
            
            // Query related items
            List<Release_Playbook_Item__c> bookRelatedItems = [SELECT Id, Name, Area__c, Execution_Sequence__c, Order__c, 
                                                               Release_Playbook__c, SCA__c, Status__c, Task_Description__c 
                                                               FROM Release_Playbook_Item__c 
                                                               WHERE Release_Playbook__c = :playBook.Id AND SCA__c = true];
            System.debug('Filtered SCA True Items: ' + bookRelatedItems);
            
            if (bookRelatedItems.isEmpty()) {
                System.debug('No SCA true items found for the given playbook');
                return '{"status":"no_items","message":"No SCA items found for the given release playbook."}';
            }
            
            // Process sub-items and compare SCA results
            String result = processAndCompareSCA(bookRelatedItems, recordId);
            return '{"status":"success","message":"' + result + '"}';
            
        } catch (QueryException e) {
            System.debug('QueryException: ' + e.getMessage());
            return '{"status":"error","message":"Query failure: ' + e.getMessage() + '"}';
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return '{"status":"error","message":"An unexpected error occurred: ' + e.getMessage() + '"}';
        }
    }
    
    private static String processAndCompareSCA(List<Release_Playbook_Item__c> items, Id recordId) {
        System.debug('Inside processAndCompareSCA method');
        Set<Id> itemIds = new Set<Id>();
        Map<Id, Release_Playbook_Item__c> itemMap = new Map<Id, Release_Playbook_Item__c>();
        
        for (Release_Playbook_Item__c item : items) {
            itemIds.add(item.Id);
            itemMap.put(item.Id, item);
        }
        
        // Query sub-items
        List<Release_Playbook_Sub_Item__c> subItems = [SELECT Id, Name, Previous_SCA__c, Static_Code_Analysis_Result__c, 
                                                       Release_Playbook_Item__c 
                                                       FROM Release_Playbook_Sub_Item__c 
                                                       WHERE Release_Playbook_Item__c IN :itemIds];
        System.debug('Sub Items: ' + subItems);
        
        if (subItems.isEmpty()) {
            System.debug('No sub-items found for the given SCA items');
            return 'No sub-items found';
        }
        
        // Categorize sub-items
        List<Release_Playbook_Sub_Item__c> beforeDeploymentSubItems = new List<Release_Playbook_Sub_Item__c>();
        List<Release_Playbook_Sub_Item__c> afterDeploymentSubItems = new List<Release_Playbook_Sub_Item__c>();
        
        for (Release_Playbook_Sub_Item__c subItem : subItems) {
            Release_Playbook_Item__c parentItem = itemMap.get(subItem.Release_Playbook_Item__c);
            if (parentItem != null) {
                if (parentItem.Execution_Sequence__c == 'Before Deployment') {
                    beforeDeploymentSubItems.add(subItem);
                } else if (parentItem.Execution_Sequence__c == 'After Deployment') {
                    afterDeploymentSubItems.add(subItem);
                }
            }
        }
        
        System.debug('Before Deployment SubItem: '+beforeDeploymentSubItems);
        System.debug('After Deployment SubItem: '+afterDeploymentSubItems);
        
        if (beforeDeploymentSubItems.isEmpty() || afterDeploymentSubItems.isEmpty()) {
            System.debug('No deployment sub-items found for comparison.');
            return 'No before or after deployment sub-items found. Skipping comparison.';
        }
        
        // Compare SCA results
        String beforeSCA = beforeDeploymentSubItems[0].Static_Code_Analysis_Result__c;
        String afterSCA = afterDeploymentSubItems[0].Static_Code_Analysis_Result__c;
        
        System.debug('Before SCA: '+ beforeSCA);
        System.debug('After SCA: '+ afterSCA);
        
        if (String.isBlank(beforeSCA) || String.isBlank(afterSCA)) {
            System.debug('One or both of the SCA results are empty.');
            return 'Empty SCA results';
        }
        
        // Process violations and send email asynchronously
        processViolationsAsync(beforeSCA, afterSCA, recordId);

        return 'Comparison initiated. Email will be sent shortly.';
    }
    
    @future(callout = false)
    private static void processViolationsAsync(String beforeSCA, String afterSCA, Id recordId) {
        System.debug('Before SCA:' + beforeSCA);
        System.debug('After SCA:' + afterSCA);
        
        try {
            // Initialize variables
            String beforeCSV = 'S.No,File,Line,Rule,Priority,Message\n';
            String afterCSV = 'S.No,File,Line,Rule,Priority,Message\n';
            String htmlBody = 'Hi Team,<br><br>Here\'s the comparison of PMD Violations:<br><br>';
            
            Map<String, Integer> beforeCounts = new Map<String, Integer>{'P1' => 0, 'P2' => 0, 'P3' => 0, 'P4' => 0, 'P5' => 0};
                Map<String, Integer> afterCounts = new Map<String, Integer>{'P1' => 0, 'P2' => 0, 'P3' => 0, 'P4' => 0, 'P5' => 0};
                    
                    // Process violations for beforeSCA
                    List<copado__Static_Code_Analysis_Violation__c> beforeViolations = [
                        SELECT copado__File__c, copado__Line__c, copado__Rule__c, copado__Priority__c, copado__Message__c
                        FROM copado__Static_Code_Analysis_Violation__c
                        WHERE copado__Static_Code_Analysis_Result__c = :beforeSCA
                    ];
            beforeCSV = buildCSVAndCount(beforeViolations, beforeCSV, beforeCounts);
            
            // Process violations for afterSCA
            List<copado__Static_Code_Analysis_Violation__c> afterViolations = [
                SELECT copado__File__c, copado__Line__c, copado__Rule__c, copado__Priority__c, copado__Message__c
                FROM copado__Static_Code_Analysis_Violation__c
                WHERE copado__Static_Code_Analysis_Result__c = :afterSCA
            ];
            afterCSV = buildCSVAndCount(afterViolations, afterCSV, afterCounts);
            
            // Generate HTML comparison table
            htmlBody += generateHTMLComparisonTable(beforeCounts, afterCounts);
            htmlBody += '<br><br>Best Regards,<br>DevOps Team';
            
            // Send email
            sendEmailWithAttachments(htmlBody, beforeCSV, afterCSV);
            
            // Save comparison record
            saveComparisonRecord(recordId, beforeCounts, afterCounts, beforeSCA, afterSCA);
            
        } catch (Exception e) {
            System.debug('Error in processViolationsAsync: ' + e.getMessage());
        }
    }
    
    private static String buildCSVAndCount(List<copado__Static_Code_Analysis_Violation__c> violations, 
                                           String csv, Map<String, Integer> counts) {
                                               System.debug('Inside buildCSVAndCount Method');
                                               Integer sno = 1;
                                               
                                               for (copado__Static_Code_Analysis_Violation__c violation : violations) {
                                                   csv += sno + ',' +
                                                       (violation.copado__File__c != null ? violation.copado__File__c : '') + ',' +
                                                       (violation.copado__Line__c != null ? String.valueOf(violation.copado__Line__c) : '') + ',' +
                                                       (violation.copado__Rule__c != null ? violation.copado__Rule__c : '') + ',' +
                                                       (violation.copado__Priority__c != null ? String.valueOf(violation.copado__Priority__c) : '') + ',' +
                                                       (violation.copado__Message__c != null ? violation.copado__Message__c.escapeCsv() : '') + '\n';
                                                   sno++;
                                                   
                                                   // Ensure the priority key is properly formatted and increment its count
                                                   String priorityKey = 'P' + String.valueOf(violation.copado__Priority__c);
                                                   if (!counts.containsKey(priorityKey)) {
                                                       counts.put(priorityKey, 0);
                                                   }
                                                   counts.put(priorityKey, counts.get(priorityKey) + 1);
                                               }
                                               System.debug('counts'+counts);
                                               System.debug('csv'+csv);
                                               return csv;
                                           }
    
    
    private static String generateHTMLComparisonTable(Map<String, Integer> beforeCounts, Map<String, Integer> afterCounts) {
        String html = '<table border="1" style="border-collapse: collapse; text-align: center;">'
            + '<tr><th>Priority</th><th>Before</th><th>After</th><th>Status</th></tr>';
        System.debug('Inside generateHTMLComparisonTable Method');
        
        for (String priority : beforeCounts.keySet()) {
            String status;
            if (beforeCounts.get(priority) > afterCounts.get(priority)) {
                status = 'Decreased';
            } else if (beforeCounts.get(priority) < afterCounts.get(priority)) {
                status = 'Increased';
            } else {
                status = 'No Change';
            }
            html += '<tr><td>' + priority + '</td>'
                + '<td>' + String.valueOf(beforeCounts.get(priority)) + '</td>'
                + '<td>' + String.valueOf(afterCounts.get(priority)) + '</td>'
                + '<td>' + status + '</td></tr>';
        }
        
        html += '</table>';
        System.debug('html'+html);
        return html;
    }
    
    
    private static void sendEmailWithAttachments(String htmlBody, String beforeCSV, String afterCSV) {
        System.debug('Inside sendEmailWithAttachments Method');
        
        // Fetch the PMD Report metadata
                    List<PMD_Report__mdt> pmdReportList = [SELECT Id, Org_Address__c, Public_Group__c FROM PMD_Report__mdt LIMIT 1];        
                    PMD_Report__mdt pmdReport = pmdReportList[0];
                    System.debug('PMD report data: ' + pmdReport);
                    List<Id> idList = new List<Id>();
                    List<String> mailToAddresses = new List<String>();
                    if (!pmdReportList.isEmpty()) {
                        // Split the Public_Group__c field by comma and store in a list
                        List<String> groupNames = pmdReportList[0].Public_Group__c.split(',');
                        System.debug('Group Name ++++++ :' + groupNames);
                        // Query the Group records for all group names
                        List<Group> groups = [SELECT Id, Name, (SELECT UserOrGroupId FROM GroupMembers) 
                                              FROM Group WHERE Name IN :groupNames];
                        System.debug('Groups found: ' + groups);
                        
                        if (groups.isEmpty()) {
                            //result.put('ERROR', 'No groups found for the specified names.');
                            //return result;
                            System.debug('No Public Groups Found');
                        }
                        
                        // Collect all UserOrGroupIds from the queried groups
                        for (Group gp : groups) {
                            for (GroupMember gm : gp.GroupMembers) {
                                idList.add(gm.UserOrGroupId);
                            }
                        }
                        System.debug('Group of User Ids +++++ :' + idList);
                        
                        // Query the email addresses of the users in the groups
                        List<User> userList = [SELECT Id, Email FROM User WHERE Id IN :idList];
                     /*   for (User u : userList) {
                            mailToAddresses.add(u.Email);
                        }   */
                        System.debug('List of User Emails ++++++: ' + mailToAddresses);
                    } else {
                        //result.put('ERROR', 'No PMD Report Custom Metadata records found.');
                        //return result;
                        System.debug('No User Emails Found');
                    }
        
        // Fetch the OrgWideEmailAddress based on the display name
        List<OrgWideEmailAddress> orgAddressList = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :pmdReport.Org_Address__c LIMIT 1];
        System.debug('Org Wide Email Address: ' + orgAddressList);
        
        /* if (orgAddressList.isEmpty()) {
            System.debug('No OrgWideEmailAddress found for the specified display name.');
            return 'No OrgWideEmailAddress found'; 
        } */
        
        OrgWideEmailAddress orgAddress = orgAddressList[0];
        
        //Add Email extra email Ids
        mailToAddresses.add('dipali.m@cloudfulcrum.com');
        mailToAddresses.add('dipali24lingayat@gmail.com');
        mailToAddresses.add('sivajiganesh97@gmail.com');
        
                    
        
        Messaging.EmailFileAttachment beforeAttachment = new Messaging.EmailFileAttachment();
        beforeAttachment.setFileName('Before_Violations.csv');
        beforeAttachment.setBody(Blob.valueOf(beforeCSV));
        
        Messaging.EmailFileAttachment afterAttachment = new Messaging.EmailFileAttachment();
        afterAttachment.setFileName('After_Violations.csv');
        afterAttachment.setBody(Blob.valueOf(afterCSV));
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('PMD Violations Comparison Report');
        email.setHtmlBody(htmlBody);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {beforeAttachment, afterAttachment});
        email.setToAddresses(mailToAddresses); // Add actual recipient logic
        System.debug('setToAddresses: '+mailToAddresses);
        email.setOrgWideEmailAddressId(orgAddress.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
    private static void saveComparisonRecord(Id recordId, Map<String, Integer> beforeCounts, 
                                             Map<String, Integer> afterCounts, String beforeSCA, String afterSCA) {
                                                 
                                                 System.debug('Inside saveComparisonRecord Method');
                                                 Scan_Comparison__c scanComparison = new Scan_Comparison__c();
                                                 scanComparison.Release_Playbook__c = recordId;
                                                 scanComparison.Before_SCA_Result__c = beforeSCA;
                                                 scanComparison.After_SCA_Result__c = afterSCA;
                                                 scanComparison.Before_P1_Violations__c = beforeCounts.get('P1');
                                                 scanComparison.After_P1_Violations__c = afterCounts.get('P1');
                                                 scanComparison.Before_P2_Violations__c = beforeCounts.get('P2');
                                                 scanComparison.After_P2_Violations__c = afterCounts.get('P2');
                                                 scanComparison.Before_P3_Violations__c = afterCounts.get('P3');
                                                 scanComparison.After_P3_Violations__c = afterCounts.get('P3');
                                                 scanComparison.Before_P4_Violations__c = afterCounts.get('P4');
                                                 scanComparison.After_P4_Violations__c = afterCounts.get('P4');
                                                 scanComparison.Before_P5_Violations__c = afterCounts.get('P5');
                                                 scanComparison.After_P5_Violations__c = afterCounts.get('P5');
                                                 insert scanComparison;
                                             }
}