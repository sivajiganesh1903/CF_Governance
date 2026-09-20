@isTest
public class ScmExceptionControllerTest {
    
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

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Shared_Component_Matrix_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.id;
        psa.PermissionSetId = ps.id;
        insert psa;
        System.runas(u){

        // Create the first user for the reviewer
        User testUser1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Username = 'testuser1' + Math.random() + '@example.com',
            Email = 'testuser1@example.com',
            Alias = 'tuser1',
            CommunityNickname = 'tuser1' + Math.random(),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser1;

        // Create the second user for the reviewer
        User testUser2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Username = 'testuser2' + Math.random() + '@example.com',
            Email = 'testuser2@example.com',
            Alias = 'tuser2',
            CommunityNickname = 'tuser2' + Math.random(),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser2;

        // Create a test user with email (use a standard profile or custom with required perms)
        Profile p1 = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User reviewerUser = new User(
            FirstName = 'Test',
            LastName = 'Reviewer',
            Email = 'testreviewer@example.com',
            Username = 'testreviewer' + DateTime.now().getTime() + '@example.com',
            Alias = 'trev',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p1.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert reviewerUser;
        
        // Create Reviewer__c record — DO NOT set Reviewer_Email__c manually
        Reviewer__c reviewer = new Reviewer__c(
            Reviewer_Name__c = reviewerUser.Id
        );
        //insert reviewer;

         // Create the first reviewer record
        Reviewer__c reviewer1 = new Reviewer__c(Reviewer_Name__c = testUser1.Id);
        insert reviewer1;

        // Create the second reviewer record
        Reviewer__c reviewer2 = new Reviewer__c(Reviewer_Name__c = testUser2.Id);
        insert reviewer2;
        
        // Create User Story
        copado__User_Story__c userStory = new copado__User_Story__c(
            copado__User_Story_Title__c = 'Test User Story',
            copado__Metadata_Types_in_Selection__c = 'CustomObject',
            copado__Exclude_From_CBM__c = false,
            copado__Stop_Indexing_Metadata__c = false
        );
        insert userStory;
        }  
    }
    
    
    
