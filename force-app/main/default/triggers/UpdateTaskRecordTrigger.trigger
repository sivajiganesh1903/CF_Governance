trigger UpdateTaskRecordTrigger on copado__User_Story__c (after update) {
    UpdateTaskRecord.handleAfterUpdate(Trigger.new);
}