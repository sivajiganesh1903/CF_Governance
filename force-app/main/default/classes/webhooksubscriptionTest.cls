@IsTest
private class webhooksubscriptionTest {
    
    @TestSetup
    static void setupTestData() {
        // Set up Copado License
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense UL = new copado.GlobalAPI.UserLicense();
        UL.isCADEnabled = false; 
        UL.isCCHEnabled = false; 
        UL.isCCMEnabled = true; 
        UL.isCopadoEnabled = true; 
        UL.userId = UserInfo.getUserId();
        copado.GlobalAPI.LicenseOperationResult result = copadoGlobalAPI.upsertCopadoLicense(UL);
        
        // Create Pipeline
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(Name = 'Test Pipeline', copado__Active__c = true,
                                                                             copado__Platform__c = 'Salesforce');
        insert pipeline;
        
        // Create Project
        copado__Project__c project = new copado__Project__c(Name = 'Test Project Name', copado__Deployment_Flow__c = pipeline.Id);
        insert project;
        
        // Create Environments
        copado__Environment__c sourceEnv = new copado__Environment__c(Name = 'TEST_DEV1', copado__Type__c = 'Sandbox',
                                                                      Type__c = 'DEV', copado__Platform__c = 'Salesforce');
        insert sourceEnv;        
        copado__Environment__c destEnv = new copado__Environment__c(Name = 'TEST_QA1', copado__Type__c = 'Sandbox',
                                                                    Type__c = 'DEV', copado__Platform__c = 'Salesforce');
        insert destEnv;
        
        // Create Pipeline Connection
        copado__Deployment_Flow_Step__c pipelineConnection = new copado__Deployment_Flow_Step__c(
            copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id, 
            copado__Deployment_Flow__c = pipeline.Id);
        insert pipelineConnection;
        
        // Create Credentials
        copado__Org__c sourceCredential = new copado__Org__c(Name = 'TEST_DEV1', copado__Org_Type__c = 'Sandbox',
                                                             copado__Environment__c = sourceEnv.Id, copado__Default_Credential__c = true, 
                                                             copado__Username__c = 'test@test.com', OwnerId = UL.userId);
        insert sourceCredential;
        copado__Org__c destCredential = new copado__Org__c(Name = 'TEST_QA1', copado__Org_Type__c = 'Sandbox',
                                                           copado__Environment__c = destEnv.Id, copado__Default_Credential__c = true,
                                                           copado__Username__c = 'test2@test.com', OwnerId = UL.userId);
        insert destCredential;
        
        // Create User Story
        copado__User_Story__c us = new copado__User_Story__c(copado__User_Story_Title__c = 'Test User Story', copado__Org_Credential__c = sourceCredential.Id, 
                                                             copado__Project__c = project.Id, copado__Environment__c = sourceEnv.Id);
        insert us;
        
        // Create Promotion
        copado__Promotion__c promotion = new copado__Promotion__c(copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id,
                                                                  copado__Project__c = project.Id, OwnerId = UL.userId);
        insert promotion;
        
        // Create Promoted User Story linked to Promotion
        copado__Promoted_User_Story__c pus = new copado__Promoted_User_Story__c(
            copado__User_Story__c = us.Id,
            copado__Promotion__c = promotion.Id,
            copado__Status__c = 'Active'
        );
        insert pus;
        
        // Create Deployment
        copado__Deployment__c deployment = new copado__Deployment__c(Name = 'Test Deployment', copado__From_Org__c = sourceCredential.Id,
                                                                     copado__Promotion__c = promotion.Id, copado__Status__c = 'Draft');
        insert deployment;	     
    } 
    
    @isTest
    static void testOpened() {
        Test.startTest();
        Map<String, Object> base = new Map<String, Object>{ 'ref' => 'main' };
        Map<String, Object> head = new Map<String, Object>{ 'ref' => 'promotion/P08958-DeploySomething' };
        Map<String, Object> user = new Map<String, Object>{ 'login' => 'testuser' };

        Map<String, Object> prMap = new Map<String, Object>{
            'state' => 'open', 'title' => 'My PR Title', 'number' => 101, 'html_url' => 'https://github.com/example/pr/101',
            'changed_files' => 5, 'commits' => 2, 'base' => base, 'head' => head, 'user' => user};

        Map<String, Object> wrapper = new Map<String, Object>{ 'pull_request' => prMap };

        webhooksubscriptionhelper.opened(wrapper);
        Test.stopTest();

        // Validate the Pull Request was inserted
        List<copado__Pull_Request__c> insertedPRs = [SELECT Id, Name, copado__User_Story__c FROM copado__Pull_Request__c];
        System.assert(!insertedPRs.isEmpty(), 'Pull Request should be created');
    }
    
