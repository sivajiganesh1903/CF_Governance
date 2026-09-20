/**
 * @description Fetches Static Code Analysis (SCA) results for different environments 
 * and sends a formatted email report to the relevant recipients.
 * @author Hareesh Kandharaboina
 * @date 19-03-2025
 */
public with sharing class PMDSCANReport {

    /**
     * @description Fetches Static Code Analysis (SCA) results and sends the report.
     * @throws Exception if there is an issue with fetching records or sending email.
     */
    public static void scaResultViolations() {
        List<copado__Org__c> orgCreds = [SELECT Id, Name, Weekly_PMD_Report__c, 
                                         (SELECT Id, Name, CreatedDate, P1_Violations__c, P2_Violations__c, P3_Violations__c, 
                                          P4_Violations__c, copado__Number_of_Violations__c 
                                          FROM copado__Static_Code_Analysis_Results__r ORDER BY CreatedDate DESC LIMIT 1) 
                                         FROM copado__Org__c WHERE Weekly_PMD_Report__c = true WITH SECURITY_ENFORCED];

        // HTML table header
        String htmlBody = generateHtmlTable(orgCreds);

        // Send the email
        sendEmail(htmlBody);
    }

    /**
     * @description Generates the HTML table for the email report.
     * @param orgCreds The list of Copado orgs with SCA results.
     * @return The HTML table content as a string.
     */
    private static String generateHtmlTable(List<copado__Org__c> orgCreds) {
        String htmlBody = 'Hi Team, <br><br>Here\'s the <b>SCA Report</b> generated for the following Environments:<br><br>' +
            '<table border="1" style="border-collapse: collapse; text-align: center;">' +
            '<tr>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">Environment Name</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P1 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P2 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P3 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">P4 Violations</th>' +
            '<th style="background-color: #f2f2f2; padding: 8px;">SCA Results</th>' +
            '</tr>';

        for (copado__Org__c org : orgCreds) {
            if (org.copado__Static_Code_Analysis_Results__r.isEmpty()) {
                htmlBody += '<tr>' +
                    '<td style="padding: 8px;">' + org.Name + '</td>' +
                    '<td colspan="5" style="padding: 8px;">No data available</td>' +
                    '</tr>';
                continue;
            }

            for (SObject resultObj : org.copado__Static_Code_Analysis_Results__r) {
                copado__Static_Code_Analysis_Result__c result = (copado__Static_Code_Analysis_Result__c) resultObj;

                htmlBody += '<tr>' +
                    '<td style="padding: 8px;">' + org.Name + '</td>' +
                    '<td style="padding: 8px;">' + result.P1_Violations__c + '</td>' +
                    '<td style="padding: 8px;">' + result.P2_Violations__c + '</td>' +
                    '<td style="padding: 8px;">' + result.P3_Violations__c + '</td>' +
                    '<td style="padding: 8px;">' + result.P4_Violations__c + '</td>' +
                    '<td style="padding: 8px;">' + 
                    'To view result <a href=https://thomsonreutersglis2e--rlpsbx.sandbox.lightning.force.com/' + 
                    result.Id + '>click here.</a>' + '</td>' +
                    '</tr>';
            }
        }
        htmlBody += '</table><br>Thanks & Regards,<br>DevOps Team';
        return htmlBody;
    }

    /**
     * @description Sends an email with the SCA report.
     * @param htmlBody The HTML report content.
     */
    public static void sendEmail(String htmlBody) {
        List<String> mailToAddresses = getRecipients();
        OrgWideEmailAddress orgAddress = getOrgWideEmail();

        if (orgAddress == null || mailToAddresses.isEmpty()) {
            return;
        }

        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(mailToAddresses);
            email.setSubject('PMD Report');
            email.setHtmlBody(htmlBody);
            email.setOrgWideEmailAddressId(orgAddress.Id);

            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        } catch (Exception ex) {
            // Handle exceptions
            ex.getMessage();
        }
    }

    /**
     * @description Fetches recipients from PMD_Report__mdt metadata.
     * @return List of email addresses.
     */
    private static List<String> getRecipients() {
        List<String> emails = new List<String>();

        List<PMD_Report__mdt> pmdReports = [SELECT Org_Address__c, Public_Group__c FROM PMD_Report__mdt WITH SECURITY_ENFORCED];
        if (pmdReports.isEmpty()) {
            return emails;
        }

        List<Group> groups = [SELECT Id, (SELECT UserOrGroupId FROM GroupMembers) 
                              FROM Group WHERE Name IN :pmdReports[0].Public_Group__c.split(',') WITH SECURITY_ENFORCED];
        List<Id> userIds = new List<Id>();
        for (Group g : groups) {
            for (GroupMember gm : g.GroupMembers) {
                userIds.add(gm.UserOrGroupId);
            }
        }

        for (User u : [SELECT Email FROM User WHERE Id IN :userIds WITH SECURITY_ENFORCED]) {
            emails.add(u.Email);
        }

        return emails;
    }

    private static OrgWideEmailAddress getOrgWideEmail() {
        List<OrgWideEmailAddress> orgEmails = [SELECT Id FROM OrgWideEmailAddress WITH SECURITY_ENFORCED LIMIT 1];
        return orgEmails.isEmpty() ? null : orgEmails[0];
    }
}