trigger StepTrigger on copado__Step__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        StepTriggerHandler.handleTrigger(Trigger.new);
    } 
}