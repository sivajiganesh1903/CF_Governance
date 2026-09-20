@isTest
public class ReviewerTriggerHandlerTest {

    @isTest
    static void testPreventDuplicateReviewer() {
        // Create a user for the reviewer
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testuser' + Math.random() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            CommunityNickname = 'tuser' + Math.random(),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

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
        System.runAs(u){
        // Create the first reviewer record
        Reviewer__c reviewer1 = new Reviewer__c(Reviewer_Name__c = testUser.Id);
        insert reviewer1;

        // Attempt to create a duplicate reviewer record
        Reviewer__c reviewer2 = new Reviewer__c(Reviewer_Name__c = testUser.Id);

        Test.startTest();
        try {
            insert reviewer2;
            System.assert(false, 'Expected DMLException was not thrown.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A reviewer with this user already exists.'));
        }
        Test.stopTest();
    } 
    }

    @isTest
    static void testUpdateReviewerWithDuplicate() {
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
        System.runAs(u){

        // Create the first reviewer record
        Reviewer__c reviewer1 = new Reviewer__c(Reviewer_Name__c = testUser1.Id);
        insert reviewer1;

        // Create the second reviewer record
        Reviewer__c reviewer2 = new Reviewer__c(Reviewer_Name__c = testUser2.Id);
        insert reviewer2;

        // Attempt to update the second reviewer to a duplicate reviewer
        reviewer2.Reviewer_Name__c = testUser1.Id;

        Test.startTest();
        try {
            update reviewer2;
            System.assert(false, 'Expected DMLException was not thrown.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A reviewer with this user already exists.'));
        }
        Test.stopTest();
    }
    }
}