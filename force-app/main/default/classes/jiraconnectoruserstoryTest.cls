@isTest
public class jiraconnectoruserstoryTest {
    
    @TestSetup
    static void setupTestData() {
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
        
        // Create API Key
        copado__Personal_Settings__c apiKey = new copado__Personal_Settings__c();
        apiKey.SetupOwnerId = currentUser.Id;
        apiKey.copado__API_Key__c = 'test-api-key-123';
        insert apiKey;
        
        // Create Git Repository
        copado__Git_Repository__c repo = new copado__Git_Repository__c (
            Name = 'Test Repo', copado__URI__c = 'https://github.com/test/test.git');
        insert repo;
        
        // Create Pipeline
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
            Name = 'Test Pipeline', copado__Active__c = true, copado__Platform__c = 'Salesforce', 
            copado__Git_Repository__c = repo.Id, copado__Main_Branch__c = 'main');
        insert pipeline;
        
        // Create Project
        copado__Project__c project = new copado__Project__c(
            Name = 'Test Project Name', copado__Deployment_Flow__c = pipeline.Id, copado__Start_Date__c = Date.today(),
            copado__End_Date__c = Date.today().addDays(30), copado__Status__c = 'Active');
        insert project;
        // Commented Type Field CFEC__Type__c = 'DEV',
        // Create Source Environment 
        copado__Environment__c sourceEnv = new copado__Environment__c(
            Name = 'TEST_DEV1', copado__Type__c = 'Sandbox',  Type__c = 'DEV', 
            copado__Platform__c = 'Salesforce');
        insert sourceEnv;
        // Commented Type Field CFEC__Type__c = 'DEV',
        // Create Destination Environment
        copado__Environment__c destEnv = new copado__Environment__c(
            Name = 'TEST_INT1', copado__Type__c = 'Sandbox',  Type__c = 'INT', 
            copado__Platform__c = 'Salesforce');
        insert destEnv;
        
        // Create Source Credential
        copado__Org__c sourceCredential = new copado__Org__c(
            Name = 'TEST_DEV1', copado__Org_Type__c = 'Sandbox', copado__Environment__c = sourceEnv.Id,
            copado__Default_Credential__c = true, copado__Username__c = 'test@test.com', OwnerId = currentUser.Id);
        insert sourceCredential;
        
        // Create Destination Credential
        copado__Org__c destCredential = new copado__Org__c(
            Name = 'TEST_INT1', copado__Org_Type__c = 'Sandbox', copado__Environment__c = destEnv.Id,
            copado__Default_Credential__c = true, copado__Username__c = 'test2@test.com', OwnerId = currentUser.Id);
        insert destCredential;
        
        // Create Pipeline Connection
        copado__Deployment_Flow_Step__c pipelineConnection = new copado__Deployment_Flow_Step__c(
            copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id,
            copado__Deployment_Flow__c = pipeline.Id, copado__Branch__c = 'feature/test-branch',
            copado__Test_Level__c = 'NoTestRun');
        insert pipelineConnection;
        
