@IsTest
public class StepTriggerHandlerTest {
    @TestSetup
    public static void setupTestData(){
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];        
        // Set up Copado License
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense UL = new copado.GlobalAPI.UserLicense();
        UL.isCADEnabled = false; 
        UL.isCCHEnabled = false; 
        UL.isCCMEnabled = true; 
        UL.isCopadoEnabled = true; 
        UL.userId = currentUser.Id;
        copado.GlobalAPI.LicenseOperationResult result = copadoGlobalAPI.upsertCopadoLicense(UL);        
        System.runAs(currentUser) {
            // Create Git Repository
            copado__Git_Repository__c repo = new copado__Git_Repository__c (
                Name = 'Test Repo', 
                copado__URI__c = 'https://github-dmz.edwardjones.com/ej-fbs-salesforce/TrainingRepository.git'
            );
            insert repo;            
            // Create Pipeline
            copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
                Name = 'Test Pipeline', copado__Active__c = true, copado__Platform__c = 'Salesforce', 
                copado__Git_Repository__c = repo.Id, copado__Main_Branch__c = 'main');
            insert pipeline;            
            // Create Environments
            // // Commneted tyep filed CFEC__Type__c
            copado__Environment__c sourceEnv = new copado__Environment__c(
                Name = 'TEST_DEV1', copado__Type__c = 'Sandbox',
                Type__c = 'DEV', copado__Platform__c = 'Salesforce');
            insert sourceEnv;                    
            copado__Environment__c destEnv = new copado__Environment__c(
                Name = 'TEST_INT1', copado__Type__c = 'Sandbox', Enable_PR_Approval__c = true,  
                Type__c = 'INT', copado__Platform__c = 'Salesforce');
            insert destEnv;           
            copado__Environment__c destUAT = new copado__Environment__c(
                Name = 'TEST_UAT1', copado__Type__c = 'Sandbox', Type__c = 'UAT', 
                copado__Platform__c = 'Salesforce');
            insert destUAT;            
            // Create Project
            copado__Project__c project = new copado__Project__c(
                Name = 'Test Project Name', copado__Deployment_Flow__c = pipeline.Id, copado__Start_Date__c = Date.today(),
                copado__End_Date__c = Date.today().addDays(30), copado__Status__c = 'Active');
            insert project;            
            // Create Pipeline Connections
            copado__Deployment_Flow_Step__c pipelineConnectionINT = new copado__Deployment_Flow_Step__c(
                copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id,
                copado__Deployment_Flow__c = pipeline.Id, copado__Branch__c = 'feature/test-branch',
                copado__Test_Level__c = 'NoTestRun');
            insert pipelineConnectionINT;
            copado__Deployment_Flow_Step__c pipelineConnectionUAT = new copado__Deployment_Flow_Step__c(
                copado__Source_Environment__c = destEnv.Id, copado__Destination_Environment__c = destUAT.Id,
                copado__Deployment_Flow__c = pipeline.Id, copado__Branch__c = 'feature/test-branch-1',
                copado__Test_Level__c = 'NoTestRun');
            insert pipelineConnectionUAT;            
            // Create Credentials
            copado__Org__c sourceCredential = new copado__Org__c(
                Name = 'TEST_DEV1', copado__Org_Type__c = 'Sandbox', copado__Environment__c = sourceEnv.Id,
                copado__Default_Credential__c = true, copado__Username__c = 'test@test.com', OwnerId = currentUser.Id);
            insert sourceCredential;            
            copado__Org__c destCredential = new copado__Org__c(
                Name = 'TEST_INT1', copado__Org_Type__c = 'Sandbox', copado__Environment__c = destEnv.Id,
                copado__Default_Credential__c = true, copado__Username__c = 'test2@test.com', OwnerId = currentUser.Id);
            insert destCredential;            
            // Create test team
            copado__Team__c team = new copado__Team__c(Name = 'Test Team', Tech_Lead_Name__c = 'testTechLead');
            insert team;            
            // Create test user story
            copado__User_Story__c userStory = new copado__User_Story__c(
                copado__User_Story_Title__c = 'Test Story', copado__Org_Credential__c = sourceCredential.Id,
                copado__Environment__c = sourceEnv.Id, copado__Project__c = project.Id, copado__Team__c = team.Id, 
                copado__Status__c = 'Draft');
            insert userStory;           
            // Create Promotion
            copado__Promotion__c promotion = new copado__Promotion__c(
                copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id,
                copado__Project__c = project.Id, OwnerId = currentUser.Id, copado__Status__c = 'Draft',
                copado__Source_Org_Credential__c = sourceCredential.Id, copado__Destination_Org_Credential__c = destCredential.Id);
            insert promotion;           
            // Create deployment
            copado__Deployment__c deployment = new copado__Deployment__c(
                Name = 'Test Deployment', copado__From_Org__c = sourceCredential.Id, copado__Promotion__c = promotion.Id,
                copado__Status__c = 'Draft');
            insert deployment;            
            // Create promoted user story
            copado__Promoted_User_Story__c promotedUserStory = new copado__Promoted_User_Story__c(
                copado__User_Story__c = userStory.Id, copado__Promotion__c = promotion.Id, copado__Status__c = 'Active');
            insert promotedUserStory;
        }
    }
    
    @isTest
    static void testGitPromotionStepCreation() {
        copado__Deployment__c deployment = [SELECT Id FROM copado__Deployment__c LIMIT 1];
        
        // Set the mock before any DML operations
        Test.setMock(HttpCalloutMock.class, new GitHubAPICalloutMock());       
        Test.startTest();
        copado__Step__c step = new copado__Step__c(
            Name = 'Test Step', copado__Type__c = 'Git Promotion', copado__Deployment__c = deployment.Id,
            copado__Branch__c = 'feature/test-branch-' + DateTime.now().getTime(), copado__CheckOnly__c = false);
        insert step;
        Test.stopTest();
        
        copado__Step__c insertedStep = [SELECT Id, copado__Type__c, copado__Status__c FROM copado__Step__c WHERE Id = :step.Id];
        System.assertEquals('Git Promotion', insertedStep.copado__Type__c);
    }
    
    @isTest
    static void testNonGitPromotionStep() {
        copado__Deployment__c deployment = [SELECT Id FROM copado__Deployment__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new GitHubAPICalloutMock());
        Test.startTest();
        copado__Step__c step = new copado__Step__c(Name = 'Test Step', copado__Type__c = 'Data', 
                                                   copado__Deployment__c = deployment.Id);
        insert step;
        Test.stopTest();
        
        copado__Step__c insertedStep = [SELECT Id, copado__Type__c FROM copado__Step__c WHERE Id = :step.Id];
        System.assertEquals('Data', insertedStep.copado__Type__c);
    }
    
    // Enhanced mock class to handle all callout scenarios
    private class GitHubAPICalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');           
            if (req.getEndpoint().contains('/pulls')) {
                // Mock pull request creation response
                res.setBody('{"number": 1, "id": 12345, "url": "https://api.github.com/repos/test/test/pulls/1"}');
                res.setStatusCode(201);
            } else if (req.getEndpoint().contains('/requested_reviewers')) {
                // Mock reviewer assignment response
                res.setBody('{"id": 12345, "reviewers": [{"login": "testTechLead"}]}');
                res.setStatusCode(201);
            } else {
                // Default response for any other endpoints
                res.setStatusCode(404);
            }            
            return res;
        }
    }
}