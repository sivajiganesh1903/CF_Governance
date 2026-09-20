public class UserstoryHandlerCustom {
    
    public static void storyData(List<copado__User_Story__c> newStories, Map<Id, copado__User_Story__c> oldStories) {
        Datetime now = Datetime.now();        
        Date today = Date.today();        
        Datetime datetime1430 = Datetime.newInstance(today, Time.newInstance(14, 30, 0, 0));
        Datetime datetime2200 = Datetime.newInstance(today, Time.newInstance(22, 0, 0, 0));
        Boolean offShore = (now > datetime2200 || now < datetime1430);
        List<Task> tasksToInsert = new List<Task>();
        List<Task> tasksToUpdate = new List<Task>();        
        set<Id> storyIds=new set<Id>();
        set<Id> projectIds=new set<Id>();
        for(copado__User_Story__c storyId: newStories){
            storyIds.add(storyId.Id);
            projectIds.add(storyId.copado__Project__c);
        }
        List<copado__User_Story__c> storyData = [SELECT Id, Name, copado__User_Story_Title__c, copado__Status__c, 
                                                 copado__Project__r.Name, copado__Project__c, copado__Org_Credential__c,
                                                 copado__Environment__c, copado__Environment__r.Name,
                                                 copado__Org_Credential__r.Id, copado__Org_Credential__r.Name,                                                 
                                                 copado__Team__c, copado__Team__r.Name FROM copado__User_Story__c 
                                                 WHERE Id IN: storyIds];   
        for(copado__User_Story__c newStory : storyData){
            copado__User_Story__c oldStory = oldStories.get(newStory.Id);
            if (((newStory.copado__Status__c != oldStory.copado__Status__c) && 
                 (newStory.copado__Org_Credential__r.Id == oldStory.copado__Org_Credential__r.Id)
                ) ||
                ((newStory.copado__Status__c == 'Work Complete') && 
                 (newStory.copado__Org_Credential__r.Name != oldStory.copado__Org_Credential__r.Name)
                )){	
                    // Fetch story related Team
                    copado__Team__c fscTeam = [SELECT Id, Name, Offshore_Devops__c, Onshore_Devops__c 
                                               FROM copado__Team__c WHERE Id = :newStory.copado__Team__c LIMIT 1];
                    // Fetch story related Environment
                    copado__Environment__c storyEnvironment = [SELECT Id, Name FROM copado__Environment__c WHERE 
                                                               Id =: newStory.copado__Environment__c LIMIT 1];
                    copado__Project__c storyProject = [SELECT Id, Name, copado__Deployment_Flow__c FROM copado__Project__c 
                                                       WHERE Id = :newStory.copado__Project__c];
                    copado__Deployment_Flow_Step__c connectionEnvs = [SELECT Id, Name, copado__Source_Environment__c,
                                                                      copado__Deployment_Flow__c, 
                                                                      copado__Destination_Environment__c,
                                                                      copado__Destination_Environment__r.Name 
                                                                      FROM copado__Deployment_Flow_Step__c 
                                                                      WHERE copado__Source_Environment__c =: storyEnvironment.Id 
                                                                      AND copado__Deployment_Flow__c =: storyProject.copado__Deployment_Flow__c];
                    if(newStory.copado__Org_Credential__r.Name == 'TrnInt' && newStory.copado__Status__c == 'Work Complete' ){
                        
                        Task createTask = new Task();
                        createTask.Environment__c = connectionEnvs.copado__Destination_Environment__c;
                        createTask.OwnerId = offShore ? fscTeam.Onshore_Devops__c : fscTeam.Offshore_Devops__c;                          
                        createTask.Subject = newStory.copado__User_Story_Title__c;
                        createTask.WhatId = newStory.Id;
                        tasksToInsert.add(createTask);
                        
                    }else if(newStory.copado__Org_Credential__r.Name == 'TrnUat' && newStory.copado__Status__c == 'Done' ){                        
                        Task createTask = new Task();
                        createTask.Environment__c = connectionEnvs.copado__Destination_Environment__c;
                        createTask.OwnerId = offShore ? fscTeam.Onshore_Devops__c : fscTeam.Offshore_Devops__c;                         
                        createTask.Subject = newStory.copado__User_Story_Title__c;
                        createTask.WhatId = newStory.Id;
                        tasksToInsert.add(createTask);                        
                    }                
                }
            if(((newStory.copado__Status__c != oldStory.copado__Status__c) && 
                (newStory.copado__Org_Credential__r.Id != oldStory.copado__Org_Credential__r.Id)
               )){
                   List<Task> storyRelatedTasks = [SELECT Id, Subject, Status, WhatId, Environment__r.Name FROM Task 
                                                   WHERE WhatId = :newStory.Id AND Status != 'Completed']; 
                   If(!storyRelatedTasks.isEmpty()){
                       for(Task storyTask : storyRelatedTasks){
                           //For Int
                           if(storyTask.Environment__r.Name == 'TrnUat' && storyTask.WhatId == newStory.Id && 
                              (storyTask.Status == 'Open' || storyTask.Status == 'In Progress')){
                                  storyTask.status = 'Completed';
                              }
                           //For Uat
                           else if(storyTask.Environment__r.Name == 'trnProd' && storyTask.WhatId == newStory.Id &&
                                   (storyTask.Status == 'Open' || storyTask.Status == 'In Progress')){
                                       storyTask.status = 'Completed';
                                   }
                           tasksToUpdate.add(storyTask);
                       }
                   }
               }
            if (!tasksToInsert.isEmpty()) {
                insert tasksToInsert;
                sendTaskAssignmentEmails(tasksToInsert); // Call the email sending method
            }
            if (!tasksToUpdate.isEmpty()) {
                Database.update(tasksToUpdate, false);
            }
        }
    }
    private static void sendTaskAssignmentEmails(List<Task> tasks) {
        // Fetch the email template
        EmailTemplate template = [SELECT Id, DeveloperName FROM EmailTemplate
                                  WHERE DeveloperName = 'Task_Assign_to_User' LIMIT 1];        
        // Iterate over the tasks to send emails
        for (Task t : tasks) {
            if (t.OwnerId != null) {
                // Create the email message
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(template.Id);
                email.setTargetObjectId(t.OwnerId);
                //email.setWhatId(t.Id);
                email.setSaveAsActivity(false); // Don't save the email as an activity on the Task
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
        }
    }
    
    
    public static void releaseRetroData(List<copado__User_Story__c> newStories, Map<Id, copado__User_Story__c> oldStories) {
        Set<Id> storyIds = new Set<Id>();
        Set<Id> environmentIds = new Set<Id>();
        System.debug('1');
        
        for (copado__User_Story__c story : newStories) {
            storyIds.add(story.Id);
            environmentIds.add(story.copado__Environment__c);
            System.debug('2');
        }
        System.debug('3');
        
        List<copado__User_Story__c> storyData = [SELECT Id, Name, copado__User_Story_Title__c, copado__Status__c,
                                                 copado__Project__r.Name, copado__Project__c, copado__Org_Credential__c,
                                                 copado__Environment__c, copado__Environment__r.Name, copado__Release__c,
                                                 copado__Release__r.Name, copado__Org_Credential__r.Id, copado__Org_Credential__r.Name,
                                                 copado__Team__c, copado__Team__r.Name, Tag_Release__c, Original_Release__c,
                                                 Story_Held_In_Environment__c FROM copado__User_Story__c WHERE Id IN :storyIds];
        System.debug(storyData);
        
        Map<Id, copado__Environment__c> environmentMap = new Map<Id, copado__Environment__c>([SELECT Id, Name FROM copado__Environment__c WHERE Id IN :environmentIds]);
        System.debug(environmentMap);
        
        System.debug('OutSide Loop');
        List<copado__User_Story__c> storiesToUpdate = new List<copado__User_Story__c>();
        
        for (copado__User_Story__c story : storyData) {
            System.debug('Inside Loop');
            copado__Environment__c storyEnvironment = environmentMap.get(story.copado__Environment__c);
            System.debug(storyEnvironment);
            if (storyEnvironment.Name == 'TrnInt' && story.copado__Release__c != oldStories.get(story.Id).copado__Release__c) {
                story.Story_Held_In_Environment__c = 'INT';
            } else if (storyEnvironment.Name == 'TrnUat' && story.copado__Release__c != oldStories.get(story.Id).copado__Release__c) {
                story.Story_Held_In_Environment__c = 'UAT';
            } else if (storyEnvironment.Name == 'trnProd' && story.copado__Release__c == story.Original_Release__c) {
                story.Story_Held_In_Environment__c = '';
            }
            storiesToUpdate.add(story);
        }
        if (!storiesToUpdate.isEmpty()) {
            update storiesToUpdate;
        }
    }
    
    public static void releaseRetroInsert(List<copado__User_Story__c> newStories){
        for (copado__User_Story__c story : newStories) {
            if (!story.Tag_Release__c && story.copado__Release__c != NULL) {
                story.Original_Release__c = story.copado__Release__c;
                story.Tag_Release__c = true;
            }
        }       
    }
    
    public static void updateReleaseTask(List<copado__User_Story__c> newStories, Map<Id, copado__User_Story__c> oldStories) {
        Set<Id> storyIds = new Set<Id>();
        Map<Id, String> storyIdToReleaseMap = new Map<Id, String>();
        
        for (copado__User_Story__c newStory : newStories) {
            System.debug('Enterd in Loop : ++++++++');
            copado__User_Story__c oldStory = oldStories.get(newStory.Id);
            if (newStory.copado__Release__c != oldStory.copado__Release__c) {
                storyIds.add(newStory.Id);
                storyIdToReleaseMap.put(newStory.Id, newStory.copado__Release__c);
            }
        }
        System.debug('Storing Ids : ++++++++' + storyIds);
        
        List<Task> storyRelatedTasks = [SELECT Id, Subject, Status, WhatId, Release__c FROM Task WHERE WhatId IN :storyIds AND Status != 'Completed'];
        System.debug('Storing Tasks : ++++++++' + storyRelatedTasks);
        List<Task> updateTasks = new List<Task>();
        
        for (Task relatedTask : storyRelatedTasks) {
            relatedTask.Release__c = storyIdToReleaseMap.get(relatedTask.WhatId);
            System.debug('Print Tasks : ++++++++' + relatedTask.Release__c);
            updateTasks.add(relatedTask);
        }
        System.debug('Storing Tasks : ++++++++' + updateTasks);
        if (!updateTasks.isEmpty()) {
            update updateTasks;
        }
    }
    
    public static void perviousEnvironmentsUpdate(List<copado__User_Story__c> newList, Map<Id, copado__User_Story__c> oldMap){
        List<copado__User_Story__c> storiesToUpdate = new List<copado__User_Story__c>();
        for (copado__User_Story__c newUserStory : newList) {
            copado__User_Story__c oldUserStory = oldMap.get(newUserStory.Id);
            
            // Check if the environment has changed
            if (newUserStory.copado__Environment__c != oldUserStory.copado__Environment__c) {
                if (newUserStory.Previous_Environments__c == null) {
                    newUserStory.Previous_Environments__c = newUserStory.copado__Environment__c;
                } else if (!newUserStory.Previous_Environments__c.contains(newUserStory.copado__Environment__c)) {
                    newUserStory.Previous_Environments__c += ',' + newUserStory.copado__Environment__c;
                    System.debug('Updating Previous Environments are: +++++ ' + newUserStory.Previous_Environments__c);
                }
                
                storiesToUpdate.add(newUserStory);
            }
        }
        System.debug('Pervious Environment Updating Stories: +++++ ' + storiesToUpdate);
        // Update User Stories with the modified Previous Environments field
        if (!storiesToUpdate.isEmpty()) {
            update storiesToUpdate;
        }
    }
    
}