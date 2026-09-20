public class PMDReport {
    public static Map<String, String> intPMDReport() {
        Map<String, String> resultViol = new Map<String, String>();        
        List<copado__Org__c> orgCreds = [SELECT Id, Name, Weekly_PMD_Report__c, (SELECT Id, Name, CreatedDate FROM copado__Static_Code_Analysis_Results__r ORDER BY CreatedDate DESC LIMIT 2) FROM copado__Org__c WHERE Weekly_PMD_Report__c = true];
        
        String htmlBody = 'Hi Team, <br><br>Here\'s the PMD Report generated for the following Environments:<br><br>' +
            '<table border="1" style="border-collapse: collapse; text-align: center;">' +
            '<tr>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Environment Name</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P1 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Δ P1</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P2 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Δ P2</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P3 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Δ P3</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P4 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Δ P4</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P5 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Δ P5</th>' +
            '</tr>';
        
        for (copado__Org__c cred : orgCreds) {
    if (cred != null && cred.copado__Static_Code_Analysis_Results__r.size() >= 1) {
        Id currentResultId = cred.copado__Static_Code_Analysis_Results__r[0].Id;
        Id previousResultId = (cred.copado__Static_Code_Analysis_Results__r.size() > 1) ? cred.copado__Static_Code_Analysis_Results__r[1].Id : null;
        
        // Get violations by priority for current and previous results
        Map<String, Set<String>> currentViolationsByPriority = getUniqueViolationsByPriority(currentResultId);
        Map<String, Set<String>> previousViolationsByPriority = previousResultId != null ? getUniqueViolationsByPriority(previousResultId) : new Map<String, Set<String>>();
        
        // Calculate delta for each priority
        Integer deltaP1 = countNewViolations(currentViolationsByPriority.get('1'), previousViolationsByPriority.get('1'));
        Integer deltaP2 = countNewViolations(currentViolationsByPriority.get('2'), previousViolationsByPriority.get('2'));
        Integer deltaP3 = countNewViolations(currentViolationsByPriority.get('3'), previousViolationsByPriority.get('3'));
        Integer deltaP4 = countNewViolations(currentViolationsByPriority.get('4'), previousViolationsByPriority.get('4'));
        Integer deltaP5 = countNewViolations(currentViolationsByPriority.get('5'), previousViolationsByPriority.get('5'));
        
        // Add row to the HTML table
        htmlBody += '<tr>' +
            '<td style="padding: 8px;">' + cred.Name + '</td>' +
            '<td style="padding: 8px;">' + currentViolationsByPriority.get('1').size() + '</td>' +
            '<td style="padding: 8px; color:' + getDeltaColor(deltaP1) + ';">' + formatDelta(deltaP1) + '</td>' +
            '<td style="padding: 8px;">' + currentViolationsByPriority.get('2').size() + '</td>' +
            '<td style="padding: 8px; color:' + getDeltaColor(deltaP2) + ';">' + formatDelta(deltaP2) + '</td>' +
            '<td style="padding: 8px;">' + currentViolationsByPriority.get('3').size() + '</td>' +
            '<td style="padding: 8px; color:' + getDeltaColor(deltaP3) + ';">' + formatDelta(deltaP3) + '</td>' +
            '<td style="padding: 8px;">' + currentViolationsByPriority.get('4').size() + '</td>' +
            '<td style="padding: 8px; color:' + getDeltaColor(deltaP4) + ';">' + formatDelta(deltaP4) + '</td>' +
            '<td style="padding: 8px;">' + currentViolationsByPriority.get('5').size() + '</td>' +
            '<td style="padding: 8px; color:' + getDeltaColor(deltaP5) + ';">' + formatDelta(deltaP5) + '</td>' +
            '</tr>';
    }
}

        htmlBody += '</table><br>Thanks & Regards,<br>DevOps Team';
        
        return SendCsvEmail(htmlBody);
    }

    private static Map<String, Set<String>> getUniqueViolationsByPriority(Id analysisResultId) {
        // Initialize the map with all priority levels
        Map<String, Set<String>> violationsByPriority = new Map<String, Set<String>>{
            '1' => new Set<String>(), // P1
            '2' => new Set<String>(), // P2
            '3' => new Set<String>(), // P3
            '4' => new Set<String>(), // P4
            '5' => new Set<String>()  // P5
        };
        
        // Query violations for the given analysis result
        List<copado__Static_Code_Analysis_Violation__c> resultViolations = [
            SELECT copado__Priority__c, copado__File__c, copado__Rule__c, copado__Message__c
            FROM copado__Static_Code_Analysis_Violation__c 
            WHERE copado__Static_Code_Analysis_Result__r.Id = :analysisResultId
        ];
        
        // Categorize violations by priority
        for (copado__Static_Code_Analysis_Violation__c violation : resultViolations) {
            if (violation.copado__Priority__c != null) {
                // Convert Decimal priority to String
                String priority = String.valueOf(violation.copado__Priority__c.intValue()); // Convert to integer first, then to string
                if (violationsByPriority.containsKey(priority)) {
                    String key = violation.copado__File__c + '|' + violation.copado__Rule__c + '|' + violation.copado__Message__c;
                    violationsByPriority.get(priority).add(key);
                }
            }
        }
        
        return violationsByPriority;
    }
    
    private static Integer countNewViolations(Set<String> currentViolations, Set<String> previousViolations) {
        if (currentViolations == null) return 0;
        if (previousViolations == null) return currentViolations.size();
        
        Integer count = 0;
        for (String violation : currentViolations) {
            if (!previousViolations.contains(violation)) {
                count++;
            }
        }
        return count;
    }
    
    private static String formatDelta(Integer delta) {
        return delta == 0 ? '-' : (delta > 0 ? '+' : '') + delta;
    }
    
    private static String getDeltaColor(Integer delta) {
        return delta > 0 ? 'red' : (delta < 0 ? 'green' : 'black');
    }
    
    public static Map<String, String> SendCsvEmail(String htmlBody) {
        Map<String, String> result = new Map<String, String>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('PMD Report');
        email.setHtmlBody(htmlBody);
        email.setToAddresses(new List<String>{'dipali.m@cloudfulcrum.com'});
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        return result;
    } 
}