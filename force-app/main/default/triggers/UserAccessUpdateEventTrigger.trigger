// Name your trigger like this:
trigger UserAccessUpdateEventTrigger on UserAccessUpdateEvent__e (after insert) {
    List<User_Access_Managment__c> toUpdate = new List<User_Access_Managment__c>();

    for (UserAccessUpdateEvent__e evt : Trigger.New) {
        if (String.isNotBlank(evt.Record_Id__c)) {
            toUpdate.add(new User_Access_Managment__c(
                Id = evt.Record_Id__c,
                Status__c = evt.Update_Status__c
            ));
        }
    }

    if (!toUpdate.isEmpty()) {
        try {
            update toUpdate;
        } catch (Exception ex) {
            System.debug('Platform Event Error: ' + ex.getMessage());
        }
    }
}