        // Create Custom Setting
        JiraConnectorSettings__c settings = new JiraConnectorSettings__c(
            Status__c = 'Approved', DestinationEnvironment__c = 'TEST_INT', TriggerLogicFlag__c = true);
        insert settings;
    }
    
    @isTest
    static void testTriggerWithPromoteChange() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        copado__Project__c project = [SELECT Id FROM copado__Project__c LIMIT 1];
        copado__Environment__c sourceEnv = [SELECT Id FROM copado__Environment__c WHERE Name = 'TEST_DEV1' LIMIT 1];
        copado__Org__c sourceCredential = [SELECT Id FROM copado__Org__c WHERE Name = 'TEST_DEV1' LIMIT 1];
        
        // Create User Story with all required relationships
        Copado__User_Story__c userStory = new Copado__User_Story__c(
            copado__User_Story_Title__c = 'US1', copado__Project__c = project.Id,
            copado__Org_Credential__c = sourceCredential.Id, copado__Environment__c = sourceEnv.Id,
            copado__Status__c = 'Draft', copado__Promote_Change__c = false);
        insert userStory;
        
        // Create Change Story
        Change_Story__c changeStory = new Change_Story__c(Name = 'CS1', Status__c = 'Approved');
        insert changeStory;
        
        // Create Change Story List
        Change_Story_List__c changeStoryList = new Change_Story_List__c(User_Story__c = userStory.Id, 
                                                                        Change_Story__c = changeStory.Id);
        insert changeStoryList;
        
        Test.startTest();
        userStory.copado__Promote_Change__c = true;
        update userStory;
        Test.stopTest();
        
        // Verify the update
        Copado__User_Story__c updatedStory = [SELECT Id, copado__Promote_Change__c FROM Copado__User_Story__c 
                                              WHERE Id = :userStory.Id];
        System.assertEquals(true, updatedStory.copado__Promote_Change__c);
    }
    
    @isTest
    static void testValidationWithDisabledTriggerLogic() {
        // Get the existing custom setting record and update it
        JiraConnectorSettings__c settings = JiraConnectorSettings__c.getInstance();
        settings.TriggerLogicFlag__c = false;
        upsert settings;
        
        copado__Project__c project = [SELECT Id FROM copado__Project__c LIMIT 1];
        copado__Environment__c sourceEnv = [SELECT Id FROM copado__Environment__c WHERE Name = 'TEST_DEV1' LIMIT 1];
        copado__Org__c sourceCredential = [SELECT Id FROM copado__Org__c WHERE Name = 'TEST_DEV1' LIMIT 1];
        
        Copado__User_Story__c userStory = new Copado__User_Story__c(
            copado__User_Story_Title__c = 'US3',
            copado__Project__c = project.Id,
            copado__Org_Credential__c = sourceCredential.Id,
            copado__Environment__c = sourceEnv.Id,
            copado__Status__c = 'Draft',
            copado__Promote_Change__c = false
        );
        insert userStory;
        
        Test.startTest();
        List<String> results = jiraconnectoruserstory.validation(new List<Copado__User_Story__c>{userStory});
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when trigger logic is disabled');
    }
    
    @isTest
    static void testValidationWithNoChangeStory() {
        copado__Project__c project = [SELECT Id FROM copado__Project__c LIMIT 1];
        
        // Get both environments
        copado__Environment__c sourceEnv = [SELECT Id, Name FROM copado__Environment__c WHERE Name = 'TEST_DEV1' LIMIT 1];
        copado__Environment__c destEnv = [SELECT Id, Name FROM copado__Environment__c WHERE Name = 'TEST_INT1' LIMIT 1];
        copado__Org__c sourceCredential = [SELECT Id FROM copado__Org__c WHERE Name = 'TEST_DEV1' LIMIT 1];
        
        // Create User Story with source environment
        Copado__User_Story__c userStory = new Copado__User_Story__c(
            copado__User_Story_Title__c = 'US4',
            copado__Project__c = project.Id,
            copado__Org_Credential__c = sourceCredential.Id,
            copado__Environment__c = sourceEnv.Id,
            copado__Status__c = 'Draft',
            copado__Promote_Change__c = false
        );
        insert userStory;
        
        // Update Custom Settings to match the destination environment
        JiraConnectorSettings__c settings = JiraConnectorSettings__c.getOrgDefaults();
        settings.DestinationEnvironment__c = destEnv.Name;
        settings.Status__c = 'Approved';
        settings.TriggerLogicFlag__c = true;
        upsert settings;
        
        Test.startTest();
        try {
            // Query the full user story record including relationships
            userStory = [SELECT Id, Name, copado__Environment__r.Name, copado__Project__c 
                         FROM Copado__User_Story__c 
                         WHERE Id = :userStory.Id];
            
            // Call the validation method directly
            List<String> results = jiraconnectoruserstory.validation(new List<Copado__User_Story__c>{userStory});
            System.assert(false, 'Should throw an exception');
        } catch(jiraconnectoruserstory.CustomException e) {
            // Verify the specific exception message
            System.assert(e.getMessage().contains('No Change Story Found'), 
                         'Expected error message about missing Change Story, got: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidationWithUnapprovedChangeStory() {
        copado__Project__c project = [SELECT Id FROM copado__Project__c LIMIT 1];
        
        // Get both environments
        copado__Environment__c sourceEnv = [SELECT Id, Name FROM copado__Environment__c WHERE Name = 'TEST_DEV1' LIMIT 1];
        copado__Environment__c destEnv = [SELECT Id, Name FROM copado__Environment__c WHERE Name = 'TEST_INT1' LIMIT 1];
        copado__Org__c sourceCredential = [SELECT Id FROM copado__Org__c WHERE Name = 'TEST_DEV1' LIMIT 1];
        
        // Create User Story with source environment
        Copado__User_Story__c userStory = new Copado__User_Story__c(
            copado__User_Story_Title__c = 'US5',
            copado__Project__c = project.Id,
            copado__Org_Credential__c = sourceCredential.Id,
            copado__Environment__c = sourceEnv.Id,
            copado__Status__c = 'Draft',
            copado__Promote_Change__c = false
        );
        insert userStory;
        
        // Create Change Story with unapproved status
        Change_Story__c changeStory = new Change_Story__c(
            Name = 'CS5', 
            Status__c = 'Draft'  // Unapproved status
        );
        insert changeStory;
        
        // Create Change Story List
        Change_Story_List__c changeStoryList = new Change_Story_List__c(
            User_Story__c = userStory.Id,
            Change_Story__c = changeStory.Id
        );
        insert changeStoryList;
        
        // Update Custom Settings to match the destination environment
        JiraConnectorSettings__c settings = JiraConnectorSettings__c.getOrgDefaults();
        settings.DestinationEnvironment__c = destEnv.Name;
        settings.Status__c = 'Approved'; // Set the required status
        settings.TriggerLogicFlag__c = true;
        upsert settings;
        
        Test.startTest();
        try {
            // Query the full user story record including relationships
            userStory = [SELECT Id, Name, copado__Environment__r.Name, copado__Project__c 
                         FROM Copado__User_Story__c 
                         WHERE Id = :userStory.Id];
            
            // Call the validation method
            List<String> results = jiraconnectoruserstory.validation(new List<Copado__User_Story__c>{userStory});
            System.assert(false, 'Should throw an exception');
        } catch(jiraconnectoruserstory.CustomException e) {
            // Verify the specific exception message
            System.assert(e.getMessage().contains('Change Story is not approved'), 
                         'Expected error message about unapproved Change Story, got: ' + e.getMessage());
        }
        Test.stopTest();
    } 
    
}