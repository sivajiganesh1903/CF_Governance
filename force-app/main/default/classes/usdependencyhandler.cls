public with sharing class usdependencyhandler {
    private static Boolean isExecuting = false;
    
    public static void updatestatus(Set<Id> updatedUserStoryIds) {
        // Check if already executing
        if(isExecuting) return;
        
        try {
            isExecuting = true;
            
            // Query to get all User Stories with Ids in the set 'updatedUserStoryIds'
            List<copado__User_Story__c> userStories = [SELECT Id, copado__Status__c 
                                                      FROM copado__User_Story__c 
                                                      WHERE Id IN :updatedUserStoryIds];
            
            // Create a map to store the status of each user story
            Map<Id, String> userStoryStatusMap = new Map<Id, String>();
            for (copado__User_Story__c userStory : userStories) {
                userStoryStatusMap.put(userStory.Id, userStory.copado__Status__c);
            }
            
            // Query dependent user stories
            List<copado__Team_Dependency__c> dependencies = [SELECT Id, copado__Dependent_User_Story__c, copado__Provider_User_Story__c 
                                                           FROM copado__Team_Dependency__c 
                                                           WHERE copado__Provider_User_Story__c IN :updatedUserStoryIds];
            
            // Collect dependent user story IDs
            Set<Id> dependentUserStoryIds = new Set<Id>();
            Map<Id, Id> dependencyMap = new Map<Id, Id>();
            for (copado__Team_Dependency__c dependency : dependencies) {
                dependentUserStoryIds.add(dependency.copado__Dependent_User_Story__c);
                dependencyMap.put(dependency.copado__Dependent_User_Story__c, dependency.copado__Provider_User_Story__c);
            }
            
            // Query dependent user stories to update
            List<copado__User_Story__c> dependentUserStories = [SELECT Id, copado__Status__c 
                                                               FROM copado__User_Story__c 
                                                               WHERE Id IN :dependentUserStoryIds];
            
            // Create a list to store the dependent user stories that need to be updated
            List<copado__User_Story__c> storiesToUpdate = new List<copado__User_Story__c>();
            
            // Update the status of the dependent user stories
            for (copado__User_Story__c dependentUserStory : dependentUserStories) {
                Id providerUserStoryId = dependencyMap.get(dependentUserStory.Id);
                if (userStoryStatusMap.containsKey(providerUserStoryId)) {
                    dependentUserStory.copado__Status__c = userStoryStatusMap.get(providerUserStoryId);
                    storiesToUpdate.add(dependentUserStory);
                }
            }
            
            // Perform DML operation to update the dependent user stories
            if (!storiesToUpdate.isEmpty()) {
                update storiesToUpdate;
            }
        } catch(Exception e) {
            System.debug('Error in updatestatus: ' + e.getMessage());
            throw e;
        } finally {
            isExecuting = false;
        }
    }  
    
    public static void createRollbackRequests(List<copado__User_Story__c> cancelledUserStories) {
        try {
            // Retrieve environment records dynamically
            Map<String, String> environmentMapping = new Map<String, String>();
            // Query the object where CFEC__Type__c field resides
            // Commneted tyep filed CFEC__Type__c
            List<copado__Environment__c> environmentRecords = [SELECT Id, Name, Type__c 
                                                             FROM copado__Environment__c 
                                                             WHERE Type__c != null];
            
            // Populate the map with environment name and CFEC__Type__c value
            // Commneted tyep filed CFEC__Type__c
            for (copado__Environment__c env : environmentRecords) {
                environmentMapping.put(env.Name, env.Type__c);
            }
            System.debug('environmentMapping ==> '+ environmentMapping);
            
            System.debug('cancelledUserStories ==> '+ cancelledUserStories);
            
            // Collect IDs of cancelled user stories
            Set<Id> cancelledUserStoryIds = new Set<Id>();
            for (copado__User_Story__c userStory : cancelledUserStories) {
                if (userStory.copado__Status__c == 'Cancelled') {
                    cancelledUserStoryIds.add(userStory.Id);
                }
            }
            if (cancelledUserStoryIds.isEmpty()) return;
            
            // Retrieve user story details into a map
            Map<Id, copado__User_Story__c> userStoryMap = new Map<Id, copado__User_Story__c>(
                [SELECT Id, copado__Environment__c, copado__User_Story_Title__c, Name, 
                 copado__Developer__c, Jira_Key__c 
                 FROM copado__User_Story__c
                 WHERE Id IN :cancelledUserStoryIds]);
            
            // Retrieve active promoted user stories via the junction object
            List<copado__Promoted_User_Story__c> promotedUserStories = [SELECT Id, copado__Promotion__c, copado__User_Story__c 
                                                                       FROM copado__Promoted_User_Story__c 
                                                                       WHERE copado__User_Story__c IN :cancelledUserStoryIds];
            
            System.debug('promotedUserStories ==> '+ promotedUserStories);
            
            // Collect promotion IDs from the junction object
            Set<Id> promotionIds = new Set<Id>();
            for (copado__Promoted_User_Story__c promotedUserStory : promotedUserStories) {
                if (promotedUserStory.copado__Promotion__c != null) {
                    promotionIds.add(promotedUserStory.copado__Promotion__c);
                }
            }
            if (promotionIds.isEmpty()) return;
            
            // Retrieve completed promotion records
            List<copado__Promotion__c> completedPromotions = [SELECT Id, copado__Source_Environment__c, copado__Destination_Environment__c
                                                            FROM copado__Promotion__c 
                                                            WHERE Id IN :promotionIds 
                                                            AND copado__Status__c = 'Completed'];
            
            System.debug('completedPromotions ==> '+ completedPromotions);
            
            // Query environments to map Ids to names
            Set<Id> environmentIds = new Set<Id>();
            for (copado__Promotion__c promotion : completedPromotions) {
                if (promotion.copado__Source_Environment__c != null) {
                    environmentIds.add(promotion.copado__Source_Environment__c);
                }
                if (promotion.copado__Destination_Environment__c != null) {
                    environmentIds.add(promotion.copado__Destination_Environment__c);
                }
            }
            // Commneted tyep filed CFEC__Type__c
            Map<Id, String> environmentIdToNameMap = new Map<Id, String>();
            if (!environmentIds.isEmpty()) {
                List<copado__Environment__c> environments = [SELECT Id, Name, copado__Type__c, Type__c 
                                                           FROM copado__Environment__c 
                                                           WHERE Id IN :environmentIds];
                for (copado__Environment__c environment : environments) {
                    environmentIdToNameMap.put(environment.Id, environment.Name);
                }
            }
            System.debug('environmentIdToNameMap ==> '+ environmentIdToNameMap);
            
            // Translate environment Ids to names and store in uniqueGlobalEnvironments
            Map<Id, Set<String>> userStoryToEnvironments = new Map<Id, Set<String>>();
            for (copado__Promotion__c promotion : completedPromotions) {
                if (promotion.copado__Source_Environment__c != null) {
                    String sourceEnv = environmentIdToNameMap.get(promotion.copado__Source_Environment__c);
                    if (sourceEnv != null) {
                        for (copado__Promoted_User_Story__c promotedUserStory : promotedUserStories) {
                            if (!userStoryToEnvironments.containsKey(promotedUserStory.copado__User_Story__c)) {
                                userStoryToEnvironments.put(promotedUserStory.copado__User_Story__c, new Set<String>());
                            }
                            userStoryToEnvironments.get(promotedUserStory.copado__User_Story__c).add(sourceEnv);
                        }
                    }
                }
                if (promotion.copado__Destination_Environment__c != null) {
                    String destEnv = environmentIdToNameMap.get(promotion.copado__Destination_Environment__c);
                    if (destEnv != null) {
                        for (copado__Promoted_User_Story__c promotedUserStory : promotedUserStories) {
                            if (!userStoryToEnvironments.containsKey(promotedUserStory.copado__User_Story__c)) {
                                userStoryToEnvironments.put(promotedUserStory.copado__User_Story__c, new Set<String>());
                            }
                            userStoryToEnvironments.get(promotedUserStory.copado__User_Story__c).add(destEnv);
                        }
                    }
                }
            }
            
            // Fetch the Rollback Request record type ID
            Id rollbackRequestRecordTypeId = [SELECT Id 
                                            FROM RecordType 
                                            WHERE SObjectType = 'Issue_Tracker__c' 
                                            AND DeveloperName = 'Rollback_Request' 
                                            LIMIT 1].Id;
            
            // Create rollback requests
            List<Issue_Tracker__c> rollbackRequests = new List<Issue_Tracker__c>();
            
            // Iterate over cancelled user stories and their environments
            for (Id userStoryId : cancelledUserStoryIds) {
                if (userStoryToEnvironments.containsKey(userStoryId)) {
                    Set<String> environments = userStoryToEnvironments.get(userStoryId);
                    List<String> mappedEnvironments = new List<String>();
                    for (String environment : environments) {
                        String mappedEnvironment = environmentMapping.get(environment);
                        if (mappedEnvironment != null) {
                            mappedEnvironments.add(mappedEnvironment);
                        }
                    }
                    
                    String concatenatedEnvironments = String.join(mappedEnvironments, '; ');
                    
                    System.debug('concatenatedEnvironments ==> '+ concatenatedEnvironments);
                    
                    if (!mappedEnvironments.isEmpty()) {
                        copado__User_Story__c userStory = userStoryMap.get(userStoryId);
                        rollbackRequests.add(new Issue_Tracker__c(
                            Issue_Description__c = 'Rollback Request: ' + userStory.copado__User_Story_Title__c,
                            Issue_Environment__c = concatenatedEnvironments,
                            Status__c = 'New',
                            Category__c = 'Other',
                            Other_Information__c = 'Jira cancelled and no requirement needed as for now',
                            Priority__c = 'P3',
                            Developer__c = userStory.copado__Developer__c,
                            User_Story_Impacted__c = userStory.Id,
                            JIRA_Key__c = userStory.Jira_Key__c,
                            RecordTypeId = rollbackRequestRecordTypeId
                        ));
                    }
                }
            }
            
            // Insert rollback requests
            if (!rollbackRequests.isEmpty()) {
                insert rollbackRequests;
                System.debug('rollbackRequests ==> '+ rollbackRequests);
            }
        } catch(Exception e) {
            System.debug('Error in createRollbackRequests: ' + e.getMessage());
            throw e;
        }
    }    
}