    @isTest
    static void testSubmitted() {
        // Insert a Pull Request manually
        copado__Pull_Request__c pr = new copado__Pull_Request__c(
            copado__User_Story__c = [SELECT Id FROM copado__User_Story__c LIMIT 1].Id,
			copado__Url__c = 'https://github.com/example/pr/101');
        insert pr;

        Map<String, Object> userMap = new Map<String, Object>{
            'login' => 'reviewer1', 'avatar_url' => 'https://avatars.githubusercontent.com/u/1'};

        Map<String, Object> res = new Map<String, Object>{
            'state' => 'approved', 'html_url' => 'https://github.com/example/pr/101', 'user' => userMap};

        Map<String, Object> pr_res = new Map<String, Object>{'html_url' => 'https://github.com/example/pr/101'};

        webhooksubscriptionhelper.submitted(res, '005X00000012345', pr_res);

        List<copado__Pull_Request_Review__c> reviews = [SELECT Id, copado__Review_Action__c FROM 
                                                        copado__Pull_Request_Review__c];
        System.assertEquals('approved', reviews[0].copado__Review_Action__c);
    }
    
    @isTest
    static void testClosedMerged() {
        // Insert a PR Manually
        copado__Pull_Request__c pr = new copado__Pull_Request__c(
            copado__User_Story__c = [SELECT Id FROM copado__User_Story__c LIMIT 1].Id,
            copado__Url__c = 'https://github.com/example/pr/102');
        insert pr;

        Map<String, Object> userMap = new Map<String, Object>{ 'login' => 'merger1' };

        Map<String, Object> res = new Map<String, Object>{
            'html_url' => 'https://github.com/example/pr/102', 'merged' => true, 'state' => 'closed', 'user' => userMap};

        webhooksubscriptionhelper.closed(res);

        copado__Pull_Request__c updatedPR = [SELECT copado__State__c, copado__Merged__c, copado__Merged_By__c FROM 
                                             copado__Pull_Request__c WHERE copado__Url__c = 'https://github.com/example/pr/102' LIMIT 1];
        System.assertEquals('Merged', updatedPR.copado__State__c);
        System.assertEquals(true, updatedPR.copado__Merged__c);
        System.assertEquals('merger1', updatedPR.copado__Merged_By__c);
    }
    
    @isTest
    static void testClosedNotMerged() {
        // Insert a PR Manually
        copado__Pull_Request__c pr = new copado__Pull_Request__c(
            copado__User_Story__c = [SELECT Id FROM copado__User_Story__c LIMIT 1].Id,
            copado__Url__c = 'https://github.com/example/pr/103');
        insert pr;

        Map<String, Object> userMap = new Map<String, Object>{ 'login' => 'closer1' };

        Map<String, Object> res = new Map<String, Object>{
            'html_url' => 'https://github.com/example/pr/103', 'merged' => false, 'state' => 'closed', 'user' => userMap};

        webhooksubscriptionhelper.closed(res);
        
        copado__Pull_Request__c updatedPR = [SELECT copado__State__c, copado__Merged__c FROM copado__Pull_Request__c 
                                             WHERE copado__Url__c = 'https://github.com/example/pr/103' LIMIT 1];
        System.assertEquals('closed', updatedPR.copado__State__c);
        System.assertEquals(false, updatedPR.copado__Merged__c);
    }
    
