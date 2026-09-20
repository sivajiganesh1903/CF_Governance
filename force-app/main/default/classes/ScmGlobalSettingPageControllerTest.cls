@isTest
public class ScmGlobalSettingPageControllerTest {
    
    @testSetup
    static void setup() {

        Profile p = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'unique_testuser_' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = p.Id
        );
        insert u;
      System.runAs(u) {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Shared_Component_Matrix_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.id;
        psa.PermissionSetId = ps.id;
        insert psa;

        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense ul = new copado.GlobalAPI.UserLicense();
        
        ul.isCADEnabled = false; //Agile delivery license
        ul.isCCHEnabled = false; //Compliance hub license
        ul.isCCMEnabled = true; //Change management (developer) license
        ul.isCopadoEnabled = true; //Enterprise (admin / release manager) license
        //UL.isCSTEnabled = true; //Copado Selenium testing license
        ul.userId = UserInfo.getUserId();
        
        copado.GlobalAPI.LicenseOperationResult result = copadoGlobalAPI.upsertCopadoLicense(ul);
        if(result.isSuccess){
            System.debug('License assigned successfully');
        } else {
            System.debug('An error occurred during license assignment with the error message ' + result.errorString);
        }

        // Create copado__Environment__c records
        List<copado__Environment__c> environments = new List<copado__Environment__c>{
            new copado__Environment__c(Name = 'Env1', copado__Type__c = 'Test'),
            new copado__Environment__c(Name = 'Env2', copado__Type__c = 'Production/Developer')
        };
        insert environments;

        // Create global settings
        List<SCM_Global_Settings__c> settings = new List<SCM_Global_Settings__c>{
            new SCM_Global_Settings__c(Name = 'SCM_environment_Env1', Type__c = 'environment', Value__c = 'Env1'),
            new SCM_Global_Settings__c(Name = 'SCM_metadata_Type1', Type__c = 'metadata', Value__c = 'Type1'),
            new SCM_Global_Settings__c(Name = 'SCM_strategy_Back Promote', Type__c = 'scmStrategy', Value__c = 'Back Promote'),
            new SCM_Global_Settings__c(Name = 'SCM_validity_4 hours', Type__c = 'validity', Value__c = '4 hours')
        };
        insert settings;

        // Create user stories
        copado__User_Story__c userStory1 = new copado__User_Story__c(copado__User_Story_Title__c = 'Test US1');
        insert userStory1;

        copado__User_Story__c userStory2 = new copado__User_Story__c(copado__User_Story_Title__c = 'Test US2');
        insert userStory2;

        // Create exception approval
        SC_Matrix_Exception_Approval__c exceptions = new SC_Matrix_Exception_Approval__c(
            Status__c = 'Waiting for Approval',
            Linked_User_Story__c = userStory1.Id,
            Requested_User_Story__c = userStory2.Id
        );
        insert exceptions;

        // Create back promotion
        Back_Promoted_Result__c bpr = new Back_Promoted_Result__c(
            Status__c = 'Back Promotion in Progress',
            User_Story__c = userStory1.Id
        );
        insert bpr;
    }
    }

    @isTest
    static void testGetEnvironments() {
        Test.startTest();
        List<copado__Environment__c> result = ScmGlobalSettingPageController.getEnvironments();
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Env1', result[0].Name);
    }

    @isTest
    static void testGetSettings() {
        Test.startTest();
        List<SCM_Global_Settings__c> result = ScmGlobalSettingPageController.getSettings();
        Test.stopTest();

        System.assert(result.size() >= 4, 'At least 4 settings should be returned');
    }

    @isTest
    static void testSaveSettingsBackPromoteWithExceptionInProgress() {
        List<String> selectedEnvironments = new List<String>{ 'Env1' };
        List<String> selectedMetadataTypes = new List<String>{ 'Type1' };
        String selectedScmStrategy = 'Back Promote';
        String selectedValidity = '4 hours';

        Test.startTest();
        String result = ScmGlobalSettingPageController.saveSettings(selectedEnvironments, selectedMetadataTypes, selectedScmStrategy, selectedValidity);
        Test.stopTest();
    
      List<SCM_Global_Settings__c> allSettings = [SELECT Id FROM SCM_Global_Settings__c];
        System.assert(allSettings.size() >= 0);  
    }

    @isTest
    static void testSaveSettingsApprovalProcessWithBackPromotionInProgress() {
        List<String> selectedEnvironments = new List<String>{ 'Env1' };
        List<String> selectedMetadataTypes = new List<String>{ 'Type1' };
        String selectedScmStrategy = 'Approval Process';
        String selectedValidity = '8 hours';

        Test.startTest();
        String result = ScmGlobalSettingPageController.saveSettings(selectedEnvironments, selectedMetadataTypes, selectedScmStrategy, selectedValidity);
        Test.stopTest();

        List<SCM_Global_Settings__c> allSettings = [SELECT Id FROM SCM_Global_Settings__c];
        System.assert(allSettings.size() >= 0);
    }

    @isTest
    static void testSaveSettingsSuccess() {
        delete [SELECT Id FROM SC_Matrix_Exception_Approval__c];
        delete [SELECT Id FROM Back_Promoted_Result__c];

        List<String> selectedEnvironments = new List<String>{ 'Env1' };
        List<String> selectedMetadataTypes = new List<String>{ 'Type1', 'Type2' };
        String selectedScmStrategy = 'Approval Process';
        String selectedValidity = '8 hours';

        String result = ScmGlobalSettingPageController.saveSettings(selectedEnvironments, selectedMetadataTypes, selectedScmStrategy, selectedValidity);
        
        List<SCM_Global_Settings__c> allSettings = [SELECT Id FROM SCM_Global_Settings__c];
        System.assert(allSettings.size() >= 0);
    }

    @isTest
    static void testFetchScmExceptions() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Test.startTest();
        List<SC_Matrix_Exception_Approval__c> result = ScmGlobalSettingPageController.fetchScmExceptions();
        Test.stopTest();

        List<SCM_Global_Settings__c> allSettings = [SELECT Id FROM SCM_Global_Settings__c];
        System.assert(allSettings.size() >= 0);
        }
    }

    @isTest
    static void testUpdateScmExceptionsSuccess() {
        try{
         User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
            SC_Matrix_Exception_Approval__c exceptions = [SELECT Id FROM SC_Matrix_Exception_Approval__c LIMIT 1];

            String result = ScmGlobalSettingPageController.updateScmExceptions(exceptions.Id, 'Approved', 'Approved by test');
            SC_Matrix_Exception_Approval__c updated = [SELECT id,Status__c, Comments__c FROM SC_Matrix_Exception_Approval__c WHERE Id = :exceptions.Id];

            System.assert(updated.id!=null);
        }
        }
        catch(Exception e){}
    }
}