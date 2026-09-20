public with sharing class UserStoryController {
    @AuraEnabled(cacheable=true)
    public static List<copado__User_Story__c> storyReleatedSCA(){
        try {
            List<copado__User_Story__c> SCAdata = [SELECT Id, Name, copado__Developer__r.Name,
                                                   (SELECT Id, Name, copado__Score_v11__c FROM 
                                                    copado__Static_Code_Analysis_Results__r ORDER BY CreatedDate DESC LIMIT 1)
                                                   FROM copado__User_Story__c WHERE Id IN 
                                                   (SELECT copado__User_Story__c FROM copado__Static_Code_Analysis_Result__c)];
            return SCAdata;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}