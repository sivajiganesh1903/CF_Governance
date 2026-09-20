trigger PRTrigger on copado__Step__c (after update) {
    // Collect the steps to be processed for each status condition
    List<copado__Step__c> stepsWithErrors = new List<copado__Step__c>();
    List<copado__Step__c> stepsSuccessfullyCompleted = new List<copado__Step__c>();

    for (copado__Step__c newRecord : Trigger.new) {
        copado__Step__c oldRecord = Trigger.oldMap.get(newRecord.Id);

        // Check if the status has changed and the name is 'Pull Request'
        if (oldRecord.copado__Status__c != newRecord.copado__Status__c && newRecord.Name == 'Pull Request') {
            if (newRecord.copado__Status__c == 'Completed with Errors') {
                stepsWithErrors.add(newRecord);
            } else if (newRecord.copado__Status__c == 'Completed Successfully') {
                stepsSuccessfullyCompleted.add(newRecord);
            }
        }
    }

    // If there are steps to process with errors, call the handler method
    if (!stepsWithErrors.isEmpty()) {
        PRHandler handler = new PRHandler();
        handler.validatePRattachment(stepsWithErrors);
    }

    // If there are steps successfully completed, call the new method
    if (!stepsSuccessfullyCompleted.isEmpty()) {
        PRHandler handler = new PRHandler();
        handler.handleSuccessfulPR(stepsSuccessfullyCompleted);
    }
}