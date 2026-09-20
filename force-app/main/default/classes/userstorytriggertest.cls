@IsTest
private class userstorytriggertest {
    @TestSetup 
    static void makeData(){
        
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
        
        // Create test environments
        copado__Environment__c sourceEnv = new copado__Environment__c(Name = 'Trn Dev1', copado__Type__c = 'Sandbox', Type__c = 'DEV', 
                                                                      copado__Platform__c = 'Salesforce');
        insert sourceEnv;
        
        copado__Environment__c destEnv = new copado__Environment__c(Name = 'TrnInt', copado__Type__c = 'Sandbox', Type__c = 'DEV', 
                                                                    copado__Platform__c = 'Salesforce');
        insert destEnv;
        
        // Create Pipeline Connection
        copado__Deployment_Flow_Step__c pipelineConnection = new copado__Deployment_Flow_Step__c(
            copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id, copado__Deployment_Flow__c = pipeline.Id);
        insert pipelineConnection;
        
        // Create Credentials
        copado__Org__c sourceCredential = new copado__Org__c(Name = 'TEST_DEV1', copado__Org_Type__c = 'Sandbox', copado__Environment__c = sourceEnv.Id, 
                                                             copado__Default_Credential__c = true, copado__Username__c = 'test@test.com', OwnerId = UL.userId);
        insert sourceCredential;
        
        copado__Org__c destCredential = new copado__Org__c(Name = 'TEST_QA1', copado__Org_Type__c = 'Sandbox', copado__Environment__c = destEnv.Id, 
                                                           copado__Default_Credential__c = true, copado__Username__c = 'test2@test.com', OwnerId = UL.userId);
        insert destCredential;
        
        // Create test user stories
        List<copado__User_Story__c> userStories = new List<copado__User_Story__c>();
        for(Integer i = 0; i < 3; i++) {
            userStories.add(new copado__User_Story__c(
                copado__User_Story_Title__c = 'Test Story ' + i, copado__Status__c = 'Draft', copado__Environment__c = sourceEnv.Id,
                copado__Project__c = project.Id, copado__Developer__c = UserInfo.getUserId(), Jira_Key__c = 'JIRA-' + (100 + i)));
        }
        insert userStories;
        
        // Create promotions
        copado__Promotion__c promotion = new copado__Promotion__c(copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id,
                                                                  copado__Project__c = project.Id, OwnerId = UL.userId, copado__Status__c = 'Completed');
        insert promotion;
        
        // Create promoted user stories
        List<copado__Promoted_User_Story__c> promotedStories = new List<copado__Promoted_User_Story__c>();
        for(copado__User_Story__c story : userStories) {
            promotedStories.add(new copado__Promoted_User_Story__c(copado__User_Story__c = story.Id, copado__Promotion__c = promotion.Id,
                                                                   copado__Status__c = 'Active'));
        }
        insert promotedStories;
        
        // Create a deployment record
        copado__Deployment__c deployment = new copado__Deployment__c(copado__Status__c = 'Completed', copado__Deployment_Type__c = 'Standard',
                                                                     copado__Promotion__c = promotion.Id);
        insert deployment;
    }
    
    @IsTest 
    static void testUserStoryCancellation() {
        List<copado__User_Story__c> storiesToUpdate = [SELECT Id, copado__Status__c FROM copado__User_Story__c LIMIT 2];
        
        Test.startTest();
        for(copado__User_Story__c story : storiesToUpdate) {
            story.copado__Status__c = 'Cancelled';
        }
        update storiesToUpdate;
        Test.stopTest();       
        List<Issue_Tracker__c> rollbackRequests = [SELECT Id FROM Issue_Tracker__c WHERE User_Story_Impacted__c IN :storiesToUpdate];        
        System.assertEquals(2, rollbackRequests.size(), 'Should create one rollback request per cancelled story');
    }
    
    @IsTest 
    static void testBulkUserStoryCancellation() {
        List<copado__User_Story__c> storiesToUpdate = [SELECT Id, copado__Status__c FROM copado__User_Story__c LIMIT 3];
        
        Test.startTest();
        for(copado__User_Story__c story : storiesToUpdate) {
            story.copado__Status__c = 'Cancelled';
        }
        update storiesToUpdate;
        Test.stopTest();
        
        List<Issue_Tracker__c> rollbackRequests = [SELECT Id FROM Issue_Tracker__c WHERE User_Story_Impacted__c IN :storiesToUpdate];
        
        System.assertEquals(3, rollbackRequests.size(), 'Should handle bulk cancellations correctly');
    }
    
    @IsTest
    static void testDependencyStatusUpdate() {
        // Get a provider story
        copado__User_Story__c providerStory = [SELECT Id, copado__Status__c FROM copado__User_Story__c WHERE copado__User_Story_Title__c LIKE 'Test Story%' LIMIT 1];
        System.debug('Provider UserStory: ++++++' + providerStory);
        // Create dependent user story
        copado__User_Story__c dependentStory = new copado__User_Story__c(
            copado__User_Story_Title__c = 'Dependent Story', copado__Status__c = 'Draft', copado__Developer__c = UserInfo.getUserId(),
            copado__Project__c = [SELECT Id FROM copado__Project__c LIMIT 1].Id, Jira_Key__c = 'JIRA-999');
        insert dependentStory;
        System.debug('Dependent UserStory: ++++++' + dependentStory);
        // Create dependency
        copado__Team_Dependency__c dependency = new copado__Team_Dependency__c(copado__Provider_User_Story__c = providerStory.Id, 
                                                                               copado__Dependent_User_Story__c = dependentStory.Id);
        insert dependency;
        System.debug('Dependencey: ++++++' + dependency);
        Test.startTest();
        providerStory.copado__Status__c = 'Cancelled';
        update providerStory;
        Test.stopTest();
        System.debug('Updated Provided Story: +++++' + providerStory);
        // Verify dependent story status was updated
        copado__User_Story__c updatedDependentStory = [SELECT copado__Status__c FROM copado__User_Story__c WHERE Id = :dependentStory.Id];
        System.assertEquals('Draft', updatedDependentStory.copado__Status__c, 'Dependent story status should match provider story status');
    }
}