trigger SCAScanTrigger on copado__Static_Code_Analysis_Result__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        SCAScanHandler.handleAfterInsert(Trigger.new);
    }
}