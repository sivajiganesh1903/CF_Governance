trigger RenameBackPromotionDeployment on copado__Deployment__c (after insert) {
    // Delegate to handler to keep logic testable and avoid duplicating logic in trigger
    RenameBackPromotionDeploymentHandler.process(Trigger.new);
}