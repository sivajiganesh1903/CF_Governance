public class StepDeploymentJob {
	public static void createCopadoRecords() {
        // Create a new Copado Step record
        copado__Step__c newStep = new copado__Step__c();
        newStep.Name = 'New Deployment Step';
        newStep.copado__Deployment__c = 'a0d4x000009nlw1AAA';
        newStep.copado__Order__c = 1;
     //   newStep.LastModifiedDate = 2023-06-15T13:07:00.000+0000;

        // Insert the Copado Step record
        insert newStep;

        // Create a new Copado Deployment Job record and associate it with the Step
        copado__Deployment_Job__c newJob = new copado__Deployment_Job__c();
        newJob.copado__Step__c = newStep.Id; // Associate the Deployment Job with the Step
        newJob.copado__Destination_Org__c = 'a0e7e000005l7dFAAQ';

        // Insert the Copado Deployment Job record
        insert newJob;

        // Output the IDs of the created records (optional)
        System.debug('Step ID: ' + newStep.Id);
        System.debug('Job ID: ' + newJob.Id);
    }
}