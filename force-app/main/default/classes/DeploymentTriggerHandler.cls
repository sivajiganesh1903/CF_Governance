public class DeploymentTriggerHandler {
    public static void failedDeploymentRecords(List<copado__Deployment__c> failedDeployments){
        // Collect Promotion Ids from failed deployments
        Set<Id> promotionIds = new Set<Id>();
        for (copado__Deployment__c deploy : failedDeployments) {
            if (deploy.copado__Promotion__c != null) {
                promotionIds.add(deploy.copado__Promotion__c);
            }
        }
        System.debug('Promotion Ids: ' + promotionIds);
        
        // Query Promoted User Stories using Promotion Ids
        List<copado__Promoted_User_Story__c> promotedUS = [SELECT Id, copado__Promotion__c, copado__User_Story__c FROM 
                                                           copado__Promoted_User_Story__c WHERE copado__Promotion__c IN :promotionIds];
        System.debug('Promoted User Stories: ' + promotedUS);
        
        // Extract User Story Ids from promotedUS
        Set<Id> userStoryIds = new Set<Id>();
        for (copado__Promoted_User_Story__c pus : promotedUS) {
            if (pus.copado__User_Story__c != null) {
                userStoryIds.add(pus.copado__User_Story__c);
            }
        }
        System.debug('User Story Ids: ' + userStoryIds);
        
        // Query User Stories using extracted Ids
        List<copado__User_Story__c> usList = [SELECT Id, Failed_Counter__c FROM copado__User_Story__c WHERE Id IN :userStoryIds];
        System.debug('User Stories: ' + usList);
        
        // Increment Failed_Counter__c for each user story
        for (copado__User_Story__c us : usList) {
            us.Failed_Counter__c = (us.Failed_Counter__c == null ? 0 : us.Failed_Counter__c) + 1;
        }
        
        // Update User Stories
        if (!usList.isEmpty()) {
            update usList;
            System.debug('Updated User Stories: ' + usList);
        }
    }    
    

	/* //Script to update existing records
	
	// Fetch all deployment record IDs
    Set<Id> deploymentIds = new Set<Id>();
    for (copado__Deployment__c deploy : [SELECT Id FROM copado__Deployment__c]) {
        deploymentIds.add(deploy.Id);
    }
    
    System.debug('Fetched Deployment Ids: ' + deploymentIds);
    
    if (deploymentIds.isEmpty()) {
        System.debug('No Deployment records found.');
        return;
    }
    
    // Query all failed deployments based on deployment Ids
    List<copado__Deployment__c> failedDeployments = [
        SELECT Id, copado__Status__c, copado__Promotion__c
        FROM copado__Deployment__c
        WHERE Id IN :deploymentIds
    ];
    System.debug('Failed Deployments: ' + failedDeployments);
    
    // Collect Promotion Ids
    Set<Id> promotionIds = new Set<Id>();
    for (copado__Deployment__c deploy : failedDeployments) {
        if (deploy.copado__Promotion__c != null) {
            promotionIds.add(deploy.copado__Promotion__c);
        }
    }
    System.debug('Promotion Ids: ' + promotionIds);
    
    // Query deployment histories for status transitions
    Map<Id, Integer> deploymentErrorCounts = new Map<Id, Integer>();
    List<copado__Deployment_History__c> deploymentHistories = [
        SELECT copado__Deployment__c
        FROM copado__Deployment_History__c
        WHERE copado__Deployment__c IN :deploymentIds
        AND copado__Field__c = 'Status'
		AND copado__Object__c = 'Deployment'
        AND copado__Old_Value__c = 'In progress'
        AND copado__New_Value__c = 'Completed with Errors'
    ];
    
    // Count errors per deployment
    for (copado__Deployment_History__c history : deploymentHistories) {
        if (deploymentErrorCounts.containsKey(history.copado__Deployment__c)) {
            deploymentErrorCounts.put(history.copado__Deployment__c, deploymentErrorCounts.get(history.copado__Deployment__c) + 1);
        } else {
            deploymentErrorCounts.put(history.copado__Deployment__c, 1);
        }
    }
    System.debug('Deployment Error Counts: ' + deploymentErrorCounts);
    
    // Query Promoted User Stories using Promotion Ids
    Map<Id, List<copado__Promoted_User_Story__c>> promotionToUserStoriesMap = new Map<Id, List<copado__Promoted_User_Story__c>>();
    List<copado__Promoted_User_Story__c> promotedUS = [
        SELECT Id, copado__Promotion__c, copado__User_Story__c
        FROM copado__Promoted_User_Story__c
        WHERE copado__Promotion__c IN :promotionIds
    ];
    
    for (copado__Promoted_User_Story__c pus : promotedUS) {
        if (!promotionToUserStoriesMap.containsKey(pus.copado__Promotion__c)) {
            promotionToUserStoriesMap.put(pus.copado__Promotion__c, new List<copado__Promoted_User_Story__c>());
        }
        promotionToUserStoriesMap.get(pus.copado__Promotion__c).add(pus);
    }
    System.debug('Promoted User Stories: ' + promotionToUserStoriesMap);
    
    // Collect User Story Ids
    Set<Id> userStoryIds = new Set<Id>();
    for (List<copado__Promoted_User_Story__c> pusList : promotionToUserStoriesMap.values()) {
        for (copado__Promoted_User_Story__c pus : pusList) {
            if (pus.copado__User_Story__c != null) {
                userStoryIds.add(pus.copado__User_Story__c);
            }
        }
    }
    System.debug('User Story Ids: ' + userStoryIds);
    
    // Query User Stories
    List<copado__User_Story__c> usList = [
        SELECT Id, Failed_Counter__c
        FROM copado__User_Story__c
        WHERE Id IN :userStoryIds
    ];
    System.debug('Queried User Stories: ' + usList);
    
    // Update Failed_Counter__c based on error count
    for (copado__User_Story__c us : usList) {
        Integer totalErrorCount = 0;
        for (copado__Deployment__c deploy : failedDeployments) {
            if (deploymentErrorCounts.containsKey(deploy.Id) && promotionToUserStoriesMap.containsKey(deploy.copado__Promotion__c)) {
                totalErrorCount += deploymentErrorCounts.get(deploy.Id);
            }
        }
        us.Failed_Counter__c = totalErrorCount;
    }
    
    // Bulk update User Stories
    if (!usList.isEmpty()) {
        update usList;
        System.debug('Updated User Stories: ' + usList);
    }

*/
}