public with sharing class PRHandler {
    public void validatePRattachment(List<copado__Step__c> jobstep) {
        Set<Id> stepIdsToUpdate = new Set<Id>();
        Map<Id, String> stepStatusMap = new Map<Id, String>();
        String jsonString;
        for (copado__Step__c step : jobstep) {
            List<copado__Deployment_Job__c> deployments = [
                SELECT Id, copado__Step__c, copado__Status__c
                FROM copado__Deployment_Job__c 
                WHERE copado__Step__c = :step.Id
            ];

            if (!deployments.isEmpty()) {
                if(deployments[0].copado__Status__c == 'Failed'){
                // JSON string with current datetime and comment
                 jsonString = '[{"m":"NEW STATUS: Failed , Comment: Pull Request not Approved","l":"INFO","t":""}]';
                }
                else{
                    jsonString = '[{"m":"NEW STATUS: Success , Comment: Pull Request is Approved","l":"INFO","t":""}]';
                }
                // Convert JSON string to Blob
                Blob jsonBlob = Blob.valueOf(jsonString);
                
                // Create Attachment object
                Attachment attachment = new Attachment();
                attachment.ParentId = deployments[0].Id; // ID of the record to which the attachment is linked
                attachment.Name = deployments[0].Id+'.json'; // Name of the attachment file
                attachment.Body = jsonBlob; // The JSON content
                attachment.ContentType = 'application/json'; // Set the content type to JSON
                
                // Insert the attachment
                insert attachment;
            }
        }
    }
    public void handleSuccessfulPR(List<copado__Step__c> jobstep){
        String jsonString;
        for (copado__Step__c step : jobstep) {
            List<copado__Deployment_Job__c> deployments = [
                SELECT Id, copado__Step__c, copado__Status__c
                FROM copado__Deployment_Job__c 
                WHERE copado__Step__c = :step.Id
            ];

            copado__Step__c step_branch = [
                SELECT Id, copado__Branch__c, copado__Deployment__c 
                FROM copado__Step__c 
                WHERE copado__Deployment__c = :step.copado__Deployment__c 
                AND copado__Branch__c != NULL 
                LIMIT 1
            ];
            
            // Check if step_branch has been found
            if (step_branch != null) {
                // Retrieve the pull request object
                copado__Pull_Request__c cpr_approved = [
                    SELECT Id, Branch_Name__c, Pull_Request_Approved__c 
                    FROM copado__Pull_Request__c 
                    WHERE Branch_Name__c = :step_branch.copado__Branch__c 
                    LIMIT 1
                ];
            
                // Check if the pull request is approved
                if (cpr_approved != null && cpr_approved.Pull_Request_Approved__c == FALSE) {
                    step.addError('Please request for PR Approval');
                }
            } else {
                // Handle the case where no matching step_branch was found
                step.addError('No step_branch found for the given deployment');
            }
            if (!deployments.isEmpty()) {
                if(deployments[0].copado__Status__c == 'Failed'){
                // JSON string with current datetime and comment
                 jsonString = '[{"m":"NEW STATUS: Failed , Comment: Pull Request not Approved","l":"INFO","t":""}]';
                }
                else{
                    jsonString = '[{"m":"NEW STATUS: Success , Comment: Pull Request is Approved","l":"INFO","t":""}]';
                }
                // Convert JSON string to Blob
                Blob jsonBlob = Blob.valueOf(jsonString);
                
                // Create Attachment object
                Attachment attachment = new Attachment();
                attachment.ParentId = deployments[0].Id; // ID of the record to which the attachment is linked
                attachment.Name = deployments[0].Id+'.json'; // Name of the attachment file
                attachment.Body = jsonBlob; // The JSON content
                attachment.ContentType = 'application/json'; // Set the content type to JSON
                
                // Insert the attachment
                insert attachment;
            }
    }
}
}