  	// Code Coverage for Webhook Subscription Class (Parent Class)   
    @IsTest
    static void testHandleNotificationOpened() {
        // Prepare mock request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set the request body and headers
        req.requestUri = '/services/apexrest/api/webhooks/pushDetails';
        req.httpMethod = 'POST';
        req.addHeader('X-Hub-Signature-256', 'mocked_signature');
        req.addHeader('X-GitHub-Delivery', 'mocked_delivery_id');
        
        String jsonPayload = '{"action": "opened", "pull_request": {"id": 1, "title": "Test PR"}}';
        req.requestBody = Blob.valueOf(jsonPayload);
        
        // Assign the request and response to RestContext
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        webhooksubscription.handleNotification();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(200, RestContext.response.statusCode);
        //System.assertEquals('{"status": "success from salesforce"}', RestContext.response.responseBody.toString());
        
        // Verify the Pull_Request_Event__c record
        List<Pull_Request_Event__c> events = [SELECT Id, Event_Type__c, Entire_Payload__c FROM Pull_Request_Event__c];
        System.assertEquals(1, events.size());
        System.assertEquals('opened', events[0].Event_Type__c);
        System.assertEquals(jsonPayload, events[0].Entire_Payload__c);
    }
	
    @IsTest
    static void testHandleNotificationSubmitted() {
        // Prepare mock request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set the request body and headers
        req.requestUri = '/services/apexrest/api/webhooks/pushDetails';
        req.httpMethod = 'POST';
        req.addHeader('X-Hub-Signature-256', 'mocked_signature');
        req.addHeader('X-GitHub-Delivery', 'mocked_delivery_id');
        
        String jsonPayload = '{"action": "submitted", "review": {"id": 1, "state": "approved"}, "pull_request": {"id": 1, "title": "Test PR"}}';
        req.requestBody = Blob.valueOf(jsonPayload);
        
        // Assign the request and response to RestContext
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        webhooksubscription.handleNotification();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(200, RestContext.response.statusCode);
        //System.assertEquals('{"status": "Submitted condition Success"}', RestContext.response.responseBody.toString());
        
        // Verify the Pull_Request_Event__c record
        List<Pull_Request_Event__c> events = [SELECT Id, Event_Type__c, Entire_Payload__c FROM Pull_Request_Event__c];
        System.assertEquals(1, events.size());
        System.assertEquals('submitted', events[0].Event_Type__c);
        System.assertEquals(jsonPayload, events[0].Entire_Payload__c);
        
    }
    
    @IsTest
    static void testHandleNotificationClosed() {
        // Prepare mock request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set the request body and headers
        req.requestUri = '/services/apexrest/api/webhooks/pushDetails';
        req.httpMethod = 'POST';
        req.addHeader('X-Hub-Signature-256', 'mocked_signature');
        req.addHeader('X-GitHub-Delivery', 'mocked_delivery_id');
        
        String jsonPayload = '{"action": "closed", "pull_request": {"id": 1, "title": "Test PR"}}';
        req.requestBody = Blob.valueOf(jsonPayload);
        
        // Assign the request and response to RestContext
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        webhooksubscription.handleNotification();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(200, RestContext.response.statusCode);
        //System.assertEquals('{"status": "success from salesforce Closed"}', RestContext.response.responseBody.toString());
        
        // Verify the Pull_Request_Event__c record
        List<Pull_Request_Event__c> events = [SELECT Id, Event_Type__c, Entire_Payload__c FROM Pull_Request_Event__c];
        System.assertEquals(1, events.size());
        System.assertEquals('closed', events[0].Event_Type__c);
        System.assertEquals(jsonPayload, events[0].Entire_Payload__c);
        
        // Additional verifications if needed
    }
    
    @IsTest
    static void testHandleNotificationException() {
        // Prepare mock request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        // Set the request body and headers
        req.requestUri = '/services/apexrest/api/webhooks/pushDetails';
        req.httpMethod = 'POST';
        req.addHeader('X-Hub-Signature-256', 'mocked_signature');
        req.addHeader('X-GitHub-Delivery', 'mocked_delivery_id');
        
        // Malformed JSON payload to cause an exception
        String jsonPayload = '{"action": "opened", "pull_request": "malformed_payload"}';
        req.requestBody = Blob.valueOf(jsonPayload);
        
        // Assign the request and response to RestContext
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        webhooksubscription.handleNotification();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(200, RestContext.response.statusCode);
        //System.assert(RestContext.response.responseBody.toString().contains('exception'));       
    }
}