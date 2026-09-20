trigger CopadoDeploymentTrigger on copado__Deployment__c (after update) {
    if (trigger.isAfter && trigger.isUpdate) {
        List<copado__Deployment__c> failedDeployments = new List<copado__Deployment__c>();
        for (copado__Deployment__c deploy : trigger.new) {
            copado__Deployment__c oldDeploy = trigger.oldMap.get(deploy.Id);
            if (oldDeploy.copado__Status__c != 'Completed with Errors' && 
                deploy.copado__Status__c == 'Completed with Errors') {
                failedDeployments.add(deploy);
            }
        }
        if (!failedDeployments.isEmpty()) {
            DeploymentTriggerHandler.failedDeploymentRecords(failedDeployments);
        }
    }
}