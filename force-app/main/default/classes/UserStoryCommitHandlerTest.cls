@isTest
public class UserStoryCommitHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data
        copado__User_Story__c userStory = new copado__User_Story__c(copado__User_Story_Title__c = 'US-0005654Commit');
        insert userStory;
        
        copado__Org__c org = new copado__Org__c(Name = 'SampleOrg');
        insert org;
        
        copado__Git_Org_Commit__c snapshotCommit = new copado__Git_Org_Commit__c(
            copado__Commit_Message__c = 'Test Commit Message',
            copado__Org__c = org.Id
        );
        insert snapshotCommit;
    }
    
    @isTest
static void testHandlerWithCustomLabels() {
    // Get the test data
    copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__c LIMIT 1];
    copado__Git_Org_Commit__c snapshotCommit = [SELECT Id, copado__Org__c FROM copado__Git_Org_Commit__c LIMIT 1];
    
    // Create an attachment with CustomLabels
    Attachment att = new Attachment(
        Name = 'MetaData',
        Body = Blob.valueOf('[{"n": "CustomMath"}, {"t": "CustomLabels", "n": "OtherType"}]'),
        ParentId = snapshotCommit.Id
    );
    insert att;
    
    Test.startTest();
    
    // Create a new User Story Commit
    copado__User_Story_Commit__c userStoryCommit = new copado__User_Story_Commit__c(
        copado__User_Story__c = userStory.Id,
        copado__Snapshot_Commit__c = snapshotCommit.Id
    );
    insert userStoryCommit; // This will trigger the UserStoryCommitTrigger
    
    Test.stopTest();
    
    // Verify that the handler method processed the attachment as expected
    List<Attachment> newAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :snapshotCommit.Id AND Name = 'MetaData'];
    
    System.assertEquals(1, newAttachments.size(), 'There should be one processed MetaData attachment');
    String content = newAttachments[0].Body.toString();
    System.assert(!content.contains('"t": "CustomLabels"'), 'CustomLabels should be removed from the attachment');
}
    
    @isTest
    static void testHandlerWithoutCustomLabels() {
        // Get the test data
        copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__c LIMIT 1];
        copado__Git_Org_Commit__c snapshotCommit = [SELECT Id, copado__Org__c FROM copado__Git_Org_Commit__c LIMIT 1];
        
        // Create an attachment without CustomLabels
        Attachment att = new Attachment(
            Name = 'MetaData',
            Body = Blob.valueOf('[{"n": "CustomMath"}, {"t": "ApexClass", "n": "OtherType"}]'),
            ParentId = snapshotCommit.Id
        );
        insert att;
        
        Test.startTest();
        
        // Create a new User Story Commit
        copado__User_Story_Commit__c userStoryCommit = new copado__User_Story_Commit__c(
            copado__User_Story__c = userStory.Id,
            copado__Snapshot_Commit__c = snapshotCommit.Id
        );
        insert userStoryCommit;
        
        // Explicitly call the handler method
        UserStoryCommitHandler.getSnapshotFilesAndAttachments(new List<copado__User_Story_Commit__c>{userStoryCommit});
        
        Test.stopTest();
        
        // Verify that the handler method did not modify the attachment
        List<Attachment> attachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :snapshotCommit.Id AND Name = 'MetaData'];
        System.assertEquals(1, attachments.size(), 'The original attachment should remain unchanged');
        String content = attachments[0].Body.toString();
        System.assert(content.contains('"t": "ApexClass"'), 'The attachment content should remain unchanged');
    }
    
    @isTest
    static void testHandlerWithMultipleCommits() {
        // Get the test data
        copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__c LIMIT 1];
        copado__Git_Org_Commit__c snapshotCommit1 = [SELECT Id, copado__Org__c FROM copado__Git_Org_Commit__c LIMIT 1];
        
        // Create a second snapshot commit
        copado__Git_Org_Commit__c snapshotCommit2 = new copado__Git_Org_Commit__c(
            copado__Commit_Message__c = 'Test Commit Message 2',
            copado__Org__c = snapshotCommit1.copado__Org__c
        );
        insert snapshotCommit2;
        
        // Create attachments for both commits
        Attachment att1 = new Attachment(
            Name = 'MetaData',
            Body = Blob.valueOf('[{"n": "CustomMath"}, {"t": "CustomLabels", "n": "OtherType"}]'),
            ParentId = snapshotCommit1.Id
        );
        insert att1;
        
        Attachment att2 = new Attachment(
            Name = 'MetaData',
            Body = Blob.valueOf('[{"n": "AnotherClass"}, {"t": "CustomLabels", "n": "AnotherLabel"}]'),
            ParentId = snapshotCommit2.Id
        );
        insert att2;
        
        Test.startTest();
        
        // Create User Story Commits for both snapshot commits
        copado__User_Story_Commit__c userStoryCommit1 = new copado__User_Story_Commit__c(
            copado__User_Story__c = userStory.Id,
            copado__Snapshot_Commit__c = snapshotCommit1.Id
        );
        copado__User_Story_Commit__c userStoryCommit2 = new copado__User_Story_Commit__c(
            copado__User_Story__c = userStory.Id,
            copado__Snapshot_Commit__c = snapshotCommit2.Id
        );
        insert new List<copado__User_Story_Commit__c>{userStoryCommit1, userStoryCommit2};
        
        // Explicitly call the handler method
        UserStoryCommitHandler.getSnapshotFilesAndAttachments(new List<copado__User_Story_Commit__c>{userStoryCommit1, userStoryCommit2});
        
        Test.stopTest();
        
        // Verify that both attachments were processed
        List<Attachment> newAttachments = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId IN (:snapshotCommit1.Id, :snapshotCommit2.Id) AND Name = 'MetaData'];
        System.assertEquals(2, newAttachments.size(), 'There should be two processed MetaData attachments');
        
        for (Attachment att : newAttachments) {
            String content = att.Body.toString();
            System.assert(!content.contains('"t": "CustomLabels"'), 'CustomLabels should be removed from both attachments');
        }
    }
    
    @isTest
    static void testHandlerWithNoAttachments() {
        // Get the test data
        copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__c LIMIT 1];
        copado__Git_Org_Commit__c snapshotCommit = [SELECT Id, copado__Org__c FROM copado__Git_Org_Commit__c LIMIT 1];
        
        Test.startTest();
        
        // Create a new User Story Commit
        copado__User_Story_Commit__c userStoryCommit = new copado__User_Story_Commit__c(
            copado__User_Story__c = userStory.Id,
            copado__Snapshot_Commit__c = snapshotCommit.Id
        );
        insert userStoryCommit;
        
        // Explicitly call the handler method
        UserStoryCommitHandler.getSnapshotFilesAndAttachments(new List<copado__User_Story_Commit__c>{userStoryCommit});
        
        Test.stopTest();
        
        // Verify that no attachments were created
        List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :snapshotCommit.Id];
        System.assertEquals(0, attachments.size(), 'No attachments should be created when none existed initially');
    }
}