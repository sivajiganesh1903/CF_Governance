public class UpdateTaskRecord {
    public static void handleAfterUpdate(List<copado__User_Story__c> usrData) {
        /*List<Task> tasksToUpdate = new List<Task>();

        for (copado__User_Story__c userStory : newRecords) {
            copado__User_Story__c oldUserStory = oldMap.get(userStory.Id);

            // Check if Credential field has changed
            if (userStory.copado__Org_Credential__c != oldUserStory.copado__Org_Credential__c) {
                // Fetch related tasks
                List<Task> relatedTasks = [SELECT Id FROM Task WHERE WhatId = :userStory.Id];

                // Update Environment field in related tasks
                for (Task task : relatedTasks) {
                    task.Credential__c = userStory.copado__Org_Credential__c;
                    tasksToUpdate.add(task);
                }
            }
        }

        // Update tasks
        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }*/
        List<copado__User_Story__c> storyData = [SELECT Id, copado__Status__c, copado__Promote_and_Deploy__c,
                                                 copado__Org_Credential__r.Name, (SELECT Id FROM Tasks) 
                                                 FROM copado__User_Story__c WHERE Id IN :usrData];
        for (copado__User_Story__c us : storyData) {
            if (us.copado__Org_Credential__r.Name != NULL) {
                for (Task t : us.Tasks) {
                    t.Credential__c = us.copado__Org_Credential__r.Name;
                }
            }
        }
    }
        
}