@IsTest
private class jiraconnectorTest {
    
    // Setup method to create custom settings
    @TestSetup
    static void setupCustomSettings() {
        JiraConnectorSettings__c settings = new JiraConnectorSettings__c();
        settings.ProjectKey__c = 'TEST_PROJECT';
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        insert settings;
    }
    
    // Mock class for REST callouts
    private class RestRequestMock {
        private String requestBody;
        private String projectKey;
        private String webhookEvent;
        
        public RestRequestMock(String requestBody, String projectKey, String webhookEvent) {
            this.requestBody = requestBody;
            this.projectKey = projectKey;
            this.webhookEvent = webhookEvent;
        }
        
        public String getRequestBody() {
            Map<String, Object> payload = new Map<String, Object>();
            Map<String, Object> issue = new Map<String, Object>();
            Map<String, Object> fields = new Map<String, Object>();
            Map<String, Object> project = new Map<String, Object>();
            
            project.put('key', projectKey);
            fields.put('project', project);
            issue.put('fields', fields);
            
            payload.put('webhookEvent', webhookEvent);
            payload.put('issue', issue);
            
            return JSON.serialize(payload);
        }
    }
    
    @IsTest
    static void testIssueCreated() {
        // Create test request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set request properties
        req.requestURI = '/api/webhooks/jira/';
        req.httpMethod = 'POST';
        
        // Get project key from custom settings
        String projectKey = JiraConnectorSettings__c.getInstance().ProjectKey__c;
        
        // Create mock payload using custom settings value
        RestRequestMock mock = new RestRequestMock('testBody', projectKey, 'jira:issue_created');
        req.requestBody = Blob.valueOf(mock.getRequestBody());
        
        // Set the mock request/response
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        jiraconnector.payload();
        Test.stopTest();
        
        // Verify webhook record was created
        List<Jira_Webhook__c> webhooks = [SELECT Id, action__c FROM Jira_Webhook__c];
        System.assertEquals(1, webhooks.size(), 'Should create one webhook record');
        System.assertEquals('jira:issue_created', webhooks[0].action__c, 'Action should match');
    }
    
    @IsTest
    static void testIssueUpdated() {
        // Create test request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set request properties
        req.requestURI = '/api/webhooks/jira/';
        req.httpMethod = 'POST';
        
        // Get project key from custom settings
        String projectKey = JiraConnectorSettings__c.getInstance().ProjectKey__c;
        
        // Create mock payload using custom settings value
        RestRequestMock mock = new RestRequestMock('testBody', projectKey, 'jira:issue_updated');
        req.requestBody = Blob.valueOf(mock.getRequestBody());
        
        // Set the mock request/response
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        jiraconnector.payload();
        Test.stopTest();
        
        // Verify webhook record was created
        List<Jira_Webhook__c> webhooks = [SELECT Id, action__c FROM Jira_Webhook__c];
        System.assertEquals(1, webhooks.size(), 'Should create one webhook record');
        System.assertEquals('jira:issue_updated', webhooks[0].action__c, 'Action should match');
    }
    
    @IsTest
    static void testIssueLinkCreated() {
        // Create test request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set request properties
        req.requestURI = '/api/webhooks/jira/';
        req.httpMethod = 'POST';
        
        // Create mock payload for issue link
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> issueLink = new Map<String, Object>();
        Map<String, Object> sourceIssue = new Map<String, Object>();
        Map<String, Object> destinationIssue = new Map<String, Object>();
        
        sourceIssue.put('key', 'TEST-123');
        destinationIssue.put('key', 'TEST-456');
        issueLink.put('sourceIssue', sourceIssue);
        issueLink.put('destinationIssue', destinationIssue);
        
        payload.put('webhookEvent', 'issuelink_created');
        payload.put('issueLink', issueLink);
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        
        // Set the mock request/response
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        jiraconnector.payload();
        Test.stopTest();
        
        // Verify webhook record was created
        List<Jira_Webhook__c> webhooks = [SELECT Id, action__c FROM Jira_Webhook__c];
        System.assertEquals(1, webhooks.size(), 'Should create one webhook record');
        System.assertEquals('issuelink_created', webhooks[0].action__c, 'Action should match');
    }
    
    @IsTest
    static void testIssueLinkDeleted() {
        // Create test request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set request properties
        req.requestURI = '/api/webhooks/jira/';
        req.httpMethod = 'POST';
        
        // Create mock payload for issue link deletion
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> issueLink = new Map<String, Object>();
        Map<String, Object> sourceIssue = new Map<String, Object>();
        Map<String, Object> destinationIssue = new Map<String, Object>();
        
        sourceIssue.put('key', 'TEST-123');
        destinationIssue.put('key', 'TEST-456');
        issueLink.put('sourceIssue', sourceIssue);
        issueLink.put('destinationIssue', destinationIssue);
        
        payload.put('webhookEvent', 'issuelink_deleted');
        payload.put('issueLink', issueLink);
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        
        // Set the mock request/response
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        jiraconnector.payload();
        Test.stopTest();
        
        // Verify webhook record was created
        List<Jira_Webhook__c> webhooks = [SELECT Id, action__c FROM Jira_Webhook__c];
        System.assertEquals(1, webhooks.size(), 'Should create one webhook record');
        System.assertEquals('issuelink_deleted', webhooks[0].action__c, 'Action should match');
    }
    
    @IsTest
    static void testInvalidProjectKey() {
        // Create test request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set request properties
        req.requestURI = '/api/webhooks/jira/';
        req.httpMethod = 'POST';
        
        // Create mock payload with invalid project key
        RestRequestMock mock = new RestRequestMock('testBody', 'INVALID', 'jira:issue_created');
        req.requestBody = Blob.valueOf(mock.getRequestBody());
        
        // Set the mock request/response
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        jiraconnector.payload();
        Test.stopTest();
        
        // Verify no webhook record was created
        List<Jira_Webhook__c> webhooks = [SELECT Id, action__c FROM Jira_Webhook__c];
        System.assertEquals(0, webhooks.size(), 'Should not create webhook record for invalid project key');
    }
    
    @IsTest
    static void testExceptionHandling() {
        // Create test request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set request properties
        req.requestURI = '/api/webhooks/jira/';
        req.httpMethod = 'POST';
        
        // Set invalid JSON to trigger exception
        req.requestBody = Blob.valueOf('Invalid JSON');
        
        // Set the mock request/response
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        jiraconnector.payload();
        Test.stopTest();
        
        // Verify webhook record was created with error
        List<Jira_Webhook__c> webhooks = [SELECT Id, Error__c FROM Jira_Webhook__c];
        System.assertEquals(1, webhooks.size(), 'Should create one webhook record');
        System.assertNotEquals(null, webhooks[0].Error__c, 'Should have error message');
    }
    
    @IsTest
    static void testNullProjectKey() {
        // Create test request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set request properties
        req.requestURI = '/api/webhooks/jira/';
        req.httpMethod = 'POST';
        
        // Create payload with null project key
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> issue = new Map<String, Object>();
        Map<String, Object> fields = new Map<String, Object>();
        Map<String, Object> project = new Map<String, Object>();
        
        project.put('key', null);
        fields.put('project', project);
        issue.put('fields', fields);
        payload.put('webhookEvent', 'jira:issue_created');
        payload.put('issue', issue);
        
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        
        // Set the mock request/response
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        jiraconnector.payload();
        Test.stopTest();
        
        // Verify webhook record handling
        List<Jira_Webhook__c> webhooks = [SELECT Id, Error__c FROM Jira_Webhook__c];
        System.assertEquals(1, webhooks.size(), 'Should create one webhook record');
    }
}