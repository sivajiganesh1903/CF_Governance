public class PMDViolationsReport implements Database.Batchable<SObject>, Database.Stateful {
    private Map<String, Map<String, Integer>> violationCountsByOrg;
    private List<copado__Org__c> orgCreds;
    private String htmlTableRows;
    private Map<String, List<String>> csvRowsByOrg;
    private Map<String, Integer> snoByOrg;
    
    public PMDViolationsReport() {
        violationCountsByOrg = new Map<String, Map<String, Integer>>();
        htmlTableRows = '';
        csvRowsByOrg = new Map<String, List<String>>();
        snoByOrg = new Map<String, Integer>();
        
        orgCreds = [SELECT Id, Name, Weekly_PMD_Report__c, (SELECT Id, Name, CreatedDate FROM copado__Static_Code_Analysis_Results__r 
                                                            ORDER BY CreatedDate DESC LIMIT 1) FROM copado__Org__c 
                    WHERE Weekly_PMD_Report__c = true WITH SECURITY_ENFORCED];
        if(!orgCreds.isEmpty()) {
            System.debug('First orgCred Id: ' + orgCreds[0].Id + ', Name: ' + orgCreds[0].Name);
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<Id> resultIds = new List<Id>();      
        for (copado__Org__c cred : orgCreds) {
            if (!cred.copado__Static_Code_Analysis_Results__r.isEmpty()) {
                resultIds.add(cred.copado__Static_Code_Analysis_Results__r[0].Id);
            } else {
                System.debug('No Static Code Analysis Results found for org: ' + cred.Name);
            }
        }        
        System.debug('Total Result Ids to query violations: ' + resultIds.size());
        
        return Database.getQueryLocator([
            SELECT Id, copado__File__c, copado__Line__c, copado__Rule__c, copado__Priority__c, copado__Message__c, 
            copado__Static_Code_Analysis_Result__r.copado__Org_Credential__r.Name FROM copado__Static_Code_Analysis_Violation__c 
            WHERE copado__Static_Code_Analysis_Result__c IN :resultIds ORDER BY copado__Static_Code_Analysis_Result__r.copado__Org_Credential__r.Name, 
            copado__Priority__c ASC]);
    }
    
    public void execute(Database.BatchableContext bc, List<copado__Static_Code_Analysis_Violation__c> scope) {        
        Map<String, List<copado__Static_Code_Analysis_Violation__c>> violationsByOrg = 
            new Map<String, List<copado__Static_Code_Analysis_Violation__c>>();
        
        // Group violations by org
        for (copado__Static_Code_Analysis_Violation__c v : scope) {
            String orgName = v.copado__Static_Code_Analysis_Result__r.copado__Org_Credential__r.Name;
            
            if (!violationsByOrg.containsKey(orgName)) {
                violationsByOrg.put(orgName, new List<copado__Static_Code_Analysis_Violation__c>());
            }
            violationsByOrg.get(orgName).add(v);
        }
        
        // Process each org's violations
        for (String orgName : violationsByOrg.keySet()) {
            List<copado__Static_Code_Analysis_Violation__c> violations = violationsByOrg.get(orgName);          
            Integer p1 = 0, p2 = 0, p3 = 0, p4 = 0, p5 = 0;
            
            // Initialize S.No counter for this org if not exists
            if (!snoByOrg.containsKey(orgName)) {
                snoByOrg.put(orgName, 1);
            }
            Integer sno = snoByOrg.get(orgName);
            
            // Initialize CSV rows list for this org if not exists
            if (!csvRowsByOrg.containsKey(orgName)) {
                csvRowsByOrg.put(orgName, new List<String>());
            }
            List<String> csvRows = csvRowsByOrg.get(orgName);
            
            // Process violations and build CSV rows
            for (copado__Static_Code_Analysis_Violation__c v : violations) {
                // Build CSV row - escape message properly
                String message = v.copado__Message__c != null ? 
                    v.copado__Message__c.escapeCsv() : '';
                
                csvRows.add(sno + ',' + 
                            (v.copado__File__c != null ? v.copado__File__c : '') + ',' + 
                            (v.copado__Line__c != null ? String.valueOf(v.copado__Line__c) : '') + ',' +
                            (v.copado__Rule__c != null ? v.copado__Rule__c : '') + ',' + 
                            (v.copado__Priority__c != null ? String.valueOf(v.copado__Priority__c) : '') + ',' +
                            message);              
                sno++;
                
                // Count priorities
                if (v.copado__Priority__c != null) {
                    switch on String.valueOf(v.copado__Priority__c) {
                        when '1' { p1++; }
                        when '2' { p2++; }
                        when '3' { p3++; }
                        when '4' { p4++; }
                        when '5' { p5++; }
                    }
                }
            }
            
            // Update S.No counter for next batch
            snoByOrg.put(orgName, sno);
            
            // Initialize or update violation counts
            if (!violationCountsByOrg.containsKey(orgName)) {
                violationCountsByOrg.put(orgName, new Map<String, Integer>{
                    'P1' => 0, 'P2' => 0, 'P3' => 0, 'P4' => 0, 'P5' => 0
                        });
            }
            
            Map<String, Integer> counts = violationCountsByOrg.get(orgName);
            counts.put('P1', counts.get('P1') + p1);
            counts.put('P2', counts.get('P2') + p2);
            counts.put('P3', counts.get('P3') + p3);
            counts.put('P4', counts.get('P4') + p4);
            counts.put('P5', counts.get('P5') + p5);
        }
        
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('--- Finish Method ---');
        
        // Build HTML table rows ONCE in finish
        htmlTableRows = '';
        for (String orgKey : violationCountsByOrg.keySet()) {
            Map<String, Integer> orgCounts = violationCountsByOrg.get(orgKey);
            htmlTableRows += '<tr>' +
                '<td style="padding: 8px;">' + orgKey + '</td>' +
                '<td style="padding: 8px;">' + orgCounts.get('P1') + '</td>' +
                '<td style="padding: 8px;">' + orgCounts.get('P2') + '</td>' +
                '<td style="padding: 8px;">' + orgCounts.get('P3') + '</td>' +
                '<td style="padding: 8px;">' + orgCounts.get('P4') + '</td>' +
                '<td style="padding: 8px;">' + orgCounts.get('P5') + '</td>' +
                '</tr>';
        }
        
        String finalBody = 'Hi Team,<br><br>Here\'s the PMD Report generated for the following Environments:<br><br>' +
            '<table border="1" style="border-collapse: collapse; text-align: center;">' +
            '<tr>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Environment Name</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P1 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P2 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P3 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P4 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P5 Violations</th>' +
            '</tr>' + htmlTableRows + '</table><br>Thanks & Regards,<br>DevOps Team';
        
        // Build CSV attachments from rows
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        for (String orgName : csvRowsByOrg.keySet()) {
            List<String> rows = csvRowsByOrg.get(orgName);
            
            // Build CSV with header + all rows
            String csvContent = 'SNo,File,Line,Rule,Priority,Message\n' + String.join(rows, '\n');            
            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setFileName(orgName + '_PMD_Report.csv');
            att.setBody(Blob.valueOf(csvContent));
            attachments.add(att);
        }
        
        // Fetch email configuration
        Set<String> toAddresses = new Set<String>();
        String orgAddressFromMeta;
        
        List<PMD_Report__mdt> metaForAddress = [SELECT Org_Address__c FROM PMD_Report__mdt WHERE DeveloperName = 'PMD_Report_Rec' LIMIT 1];
        
        if (!metaForAddress.isEmpty() && String.isNotBlank(metaForAddress[0].Org_Address__c)) {
            orgAddressFromMeta = metaForAddress[0].Org_Address__c;
        }
        
        List<OrgWideEmailAddress> orgAddresses = new List<OrgWideEmailAddress>();
        if (String.isNotBlank(orgAddressFromMeta)) {
            orgAddresses = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :orgAddressFromMeta LIMIT 1];           
            if (!orgAddresses.isEmpty()) {
                System.debug('orgAddresses: ' + orgAddresses[0].Id);
            } else {
                System.debug('No OrgWideEmailAddress found for: ' + orgAddressFromMeta);
            }
        }
        
        List<PMD_Report__mdt> meta = [SELECT Public_Group__c, Email_Address__c, Org_Address__c FROM PMD_Report__mdt 
                                      WHERE DeveloperName = 'PMD_Report_Rec' LIMIT 1];
        
        if (!meta.isEmpty()) {
            if (String.isNotBlank(meta[0].Email_Address__c)) {
                toAddresses.addAll(meta[0].Email_Address__c.split(','));
                System.debug('Added emails from metadata: ' + meta[0].Email_Address__c);
            }
            
            if (String.isNotBlank(meta[0].Public_Group__c)) {
                List<String> groupNames = meta[0].Public_Group__c.split(',');
                System.debug('Group names from metadata: ' + groupNames);              
                List<Group> groups = [SELECT Id, (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE Name IN :groupNames];
                
                Set<Id> userIds = new Set<Id>();
                for (Group g : groups) {
                    for (GroupMember gm : g.GroupMembers) {
                        userIds.add(gm.UserOrGroupId);
                    }
                }
                
                for (User u : [SELECT Email FROM User WHERE Id IN :userIds]) {
                    toAddresses.add(u.Email);
                }
            }
        }
        
        List<String> toAddressesList = new List<String>(toAddresses);
        if (!toAddressesList.isEmpty() && !orgAddresses.isEmpty()) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject('PMD Scan Report - ' + Date.today().format());
            email.setToAddresses(toAddressesList);
            email.setOrgWideEmailAddressId(orgAddresses[0].Id);
            email.setHtmlBody(finalBody);
            email.setFileAttachments(attachments);
            
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                System.debug('Email sent successfully to: ' + email.getToAddresses());
            } catch (Exception e) {
                System.debug('Failed to send email: ' + e.getMessage());
            }
        } else {
            System.debug('No recipients or Org Wide Address missing. Email not sent.');
        }
    }
}