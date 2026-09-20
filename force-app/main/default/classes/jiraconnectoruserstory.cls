public with sharing class jiraconnectoruserstory {
    @AuraEnabled
    public static List<String> validation(List<Copado__User_Story__c> updatedRecords) {
        List<String> results = new List<String>();    
        // Fetch Custom Settings
        JiraConnectorSettings__c settings = JiraConnectorSettings__c.getInstance();
        if (!settings.TriggerLogicFlag__c) {
            System.debug('Logic is disabled via custom settings.');
            return results;
        } else {    
            String requiredStatus = settings.Status__c;
            String destinationEnvironment = settings.DestinationEnvironment__c;

            if (String.isEmpty(destinationEnvironment)) {
                throw new CustomException('Source Environment not configured in custom settings.');
            }

            Set<String> validEnvironments = new Set<String>(destinationEnvironment.split(','));
            system.debug('Custom Setting source environment: '+validEnvironments);
            if (updatedRecords == null || updatedRecords.isEmpty()) {
                throw new CustomException('No updated records provided.');
            }

            Set<Id> updatedRecordIds = new Set<Id>();
            for (Copado__User_Story__c record : updatedRecords) {
                updatedRecordIds.add(record.Id);
            }

            List<Copado__User_Story__c> userStories = [SELECT Id, Name, copado__Environment__r.Name, copado__Project__c FROM Copado__User_Story__c WHERE Id IN :updatedRecordIds];
			
            // Get Project Ids
            Set<Id> projectIds = new Set<Id>();
            for(Copado__User_Story__c us : userStories) {
                if(us.copado__Project__c != null) {
                    projectIds.add(us.copado__Project__c);
                }
            }
            
            // Query Projects to get their Pipeline IDs
            List<copado__Project__c> projects = [ SELECT Id, copado__Deployment_Flow__c FROM copado__Project__c WHERE Id IN :projectIds ];
            System.debug('Project: '+ projects);
            
            // Get Pipeline IDs
            Set<Id> pipelineIds = new Set<Id>();
            for(copado__Project__c proj : projects) {
                if(proj.copado__Deployment_Flow__c != null) {
                    pipelineIds.add(proj.copado__Deployment_Flow__c);
                }
            }
            
            // Query Pipelines and their steps
            List<copado__Deployment_Flow__c> pipelines = [SELECT Id, (SELECT Id, copado__Source_Environment__r.Name, copado__Destination_Environment__r.Name 
                                                          FROM copado__Deployment_Flow_Steps__r) FROM copado__Deployment_Flow__c WHERE Id IN :pipelineIds ];
            
            // Create map of Environment Name to its Destination Environment Name
            Map<String, String> sourceToDestinationEnvNameMap = new Map<String, String>();
            for(copado__Deployment_Flow__c pipeline : pipelines) {
                for(copado__Deployment_Flow_Step__c step : pipeline.copado__Deployment_Flow_Steps__r) {
                    sourceToDestinationEnvNameMap.put( step.copado__Source_Environment__r.Name, step.copado__Destination_Environment__r.Name );
                    System.debug('sourceToDestinationEnvNameMap: '+sourceToDestinationEnvNameMap);
                }
            }
            
            List<Change_Story_List__c> changeStoriesList = [SELECT Id, Name, Change_Story__c, Change_Story__r.Name, User_Story__c, 
                                                            Change_Story__r.Status__c FROM Change_Story_List__c WHERE 
                                                            User_Story__c IN :updatedRecordIds];

            Map<Id, List<Change_Story__c>> userStoryToChangeStoriesMap = new Map<Id, List<Change_Story__c>>();
            for (Change_Story_List__c changeStoryListItem : changeStoriesList) {
                Id userStoryId = changeStoryListItem.User_Story__c;                
                if (!userStoryToChangeStoriesMap.containsKey(userStoryId)) {
                    userStoryToChangeStoriesMap.put(userStoryId, new List<Change_Story__c>());
                }                
                userStoryToChangeStoriesMap.get(userStoryId).add(changeStoryListItem.Change_Story__r);
            }

            for (Copado__User_Story__c userStory : userStories) {
                // Get destination environment name for current user story's environment
                String destinationEnvName = sourceToDestinationEnvNameMap.get(userStory.copado__Environment__r.Name);
                System.debug('destinationEnvName: ' + destinationEnvName);
                
                if (destinationEnvName != null && validEnvironments.contains(destinationEnvName)) {
                    List<Change_Story__c> changeStories = userStoryToChangeStoriesMap.get(userStory.Id);

                    if (changeStories != null && !changeStories.isEmpty()) {
                        for (Change_Story__c changeStory : changeStories) {
                            if (changeStory.Status__c != requiredStatus) {
                                throw new CustomException('Change Story is not approved for this User Story: "' + changeStory.Name + '"');
                            }
                        }
                        results.add('Change Story is approved for User Story: "' + userStory.Name + '"');
                    } else {
                        throw new CustomException('No Change Story Found for this User Story: "' + userStory.Name + '"');
                    }
                }
            }            
            return results;
        }
    }

    // Custom exception for clarity
    public class CustomException extends Exception {}
}