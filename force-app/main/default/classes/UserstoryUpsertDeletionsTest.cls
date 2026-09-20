/**
* @description Test class for UserstoryUpsertDeletions handler Validates the logic that prevents User Stories from being promoted
* when both Git MetaData and Delete MetaData files are present.
*/
@IsTest
private class UserstoryUpsertDeletionsTest {   
    // Constants matching the handler class
    private static final String DELETE_METADATA_FILE = 'Delete MetaData';
    private static final String GIT_METADATA_FILE = 'Git MetaData';
    private static final String VALIDATION_ERROR_MESSAGE = '"Git Upserts" and "Git Deletion" cannot be selected together in the same User Story';   
    /* @description Test setup method to create common test data */
    @TestSetup
    static void setupTestData() {
        // Create test User Stories
        List<copado__User_Story__c> userStories = new List<copado__User_Story__c>();        
        for (Integer i = 0; i < 10; i++) {
            userStories.add(new copado__User_Story__c(copado__User_Story_Title__c = 'Test User Story ' + i,
                                                      copado__Promote_Change__c = false,copado__Promote_and_Deploy__c = false));
        }       
        insert userStories;
    }
    
    /* @description Test validation fails when both Git MetaData and Delete MetaData attachments are present (classic Attachments) */
    @IsTest
    static void testBothAttachmentsPresent_ShouldFail() {
        // Given: User Story with both Git MetaData and Delete MetaData attachments
        copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__c LIMIT 1];       
        // Create both attachments
        List<Attachment> attachments = new List<Attachment>();       
        attachments.add(new Attachment(ParentId = userStory.Id, Name = GIT_METADATA_FILE,
                                       Body = Blob.valueOf('{"ApexClass": ["TestClass1", "TestClass2"]}'),ContentType = 'application/json'));       
        attachments.add(new Attachment(ParentId = userStory.Id, Name = DELETE_METADATA_FILE, 
                                       Body = Blob.valueOf('{"ApexClass": ["OldClass1", "OldClass2"]}'), ContentType ='application/json'));       
        insert attachments;        
        // When: Promote Change checkbox is enabled
        Test.startTest();
        userStory.copado__Promote_Change__c = true;
        Database.SaveResult result = Database.update(userStory, false);
        Test.stopTest();        
        // Then: Validation error should be thrown
        System.assertEquals(false, result.isSuccess(), 'Update should fail when both files are present');
        System.assert(result.getErrors()[0].getMessage().contains(VALIDATION_ERROR_MESSAGE), 'Error message should match expected validation message');
    }
    /* @description Test validation pass only Git Delete MetaData attachment */
    @IsTest
    static void testOnlyDeleteMetadataFile_ShouldPass() {
        // Given: User Story with only Delete MetaData file
        copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__c LIMIT 1];       
        ContentVersion deleteCV = new ContentVersion(Title = DELETE_METADATA_FILE, PathOnClient = DELETE_METADATA_FILE + '.json',
                                                     VersionData = Blob.valueOf('{"ApexClass": ["OldClass1", "OldClass2"]}'), IsMajorVersion = true);
        insert deleteCV;
        
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :deleteCV.Id];       
        ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = userStory.Id, ContentDocumentId = insertedCV.ContentDocumentId,
                                                           ShareType = 'V', Visibility = 'AllUsers');
        insert link;        
        // When: Promote Change checkbox is enabled
        Test.startTest();
        userStory.copado__Promote_Change__c = true;
        update userStory;      
        Test.stopTest();     
        // Then: Update should succeed
        copado__User_Story__c updatedUS = [SELECT copado__Promote_Change__c FROM copado__User_Story__c WHERE Id = :userStory.Id];
        System.assertEquals(true, updatedUS.copado__Promote_Change__c, 
                            'Promote Change should be enabled');
    }
    /* @description Test no validation when Promote Change was already enabled */
    @IsTest
    static void testPromoteChangeAlreadyEnabled_ShouldSkipValidation() {
        // Given: User Story with Promote Change already enabled
        copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__c LIMIT 1];
        userStory.copado__Promote_Change__c = true;
        update userStory;
        
        // Add both files
        List<Attachment> attachments = new List<Attachment>();
        attachments.add(new Attachment(ParentId = userStory.Id, Name = GIT_METADATA_FILE, Body = Blob.valueOf('{"ApexClass": ["TestClass1"]}'),
                                       ContentType = 'application/json'));
        attachments.add(new Attachment(ParentId = userStory.Id, Name = DELETE_METADATA_FILE, Body = Blob.valueOf('{"ApexClass": ["OldClass1"]}'),
                                       ContentType = 'application/json'));
        insert attachments;      
        // When: Updating another field (not changing Promote Change from false to true)
        Test.startTest(); 
        userStory.copado__User_Story_Title__c = 'Updated Title';
        update userStory;     
        Test.stopTest(); 
        // Then: Update should succeed (validation is skipped)
        copado__User_Story__c updatedUS = [SELECT copado__User_Story_Title__c FROM copado__User_Story__c WHERE Id = :userStory.Id];
        System.assertEquals('Updated Title', updatedUS.copado__User_Story_Title__c, 'Title should be updated');
    }
}