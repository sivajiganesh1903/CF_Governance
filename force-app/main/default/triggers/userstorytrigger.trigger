trigger userstorytrigger on copado__User_Story__c (before update, after update) {
    // Collect the Ids of the updated User Stories where the status has changed
    if (Trigger.isBefore && Trigger.isUpdate) {
        Set<Id> updatedUserStoryIds = new Set<Id>();
        for (copado__User_Story__c userStory : Trigger.new) {
            copado__User_Story__c oldUserStory = Trigger.oldMap.get(userStory.Id);
            // Only process records where status has changed and avoid self-referential updates
            if (userStory.copado__Status__c != oldUserStory.copado__Status__c) {
                updatedUserStoryIds.add(userStory.Id);
            }
        }
    
        // Proceed only if there are User Stories with status changes
        if (!updatedUserStoryIds.isEmpty()) {
            usdependencyhandler.updatestatus(updatedUserStoryIds);
        } 
    }
    
    // Automatic Rollback request when US status updated to Cancelled.
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<copado__User_Story__c> cancelledUserStories = new List<copado__User_Story__c>();
        for (copado__User_Story__c userStory : Trigger.new) {
            copado__User_Story__c oldUserStory = Trigger.oldMap.get(userStory.Id);
            if (userStory.copado__Status__c == 'Cancelled' && oldUserStory.copado__Status__c != 'Cancelled') {
                cancelledUserStories.add(userStory);
            }
        }

        if (!cancelledUserStories.isEmpty()) {
            usdependencyhandler.createRollbackRequests(cancelledUserStories);
        }
    }
    /* Before Update: Validate User Story promotion Prevents User Stories from being promoted when both Git MetaData (upserts) and 
     * Delete MetaData (deletions) files are attached.
     */
    if (Trigger.isBefore && Trigger.isUpdate) {
        UserstoryUpsertDeletions.beforePromoteChange(Trigger.new, Trigger.oldMap);
    }
}