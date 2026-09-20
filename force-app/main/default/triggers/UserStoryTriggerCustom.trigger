trigger UserStoryTriggerCustom on copado__User_Story__c (before insert, after insert, before update, after update) {
    /*if (Trigger.isAfter && Trigger.isUpdate) {
        UserstoryHandler.storyData(Trigger.new, Trigger.oldMap);
    }  
    boolean isExecuting=false;    
    if (Trigger.isAfter && Trigger.isUpdate && isExecuting==false) {
        isExecuting=true;
        UserstoryHandlerCustom.releaseRetroData(Trigger.new, Trigger.oldMap);
        isExecuting=false;
    }
    if (Trigger.isBefore && Trigger.isInsert) {
        UserstoryHandlerCustom.releaseRetroInsert(Trigger.new);
    }*/ 
    
    /*if (Trigger.isAfter && Trigger.isUpdate) {
        UserstoryHandlerCustom.updateReleaseTask(Trigger.new, Trigger.oldMap);
    } 
    if (Trigger.isAfter && Trigger.isUpdate) {
        UserstoryHandlerCustom.perviousEnvironmentsUpdate(Trigger.new, Trigger.oldMap);
    }*/
}