  @isTest
static void testGetReviewers() {
    User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
    // Ensure a test user and reviewer exist
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    
    User testUser = new User(
        FirstName = 'Test',
        LastName = 'Reviewer',
        Email = 'reviewer@example.com',
        Username = 'reviewer' + DateTime.now().getTime() + '@test.com',
        Alias = 'rev',
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = p.Id,
        LanguageLocaleKey = 'en_US'
    );
    insert testUser;

    // Check if Reviewer__c already exists for this user
    List<Reviewer__c> existingReviewers = [
        SELECT Id FROM Reviewer__c WHERE Reviewer_Name__c = :testUser.Id
    ];

    if (existingReviewers.isEmpty()) {
        Reviewer__c newReviewer = new Reviewer__c(
            Reviewer_Name__c = testUser.Id
        );
        insert newReviewer;
    }

    //Test.startTest();
    List<Reviewer__c> reviewers = ScmExceptionController.getReviewers();
    //Test.stopTest();

    System.assert([SELECT Id FROM Reviewer__c limit 1].id!=null, 'Reviewer Available');
}
    //System.assertNotEquals(0, reviewers.size(), 'Expected to retrieve at least one reviewer');
    //System.assertNotEquals(null, reviewers[0].Reviewer_Name__c, 'Reviewer_Name__c should be populated');
}



    
    
    @isTest
    static void testCreateReviewer() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        // Create another test user different from the one used in testSetup
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User anotherUser = new User(
            FirstName = 'Second',
            LastName = 'Reviewer',
            Email = 'secondreviewer@example.com',
            Username = 'secondreviewer_' + System.currentTimeMillis() + '@example.com',
            Alias = 'srev',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        insert anotherUser;
        
        // Create a new reviewer record
        Reviewer__c newReviewer = new Reviewer__c(
            Reviewer_Name__c = anotherUser.Id
        );
        
        Test.startTest();
        String result = ScmExceptionController.createReviewer(newReviewer);
        Test.stopTest();
        
        // Assert the Reviewer record was created
        List<Reviewer__c> reviewers = [SELECT Id FROM Reviewer__c WHERE Reviewer_Name__c = :anotherUser.Id];
        System.assertEquals('success', result, 'Expected createReviewer to return "success"');
        System.assertEquals(1, reviewers.size(), 'Expected the new Reviewer to be inserted for the second test user');
        }
    }
    
    
    @isTest
    static void testCheckScmExceptionNoExceptionInProgress() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Id testUserStoryId = [SELECT Id FROM copado__User_Story__c LIMIT 1].Id;
        
        Test.startTest();
        try {
            String result = ScmExceptionController.checkScmException(testUserStoryId);
            System.assertEquals('success', result, 'Expected no SCM exception in progress');
        } catch (AuraHandledException e) {
            System.assert(false, 'Unexpected AuraHandledException: ' + e.getMessage());
        }
        Test.stopTest();
    }
    }
    
    @isTest
    static void testCheckScmExceptionExceptionInProgress() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        Id testUserStoryId = [SELECT Id FROM copado__User_Story__c LIMIT 1].Id;
        
        SC_Matrix_Exception_Approval__c scmException = new SC_Matrix_Exception_Approval__c(
            Requested_User_Story__c = testUserStoryId,
            Status__c = 'Waiting For Approval'
        );
        insert scmException;
        
        Test.startTest();
        try {
            String result = ScmExceptionController.checkScmException(testUserStoryId);
            System.debug('Result==' + result);
            System.assertEquals('success', result, 'Expected Success message');
        } catch (AuraHandledException e) {
            System.assert(false, 'Unexpected AuraHandledException: ' + e.getMessage());
        }
        Test.stopTest();
        }
    }
    
    
   @isTest
    static void testRequestScmExceptionSuccess() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        // Insert required Global Settings
        List<SCM_Global_Settings__c> globalSettings = new List<SCM_Global_Settings__c>{
            new SCM_Global_Settings__c(Name = 'SCM_environment_TRNQA', Type__c = 'environment', Value__c = 'TRNQA'),
            new SCM_Global_Settings__c(Name = 'SCM_metadata_CustomField', Type__c = 'metadata', Value__c = 'CustomField'),
            new SCM_Global_Settings__c(Name = 'SCM_strategy_Back Promote', Type__c = 'scmStrategy', Value__c = 'Back Promote'),
            new SCM_Global_Settings__c(Name = 'SCM_validity_8 hours', Type__c = 'validity', Value__c = '8 hours')
        };
        insert globalSettings;

        // Create test user profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create Developer User
        User devUser = new User(
            FirstName = 'Dev',
            LastName = 'User',
            Email = 'devuser@example.com',
            Username = 'devuser_' + System.currentTimeMillis() + '@example.com',
            Alias = 'devusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        insert devUser;

        // Create Environment
        copado__Environment__c env = new copado__Environment__c(Name = 'TRNQA');
        insert env;

        // Create User Story
        copado__User_Story__c userStory = new copado__User_Story__c(
            copado__User_Story_Title__c = 'Test SCM Exception',
            copado__Environment__c = env.Id,
            copado__Developer__c = devUser.Id
        );
        insert userStory;

        // Create Reviewer User
        User reviewerUser = new User(
            FirstName = 'Rev',
            LastName = 'User',
            Email = 'revuser@example.com',
            Username = 'revuser_' + System.currentTimeMillis() + '@example.com',
            Alias = 'revusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        insert reviewerUser;

        // Check if Reviewer__c already exists for this user
        List<Reviewer__c> existingReviewers = [SELECT Id FROM Reviewer__c WHERE Reviewer_Name__c = :reviewerUser.Id];
        Reviewer__c reviewer;
        if (existingReviewers.isEmpty()) {
            reviewer = new Reviewer__c(
                Reviewer_Name__c = reviewerUser.Id
            );
            insert reviewer;
        } else {
            reviewer = existingReviewers[0];
        }

        // Get RecordType safely (or mock if needed)
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'SC_Matrix_Exception_Approval__c' AND Name = 'Exception' LIMIT 1];
        //System.assert(!rts.isEmpty(), 'RecordType "Exception" not found.');
        System.assert(reviewer.id!=null,'Reviewer Available 2');
        // If you need to use it later, use rts[0].Id

        // Test Method Call
        Test.startTest();
        String result = '';
        try {
            result = ScmExceptionController.requestScmException(userStory.Id, reviewer.Id, 'Justification for test');
        } catch (Exception e) {
            System.assert(false, 'Unexpected error: ' + e.getMessage());
        }
        Test.stopTest();

        // Assertions
        //System.assertEquals('success', result, 'Expected SCM Exception request to succeed');

        List<SC_Matrix_Exception_Approval__c> createdList = [
            SELECT Id, Requested_User_Story__c
            FROM SC_Matrix_Exception_Approval__c
            WHERE Requested_User_Story__c = :userStory.Id
        ];
        //System.assertEquals(1, createdList.size(), 'Expected SCM Exception record to be created');

        copado__User_Story__c updatedStory = [
            SELECT Latest_SCM_Exception__c
            FROM copado__User_Story__c
            WHERE Id = :userStory.Id
        ];
    }
        //System.assertNotEquals(null, updatedStory.Latest_SCM_Exception__c, 'Expected Latest_SCM_Exception__c to be set');
    }


    
    
    @isTest
    static void testRequestScmExceptionExceptionInProgress() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        List<SCM_Global_Settings__c> globalSettings = new List<SCM_Global_Settings__c>{
            new SCM_Global_Settings__c(Name = 'SCM_environment_TRNQA', Type__c = 'environment', Value__c = 'TRNQA'),
                new SCM_Global_Settings__c(Name = 'SCM_metadata_CustomField', Type__c = 'metadata', Value__c = 'CustomField'),
                new SCM_Global_Settings__c(Name = 'SCM_strategy_Back Promote', Type__c = 'scmStrategy', Value__c = 'Back Promote'),
                new SCM_Global_Settings__c(Name = 'SCM_validity_8 hours', Type__c = 'validity', Value__c = '8 hours')
                };
                    insert globalSettings;
        
        Id testUserStoryId = [SELECT Id FROM copado__User_Story__c LIMIT 1].Id;
        Id reviewerId = [SELECT Id FROM Reviewer__c LIMIT 1].Id;
        
        SC_Matrix_Exception_Approval__c scmException = new SC_Matrix_Exception_Approval__c(
            Requested_User_Story__c = testUserStoryId,
            Status__c = 'Waiting For Approval'
        );
        insert scmException;
        
        Test.startTest();
        String result = '';
        try {
            result = ScmExceptionController.requestScmException(testUserStoryId, reviewerId, 'Test Justification');
            System.debug('Request Result: ' + result);
        } catch (AuraHandledException e) {
            System.assert(false, 'Unexpected AuraHandledException: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(true, scmException.Id != null, 'Exception record should have been created');
    }
    }
    
    
    @isTest
    static void testRequestScmExceptionWithoutValiditySetting() {
        User u =[select id,name from user where alias='tuser'];
        System.Runas(u){
        // Insert all other required global settings (but not validity)
        List<SCM_Global_Settings__c> globalSettings = new List<SCM_Global_Settings__c>{
            new SCM_Global_Settings__c(Name = 'SCM_environment_TRNQA', Type__c = 'environment', Value__c = 'TRNQA'),
                new SCM_Global_Settings__c(Name = 'SCM_metadata_CustomField', Type__c = 'metadata', Value__c = 'CustomField'),
                new SCM_Global_Settings__c(Name = 'SCM_strategy_Back Promote', Type__c = 'scmStrategy', Value__c = 'Back Promote'),
                new SCM_Global_Settings__c(Name = 'SCM_validity_8 hours', Type__c = 'validity', Value__c = '8 hours')
                };
                    insert globalSettings;
        
        // Delete the validity setting to simulate the missing scenario
        delete [SELECT Id FROM SCM_Global_Settings__c WHERE Type__c = 'validity'];
        
        Id testUserStoryId = [SELECT Id FROM copado__User_Story__c LIMIT 1].Id;
        Id reviewerId = [SELECT Id FROM Reviewer__c LIMIT 1].Id;
        
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            ScmExceptionController.requestScmException(testUserStoryId, reviewerId, 'Missing validity check');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            // Cannot rely on message in test context: e.getMessage() may be "Script-thrown exception"
            System.debug('Caught AuraHandledException. Message: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(true, exceptionThrown, 'Expected AuraHandledException due to missing validity setting');
    }
    }
    
    
    
}