public with sharing class UserAccessManagementecordRetriever {

    @AuraEnabled(cacheable=true)
    public static List<User_Access_Managment__c> getUserAccessManagementRecords() {
        return [
            SELECT Id, Name, Status__c, Product_Team__c, First_Name__c, Last_Name__c, Environments__c, Federation_ID__c, Email__c, Access_Details__c, Divsion__c 
            FROM User_Access_Managment__c 
            WHERE Status__c != 'Rejected' AND Status__c != 'Approved' AND Status__c != 'Provisioned'
        ];
    }

    @AuraEnabled
    public static String updateUserAccessRequests(String recordId, String selectedAction, String comments) {
       
        User_Access_Managment__c userAccessMan = [
            SELECT Id, Name, Status__c, Comments__c
            FROM User_Access_Managment__c
            WHERE Id = :recordId
            LIMIT 1
        ];
    
        if (userAccessMan != null) {
            userAccessMan.Status__c = selectedAction;
            userAccessMan.Comments__c = comments; 
            update userAccessMan;
            return 'Success';
        } else {
            return 'No record found';
        }
    }
}