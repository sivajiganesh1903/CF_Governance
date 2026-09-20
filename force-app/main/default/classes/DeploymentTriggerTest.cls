@IsTest
public class DeploymentTriggerTest {
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
        
        // Create Release Playbook
        Release_Playbook__c playbook = new Release_Playbook__c(Pipeline__c = pipeline.Id);
        insert playbook;
        System.debug('PlayBook Id: ----->>' + playbook.Id);
        
        // Create Release Playbook Item
        Release_Playbook_Item__c playBookItem = new Release_Playbook_Item__c(Release_Playbook__c = playbook.Id,
                                                                             Status__c = 'Not Started', Order__c = 2);
        insert playBookItem;
        System.debug('PlayBook Item Id: ----->>' + playBookItem.Id);
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
        
        // Create test Promotion record
        copado__Promotion__c testPromotion = new copado__Promotion__c(copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id,
                                                                  copado__Project__c = project.Id, OwnerId = UL.userId);
        insert testPromotion;

        // Create test User Story record
        copado__User_Story__c testUserStory = new copado__User_Story__c(copado__User_Story_Title__c = 'Test User Story', Failed_Counter__c = 0, copado__Project__c = project.Id,
                                                                       copado__Environment__c = sourceEnv.Id, copado__Org_Credential__c = sourceCredential.Id);
        insert testUserStory;

        // Create test Promoted User Story record
        copado__Promoted_User_Story__c testPromotedUS = new copado__Promoted_User_Story__c(
            copado__Promotion__c = testPromotion.Id,
            copado__User_Story__c = testUserStory.Id
        );
        insert testPromotedUS;

        // Create initial Deployment record (before update)
        copado__Deployment__c testDeployment = new copado__Deployment__c(
            Name = 'Test Deployment',
            copado__Status__c = 'In Progress',
            copado__Promotion__c = testPromotion.Id
        );
        insert testDeployment;
    }
    @isTest
    static void testDeploymentTrigger() {
        // Fetch test Deployment record
        copado__Deployment__c testDeployment = [SELECT Id, copado__Status__c FROM copado__Deployment__c LIMIT 1];

        // Start test execution
        Test.startTest();
        
        // Update the deployment status to 'Completed with Errors'
        testDeployment.copado__Status__c = 'Completed with Errors';
        update testDeployment;
        
        Test.stopTest();

        // Verify that the User Story's Failed_Counter__c is incremented
        copado__User_Story__c updatedUserStory = [SELECT Id, Failed_Counter__c FROM copado__User_Story__c LIMIT 1];
        System.assertEquals(1, updatedUserStory.Failed_Counter__c, 'Failed_Counter__c should be incremented');
    }
}