@RestResource(urlMapping='/api/webhooks/jira/*')
global without sharing class jiraconnector {
    @HttpPost
    global static void payload() {
        Jira_Webhook__c webhookRecord = new Jira_Webhook__c();
        // Retrieve the incoming request
        RestRequest req = RestContext.request;
        system.debug('Request === '+req);
        RestResponse response = RestContext.response;
        
        // Get Custom Settings
        JiraConnectorSettings__c settings = JiraConnectorSettings__c.getInstance();
        String jiraProjectKey = settings.ProjectKey__c; // New line to get project key from custom settings
        System.debug('jiraProjectKey: ' + jiraProjectKey);
        
        try {
            webhookRecord.Response__c = req.requestBody.toString();
            system.debug('request.requestBody.toString() ===='+req.requestBody.toString());
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString()); 
            webhookRecord.action__c = payload.get('webhookEvent').toString();
            string action = payload.get('webhookEvent').toString();
            system.debug('action === '+action);
            //System.debug('Request body: ' + request.requestBody.toString());')
            if (action.equals('jira:issue_created')){
            Map<String,Object> issue = (Map<String, Object>) payload.get('issue');
            Map<String,Object> fields = (Map<String,Object>) issue.get('fields');
            Map<String,Object> project = (Map<String, Object>) fields.get('project');
            string projectkey = project.get('key').toString();
            system.debug('project key === '+projectkey);
            
                if (projectkey == jiraProjectKey){
                    system.debug('entered into issue_created');
                    jiraconnectorhelper.storycreated(payload);
                }
                else{
                    return;
                }
            }
            if(action.equals('jira:issue_updated')){
                Map<String,Object> issue = (Map<String, Object>) payload.get('issue');
                Map<String,Object> fields = (Map<String,Object>) issue.get('fields');
                Map<String,Object> project = (Map<String, Object>) fields.get('project');
                string projectkey = project.get('key').toString();
                system.debug('project key === '+projectkey);
                if (projectkey == jiraProjectKey){
                    system.debug('entered into issue_updated');
                    jiraconnectorhelper.issueupdated(payload);
                }
                else{
                    return;
                }
            }
            if(action.equals('issuelink_created')){
                system.debug('entered into issuelink_created');
                jiraconnectorhelper.issuelinkcreated(payload);
            }
            if(action.equals('issuelink_deleted')){
                system.debug('entered into issuelink_deleted');

                jiraconnectorhelper.issuelinkdeleted(payload);
            }

            // Insert the record
            insert webhookRecord;
            response.statusCode = 200;
            response.responseBody = Blob.valueOf('{"status": "success from salesforce"}');
            
        } catch (Exception e) {
            System.debug('Exception Captured +++ ' + e.getMessage());
            webhookRecord.Error__c = e.getMessage();
            response.responseBody = Blob.valueOf(e.getMessage());
            insert webhookRecord;
        }
    }
}