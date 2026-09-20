trigger ReviewerTrigger on Reviewer__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            ReviewerTriggerHandler.handleBeforeInsertUpdate(Trigger.new);
        }
    }
}