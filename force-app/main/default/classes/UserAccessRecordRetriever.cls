public with sharing class UserAccessRecordRetriever {

    // Wrapper for devOps data and User Access Management record fields
    public class devopsWrapper {
        @AuraEnabled public String devOpsName { get; set; }
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String fullName { get; set; }    // Concatenated Full Name
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String productTeam { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String environments { get; set; }
        @AuraEnabled public String federationId { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String accessDetails { get; set; }
        @AuraEnabled public String division { get; set; }
        @AuraEnabled public Date accessPeriodStart { get; set; }
        @AuraEnabled public Date accessPeriodEnd { get; set; }
        @AuraEnabled public String additionOfPermission { get; set; }
        @AuraEnabled public String removalOfPermission { get; set; }
        @AuraEnabled public String endOfDay { get; set; }
        @AuraEnabled public String startOfDay { get; set; }
        @AuraEnabled public String persona { get; set; }
        @AuraEnabled public String referenceUser { get; set; }
        @AuraEnabled public String timeZone { get; set; }
        @AuraEnabled public String requestType { get; set; }
        
        // Constructor to initialize wrapper class
        public devopsWrapper(User_Access_Managment__c userAccessRecord) {
            this.devOpsName = userAccessRecord.DevOps__r != null ? userAccessRecord.DevOps__r.Name : null;
            this.recordId = userAccessRecord.Id;
            this.name = userAccessRecord.Name;
            this.fullName = userAccessRecord.First_Name__c + ' ' + userAccessRecord.Last_Name__c;
            this.status = userAccessRecord.Status__c;
            this.productTeam = userAccessRecord.Product_Team__c;
            this.firstName = userAccessRecord.First_Name__c;
            this.lastName = userAccessRecord.Last_Name__c;
            this.environments = userAccessRecord.Environments__c;
            this.federationId = userAccessRecord.Federation_ID__c;
            this.email = userAccessRecord.Email__c;
            this.accessDetails = userAccessRecord.Access_Details__c;
            this.division = userAccessRecord.Divsion__c;
            this.accessPeriodStart = userAccessRecord.Access_Period_Start__c;
            this.accessPeriodEnd = userAccessRecord.Access_Period_End__c;
            this.additionOfPermission = userAccessRecord.Addition_of_Permission__c;
            this.removalOfPermission = userAccessRecord.Removal_of_Permissions__c;
            this.endOfDay = userAccessRecord.End_of_Day__c;
            this.startOfDay = userAccessRecord.Start_Of_Day__c;
            this.persona = userAccessRecord.Persona__c;
            this.referenceUser = userAccessRecord.Reference_User__c;
            this.timeZone = userAccessRecord.Time_Zone__c;
            this.requestType = userAccessRecord.Request_Type__c;
        }
    }

    // Method to display all records with Status 'Requested' and 'Approved' in LWC
    @AuraEnabled(cacheable=true)
    public static List<devopsWrapper> getUserAccessManagementRecords() {
        List<User_Access_Managment__c> userAccessRecords = [SELECT Id, Name, Status__c, Product_Team__c, First_Name__c, Last_Name__c, 
                                                            Environments__c, Federation_ID__c, Email__c, Access_Details__c, Divsion__c, 
                                                            Access_Period_End__c, Access_Period_Start__c, Addition_of_Permission__c, 
                                                            End_of_Day__c, Persona__c, Reference_User__c, Removal_of_Permissions__c, 
                                                            Start_Of_Day__c, Time_Zone__c, DevOps__r.Name, Request_Type__c
                                                            FROM User_Access_Managment__c WHERE Status__c != 'Completed'
                                                            ORDER BY CreatedDate DESC];
        System.debug('User Access Records: +++++ ' + userAccessRecords);
        List<devopsWrapper> wrapperList = new List<devopsWrapper>();
        for (User_Access_Managment__c record : userAccessRecords) {
            wrapperList.add(new devopsWrapper(record));
        }
        System.debug('Wrapper List: ++++ ' + wrapperList);
        return wrapperList;
    }

    // Method to generate the CSV report and send an email
    public static void sendWeeklyUserAccessReport() {
        // SOQL Query to fetch records for the last 7 days
        List<User_Access_Managment__c> userAccessReport = [SELECT Id, Name, Status__c, Product_Team__c, First_Name__c, Last_Name__c, 
                                                            Environments__c, Federation_ID__c, Email__c, Access_Details__c, Divsion__c, 
                                                            Access_Period_End__c, Access_Period_Start__c, Addition_of_Permission__c, 
                                                            End_of_Day__c, Persona__c, Reference_User__c, Removal_of_Permissions__c, 
                                                            Start_Of_Day__c, Time_Zone__c, DevOps__r.Name, Request_Type__c
                                                            FROM User_Access_Managment__c WHERE CreatedDate = LAST_N_DAYS:7 
                                                            ORDER BY CreatedDate DESC];
        System.debug('Weekly User Access Report' + userAccessReport);
        // Initialize CSV data
        String csvData = 'SNo,Request Type,Requested By,Environments,Division,Persona\n';
        Integer sno = 1;
        Integer newCount = 0, existCount = 0;

        for (User_Access_Managment__c record : userAccessReport) {
            devopsWrapper wrapper = new devopsWrapper(record);
            csvData += sno + ',' + wrapper.requestType + ',' + wrapper.fullName + ',' + wrapper.environments + ',' + 
                        wrapper.division + ',' + wrapper.persona + '\n';
            sno++;

            if (wrapper.requestType == 'New User Request') {
                newCount++;
            } else if (wrapper.requestType == 'Existing User Request') {
                existCount++;
            }
        }
        System.debug('Generated CSV data' + csvData);
        // Create HTML body for the email
        String htmlBody = 'Hi Team, <br><br>Here\'s the report generated for the Weekly User Access Requests. ' +
                          'Please find the following Details:<br><br>' +
                          '<table border="1" style="border-collapse: collapse; text-align: center;">' +
                          '<tr>' +
                          '<th style="background-color: #f2f2f2; padding: 8px;">Total Number of Requests</th>' +
                          '<th style="background-color: #f2f2f2; padding: 8px;">New User Requests</th>' +
                          '<th style="background-color: #f2f2f2; padding: 8px;">Existing User Requests</th>' +
                          '</tr>' +
                          '<tr>' +
                          '<td style="padding: 8px;">' + userAccessReport.size() + '</td>' +
                          '<td style="padding: 8px;">' + newCount + '</td>' +
                          '<td style="padding: 8px;">' + existCount + '</td>' +
                          '</tr></table><br>Please find the Attachment. <br><br> Regards,<br>DevOps Team';

        // Create CSV email attachment
        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        Blob csvBlob = Blob.valueOf(csvData);
        csvAttachment.setFileName('UserAccessRequestReport.csv');
        csvAttachment.setBody(csvBlob);

        // Call the method to send email with the CSV attachment
        sendEmailWithAttachment(csvAttachment, htmlBody);
    }

    public static void sendEmailWithAttachment(Messaging.EmailFileAttachment csvAttachment, String htmlBody) {
        List<String> emailAddresses = new List<String>();
        
        // Fetch PMD_Report__mdt records
        List<PMD_Report__mdt> pmdReportList = [SELECT Id, Org_Address__c, Email_Address__c FROM PMD_Report__mdt LIMIT 1];
        PMD_Report__mdt pmdReport = pmdReportList[0];
        System.debug('PMD Report Email Address +++++ ' + pmdReportList);
        
        // Fetch OrgWideEmailAddress
        List<OrgWideEmailAddress> orgAddressList = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress 
                                                    WHERE DisplayName = :pmdReport.Org_Address__c LIMIT 1];
        OrgWideEmailAddress orgAddress = (orgAddressList.size() > 0) ? orgAddressList[0] : null;
        System.debug('OrgWideEmailAddress: +++++ ' + orgAddress);

        if (orgAddress == null) {
            System.debug('No OrgWideEmailAddress found with display name: ' + pmdReport.Org_Address__c);
            return;
        }

        // Create email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        emailAddresses.addAll(pmdReport.Email_Address__c.split(','));
        email.setToAddresses(emailAddresses);
        email.setOrgWideEmailAddressId(orgAddress.Id);
        email.setSubject('User Access Management Report');
        email.setHtmlBody(htmlBody);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { csvAttachment });

        // Send email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}


    /*
    @AuraEnabled
    public static String updateUserAccessRequests(String recordId, String selectedAction, String comments) {
        
        User_Access_Managment__c userAccessMan = [SELECT Id, Name, Status__c, Comments__c 
												  FROM User_Access_Managment__c WHERE Id = :recordId LIMIT 1];
        
        if (userAccessMan != null) {
            userAccessMan.Status__c = selectedAction;
            userAccessMan.Comments__c = comments; 
            update userAccessMan;
            return 'Success';
        } else {
            return 'No record found';
        }
    } 
	*/