trigger ReleaseTriggerCustom on copado__Release__c (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        ReleaseHandlerCustom.populateReleaseStartDate(Trigger.new);
    }
    if (Trigger.isBefore &&  Trigger.isUpdate) {
        ReleaseHandlerCustom.updateReleaseCompletionUpdate(Trigger.new, Trigger.oldMap);
    }
}