public class UserStroyHandler {
    public Static void isRelease(List<copado__User_Story__c> newReleases, Map<Id, copado__User_Story__c>oldMap){
        //List<copado__User_Story__c> storyRelease = [SELECT Id, Name, copado__Release__c, copado__Release__r.Name 
        //                                            FROM copado__User_Story__c];
        Set<Id> releaseIds = new Set<Id>();
        for (copado__User_Story__c userStory : newReleases) {
            releaseIds.add(userStory.copado__Release__c);
            }
        Map<Id, copado__Release__c> relatedReleases = new Map<Id, copado__Release__c>(
                                                     [SELECT Id, Name FROM copado__Release__c WHERE Id IN :releaseIds]);
        List<copado__Release__c> releasesToUpdate = new List<copado__Release__c>();
        
        for (copado__User_Story__c userStory : newReleases) {            
            copado__Release__c newRelease = relatedReleases.get(userStory.copado__Release__c);
            copado__User_Story__c oldUserStory = oldMap.get(userStory.Id);
            copado__Release__c oldRelease = relatedReleases.get(oldUserStory.copado__Release__c);
            
            if (oldRelease != null && newRelease.Name != oldRelease.Name) {

                userStory.Original_Release__c = userStory.copado__Release__c;
                releasesToUpdate.add(newRelease);
            }
        }

        if (!releasesToUpdate.isEmpty()) {
            update releasesToUpdate;
        }
    }
}