trigger UserAccessManagementTrigger on User_Access_Managment__c (after insert, after update) {
    Set<Id> uamIds = new Set<Id>();

    for (User_Access_Managment__c uam : Trigger.new) {
        if (uam.Requested_Environment__c != null) {
            uamIds.add(uam.Id);
        }
    }

    if (!uamIds.isEmpty()) {
        UserPermissionFetcherFuture.runUserPermissionFetcher(new List<Id>(uamIds));
    }
 
}