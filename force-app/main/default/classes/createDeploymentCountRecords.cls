public class createDeploymentCountRecords {
    
	public static void createDeploymentCountRecords(Id userStoryId) {
        
        // 1. Query the User Story record with the text field
        copado__User_Story__c userStory = [ SELECT Id, Deployment_Count__c FROM copado__User_Story__c WHERE Id = :userStoryId LIMIT 1 ];
        
        if (String.isBlank(userStory.Deployment_Count__c)) {
            System.debug('No Deployment Counts text to process.');
            return;
        }
    
        String countsText = userStory.Deployment_Count__c;
        
        // 2. Split by comma to separate each environment
        List<String> envEntries = countsText.split(',');
    
        List<Deployment_Count__c> countRecords = new List<Deployment_Count__c>();
    
        for (String entry : envEntries) {
            entry = entry.trim(); // clean whitespace
            if (entry.contains('→') && entry.contains('times')) {
                // Extract environment name and count
                List<String> parts = entry.split('→');
                if (parts.size() == 2) {
                    String envName = parts[0].trim();
                    String countPart = parts[1].trim().replace('times', '').trim();
                    Integer countValue = Integer.valueOf(countPart);
                    
                    countRecords.add(new Deployment_Count__c( User_Story__c = userStoryId, Environment_Name__c = envName, Count__c = countValue ));
                }
            }
        }
    
        // Optional: Delete existing records first to avoid duplicates
        List<Deployment_Count__c> oldRecords = [ SELECT Id FROM Deployment_Count__c WHERE User_Story__c = :userStoryId ];
        delete oldRecords;
    
        insert countRecords;
        
        System.debug('Inserted Deployment_Count__c records: ' + countRecords.size());
    }

}