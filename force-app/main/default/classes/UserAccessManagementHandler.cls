public without sharing class UserAccessManagementHandler {
    public static void userCreationEmailAlert(List<User_Access_Managment__c> newUserRecs){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
       
        EmailTemplate template = [SELECT Id, DeveloperName, Subject, Body FROM EmailTemplate WHERE 
                                  DeveloperName = 'Creation_of_Record_Template' LIMIT 1];
		System.debug('Email Template : ' + template);
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'dipali24lingayat@gmail.com' LIMIT 1];
        if (owea.size() > 0) {
            email.setOrgWideEmailAddressId(owea[0].Id);
        }
        else {
            System.debug('Org-Wide Email Address not found or not verified.');
        }
        
        
        for(User_Access_Managment__c newUser : newUserRecs){
            System.debug('Entered in Loop : ');
            System.debug('User Status : ' + newUser.Status__c);
            if (newUser.Status__c == 'Requested' && template != null && newUser.Email__c != null) {
                System.debug('Creating Email: ');
                email.setTemplateId(template.Id);
                email.setSubject(template.Subject);
                email.setPlainTextBody(template.Body);
                email.setTargetObjectId(newUser.OwnerId);
                email.setToAddresses(new String[]{newUser.Email__c});
                System.debug('newUser.Email__c ---- ' + newUser.Email__c);
                email.setSaveAsActivity(false);  // Adjust according to your need

                emails.add(email);
                system.debug('email ----- ' + email);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                for (Messaging.SendEmailResult res : results) {
                    if (res.isSuccess()) {
                        System.debug('Email sent successfully');
                    } else {
                        System.debug('Failed to send email. Errors: ' + res.getErrors());
                    }
                }
            }
        }
        
		//System.debug(emails);
        // Send the emails
        if (emails.size() > 0) {
            system.debug('Testing email' + emails);
            Messaging.sendEmail(emails);
        }
    }
}