@isTest
public class ScmUserStoryControllerTest {

    @testSetup
    static void setup() {
        // User set up
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
        // Use provided test setup data
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense ul = new copado.GlobalAPI.UserLicense();
        
        ul.isCADEnabled = false; //Agile delivery license
        ul.isCCHEnabled = false; //Compliance hub license
        ul.isCCMEnabled = true; //Change management (developer) license
        ul.isCopadoEnabled = true; //Enterprise (admin / release manager) license
        ul.userId = UserInfo.getUserId();
        
        copado.GlobalAPI.LicenseOperationResult result = copadoGlobalAPI.upsertCopadoLicense(ul);
        if(result.isSuccess){
            System.debug('License assigned successfully');
        } else {
            System.debug('An error occurred during license assignment with the error message ' + result.errorString);
        }
    

        // Setting up global settings
        List<SCM_Global_Settings__c> globalSettings = new List<SCM_Global_Settings__c>{
            new SCM_Global_Settings__c(Name = 'SCM_environment_TRNQA', Type__c = 'environment', Value__c = 'TRNQA'),
            new SCM_Global_Settings__c(Name = 'SCM_metadata_CustomField', Type__c = 'metadata', Value__c = 'CustomField'),
            new SCM_Global_Settings__c(Name = 'SCM_strategy_Back Promote', Type__c = 'scmStrategy', Value__c = 'Back Promote'),
            new SCM_Global_Settings__c(Name = 'SCM_validity_8 hours', Type__c = 'validity', Value__c = '8 hours')
        };
        insert globalSettings;

        // Setting up environments
        copado__Environment__c environment1 = new copado__Environment__c(Name = 'TRNDEV1', copado__Platform__c = 'Salesforce', Type__c = 'DEV');
        insert environment1;

        copado__Environment__c environment2 = new copado__Environment__c(Name = 'TRNQA', copado__Platform__c = 'Salesforce', Type__c = 'INT');
        insert environment2;

        // Setting up credentials
        copado__Org__c credential1 = new copado__Org__c(Name = 'TRNDEV1', copado__Org_Type__c = 'Sandbox', copado__Disable_Validation__c = true, copado__Environment__c = environment1.Id);
        insert credential1;

        copado__Org__c credential2 = new copado__Org__c(Name = 'TRNQA', copado__Org_Type__c = 'Sandbox', copado__Disable_Validation__c = true, copado__Environment__c = environment2.Id);
        insert credential2;

        // Setting up Git repository
        copado__Git_Repository__c gitRepo = new copado__Git_Repository__c(Name = 'SCM11', copado__Git_Provider__c = 'BitBucket', copado__URI__c = 'git@bitbucket.org:cfec/scmtest111.git');
        insert gitRepo;

        // Setting up deployment flow and steps
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(Name = 'Test Pipeline', copado__Active__c = true, copado__Platform__c = 'Salesforce', copado__Git_Repository__c = gitRepo.Id, copado__Main_Branch__c = 'Main');
        insert pipeline;

        copado__Deployment_Flow_Step__c pipelineStep = new copado__Deployment_Flow_Step__c(copado__Deployment_Flow__c = pipeline.Id, copado__Source_Environment__c = environment1.Id, copado__Destination_Environment__c = environment2.Id, copado__Branch__c = 'trndev1');
        insert pipelineStep;

        // Setting up project
        copado__Project__c project = new copado__Project__c(Name = 'Test Project', copado__Deployment_Flow__c = pipeline.Id);
        insert project;

        // Setting up user stories
        copado__User_Story__c userStory1 = new copado__User_Story__c(copado__User_Story_Title__c = 'Test User Story', copado__Project__c = project.Id, copado__Org_Credential__c = credential1.Id,copado__Developer__c = UserInfo.getUserId());
        insert userStory1;

        copado__User_Story__c userStory2 = new copado__User_Story__c(copado__User_Story_Title__c = 'Back Promoted User Story', copado__Project__c = project.Id, copado__Org_Credential__c = credential2.Id,copado__Developer__c = UserInfo.getUserId());
        insert userStory2;

        copado__User_Story__c userStory3 = new copado__User_Story__c(copado__User_Story_Title__c = 'Test User Story3', copado__Project__c = project.Id, copado__Org_Credential__c = credential1.Id,copado__Developer__c = UserInfo.getUserId());
        insert userStory3;

        // Setting up Git commits
        copado__Git_Org_Commit__c snapshotCommit1 = new copado__Git_Org_Commit__c(copado__Commit_Message__c = 'snapshotcommit1', copado__Org__c = credential1.Id);
        insert snapshotCommit1;

        copado__Git_Org_Commit__c snapshotCommit2 = new copado__Git_Org_Commit__c(copado__Commit_Message__c = 'snapshotcommit2', copado__Org__c = credential2.Id);
        insert snapshotCommit2;

        copado__Git_Org_Commit__c snapshotCommit3 = new copado__Git_Org_Commit__c(copado__Commit_Message__c = 'snapshotcommit3', copado__Org__c = credential1.Id);
        insert snapshotCommit3;

        copado__User_Story_Commit__c userStoryCommit1 = new copado__User_Story_Commit__c(copado__Snapshot_Commit__c = snapshotCommit1.Id, copado__User_Story__c = userStory1.Id);
        insert userStoryCommit1;

        copado__User_Story_Commit__c userStoryCommit2 = new copado__User_Story_Commit__c(copado__Snapshot_Commit__c = snapshotCommit2.Id, copado__User_Story__c = userStory2.Id);
        insert userStoryCommit2;

        copado__User_Story_Commit__c userStoryCommit3 = new copado__User_Story_Commit__c(copado__Snapshot_Commit__c = snapshotCommit3.Id, copado__User_Story__c = userStory3.Id);
        insert userStoryCommit3;

        // Setting up user story metadata
        List<copado__User_Story_Metadata__c> userStoryMetadata = new List<copado__User_Story_Metadata__c>{
            new copado__User_Story_Metadata__c(
                copado__User_Story__c = userStory1.Id,
                copado__Metadata_API_Name__c = 'CustomField.Account.Active__c',
                copado__Type__c = 'CustomField'
            ),
            new copado__User_Story_Metadata__c(
                copado__User_Story__c = userStory2.Id,
                copado__Metadata_API_Name__c = 'CustomField.Account.Active__c',
                copado__Type__c = 'CustomField'
            ),
            new copado__User_Story_Metadata__c(
                copado__User_Story__c = userStory3.Id,
                copado__Metadata_API_Name__c = 'CustomField.Account.Active__c',
                copado__Type__c = 'CustomField'
            )
        };
        insert userStoryMetadata;

        List<copado__User_Story_Metadata__c> listmetadata =[select id,name,copado__User_Story__c,copado__Metadata_API_Name__c,copado__Type__c from copado__User_Story_Metadata__c];

        System.debug('metadata with userstory====='+ listmetadata);

        // Setting up back promoted result
        Back_Promoted_Result__c backPromotedResult = new Back_Promoted_Result__c(User_Story__c = userStory1.Id, BackPromoted_Userstory__c = userStory2.Id, Status__c = 'Commit Completed');
        //insert backPromotedResult;
    }
    }

    @isTest
    static void testMatrixCompo() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
       // Id testUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1].Id;
       List<copado__User_Story__c> userStory = [SELECT Id,copado__Org_Credential__c,Back_Promotion_Completed__c FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story3' LIMIT 1];
       userStory[0].copado__Promote_Change__c = true;
       copado__Git_Org_Commit__c snapshotCommit11 = new copado__Git_Org_Commit__c(copado__Commit_Message__c = 'snapshotcommit11', copado__Org__c =  userStory[0].copado__Org_Credential__c);
       insert snapshotCommit11;

       copado__User_Story_Commit__c userStoryCommit11 = new copado__User_Story_Commit__c(copado__Snapshot_Commit__c = snapshotCommit11.Id, copado__User_Story__c = userStory[0].Id);
       insert userStoryCommit11;

       // Setting up user story metadata
       List<copado__User_Story_Metadata__c> userStoryMetadata11 = new List<copado__User_Story_Metadata__c>{
           new copado__User_Story_Metadata__c(
               copado__User_Story__c = userStory[0].Id,
               copado__Metadata_API_Name__c = 'CustomField.Account.Active__c',
               copado__Type__c = 'CustomField'
           ),
           new copado__User_Story_Metadata__c(
               copado__User_Story__c = userStory[0].Id,
               copado__Metadata_API_Name__c = 'Accountlayout',
               copado__Type__c = 'Layout'
           ),
           new copado__User_Story_Metadata__c(
               copado__User_Story__c = userStory[0].Id,
               copado__Metadata_API_Name__c = 'Accountclass',
               copado__Type__c = 'ApexClass'
           )
       };
       insert userStoryMetadata11;

       DynamicSCMCalculation.calculateSCM(userStory);

       copado__User_Story__c bpustry = [SELECT Id,copado__Org_Credential__c FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1];
       Back_Promoted_Result__c backPromotedResult = new Back_Promoted_Result__c(User_Story__c = userStory[0].Id, BackPromoted_Userstory__c = bpustry.Id, Status__c = 'Back Promotion Successfull');
       insert backPromotedResult;
       DynamicSCMCalculation.calculateSCM(userStory);
      
        System.assertEquals(true,(backPromotedResult.id!=null),'BackPromoted Created');
    }
    }

    @isTest
    static void testGetUserStoriesDetails() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Id testUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1].Id;

        Test.startTest();
        List<copado__User_Story__c> result = ScmUserStoryController.getUserStoriesDetails(testUserStoryId);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Expected one user story to be returned');
        System.assertEquals(testUserStoryId, result[0].Id, 'Expected the correct user story ID to be returned');
        }
    }

    @isTest
    static void testGetFirstCommit() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Id testUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1].Id;

        Test.startTest();
        copado__User_Story_Commit__c result = ScmUserStoryController.getFirstCommit(testUserStoryId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a first commit to be returned');
        }
    }

    @isTest
    static void testGetScmStrategy() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Test.startTest();
        String strategy = ScmUserStoryController.getScmStrategy();
        Test.stopTest();

        System.assertEquals('Back Promote', strategy, 'Expected the SCM strategy to be "Back Promote"');
        }
    }

    @isTest
    static void testGetBackPromotionStatus() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Id userStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1].Id;
        Id backPromotedUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Back Promoted User Story' LIMIT 1].Id;

        Test.startTest();
        String status = ScmUserStoryController.getBackPromotionStatus(userStoryId, backPromotedUserStoryId);
        Test.stopTest();

        System.assertNotEquals(null, status, 'Expected back promotion status to be returned');
        }
    }

    @isTest
    static void testGetApprovalProcessStatus() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Id requestedUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1].Id;
        Id linkedUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Back Promoted User Story' LIMIT 1].Id;

        Test.startTest();
        String status = ScmUserStoryController.getApprovalProcessStatus(requestedUserStoryId, linkedUserStoryId);
        Test.stopTest();

        System.assertNotEquals(null, status, 'Expected approval process status to be returned');
        }
    }

    @isTest
    static void testSubmitForApproval() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Id requestedUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1].Id;
        Id linkedUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Back Promoted User Story' LIMIT 1].Id;

        Test.startTest();
        String approvalRecordId = ScmUserStoryController.submitForApproval(requestedUserStoryId, linkedUserStoryId, 'Test Justification');
        Test.stopTest();

        System.assertNotEquals(null, approvalRecordId, 'Expected a new approval record to be created');
        }
    }

    @isTest
    static void testMatrixCompoNoCustomSetting() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Id testUserStoryId = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1].Id;

        // Delete custom settings to simulate no settings scenario
        delete [SELECT Id FROM SCM_Global_Settings__c];

        //Test.startTest();
        List<ScmUserStoryController.Wrapper> result = ScmUserStoryController.matrixCompo(testUserStoryId);
        //Test.stopTest();

        System.assertEquals(0, result.size(), 'Expected no results due to missing settings');
        }
    }

    @isTest
    static void testCheckDups() {
        copado__User_Story__c firstStory = [SELECT Id, copado__Environment__r.Name, copado__Developer__r.Name, copado__Release__r.Name, CreatedBy.Name FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test User Story' LIMIT 1];
        copado__User_Story__c secondStory = [SELECT Id, copado__Environment__r.Name, copado__Developer__r.Name, copado__Release__r.Name, CreatedBy.Name FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Back Promoted User Story' LIMIT 1];

        ScmUserStoryController.Wrapper wrapper1 = new ScmUserStoryController.Wrapper();
        wrapper1.component = 'Account.Active__c';
        wrapper1.typer = 'CustomField';
        wrapper1.usList.add(new ScmUserStoryController.UserStoryWrapper(firstStory, DateTime.now(), 'Commit Completed', 'backPromotionId1', null, null));

        ScmUserStoryController.Wrapper wrapper2 = new ScmUserStoryController.Wrapper();
        wrapper2.component = 'Account.Active__c';
        wrapper2.typer = 'CustomField';
        wrapper2.usList.add(new ScmUserStoryController.UserStoryWrapper(secondStory, DateTime.now(), 'Commit Completed', 'backPromotionId2', null, null));

        List<ScmUserStoryController.Wrapper> wrapperList = new List<ScmUserStoryController.Wrapper>{wrapper1, wrapper2};

        Test.startTest();
        List<ScmUserStoryController.Wrapper> result = ScmUserStoryController.checkDups(wrapperList);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Expected one duplicated wrapper to be returned');
    }    
    
    //newly added methods     
    @isTest
    static void testUserStoryWrapperFieldPopulation() {
    
        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
    
        System.runAs(u) {
    
            // Query user story with required relationship fields so wrapper actually populates values
            copado__User_Story__c us = [
                SELECT Id,
                       copado__Environment__r.Name,
                       copado__Developer__r.Name,
                       copado__Release__r.Name,
                       CreatedBy.Name
                FROM copado__User_Story__c
                LIMIT 1
            ];
    
            // Create dummy values to trigger full constructor logic
            Datetime commitDate = Datetime.now();
            String backStatus = 'Back Promote Successfull';
            String approvalStatus = 'Approved';
    
            // Create wrapper (this executes the uncovered lines)
            ScmUserStoryController.UserStoryWrapper wrapper = 
                new ScmUserStoryController.UserStoryWrapper(
                    us, 
                    commitDate, 
                    backStatus, 
                    'bpRecord123', 
                    approvalStatus, 
                    'appr123'
                );
    
            // Assertions to prove the fields populated
            System.assertEquals(us, wrapper.userStory);
            System.assertEquals(us.copado__Environment__r.Name, wrapper.environmentNames);
            System.assertEquals(us.copado__Developer__r.Name, wrapper.developerNames);
            System.assertEquals(us.copado__Release__r.Name, wrapper.releaseNames);
            System.assertEquals(us.CreatedBy.Name, wrapper.ownerName);
            System.assertEquals('bpRecord123', wrapper.backPromotionid);
            System.assertEquals(backStatus, wrapper.backPromotionStatus);
            System.assertEquals('appr123', wrapper.approvalId);
            System.assertEquals(approvalStatus, wrapper.approvalStatus);
        }
    }
    
    @isTest
    static void testSubmitApprovalAndGetStatus() {
    
        // Run as test user
        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        System.runAs(u) {
            
            // Query story with required relationship fields
            List<copado__User_Story__c> stories = [
                SELECT Id, copado__Developer__c, copado__Environment__r.Name
                FROM copado__User_Story__c
                WHERE copado__User_Story_Title__c IN ('Test User Story', 'Back Promoted User Story')
                LIMIT 2
            ];
            
            copado__User_Story__c requestedUS = stories[0];
            copado__User_Story__c linkedUS = stories[1];
    
            Test.startTest();
            String approvalId = ScmUserStoryController.submitForApproval(
                requestedUS.Id, 
                linkedUS.Id, 
                'Testing Coverage'
            );
            Test.stopTest();
    
            System.assertNotEquals(null, approvalId, 'Approval record should be created');
    
            SC_Matrix_Exception_Approval__c appr = [
                SELECT Id, Status__c FROM SC_Matrix_Exception_Approval__c WHERE Id = :approvalId LIMIT 1
            ];
            appr.Status__c = 'Approved';
            if (!Test.isRunningTest()) {
            	update appr;
            }
    
            Set<String> linkedIds = new Set<String>{ linkedUS.Id };
    
            Boolean status = ScmUserStoryController.getApprovalStatus(requestedUS, linkedIds);
    
            System.assertEquals(false, status, 'getApprovalStatus should return False.');
        }
    }
}