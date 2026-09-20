@isTest
public class ReleasePlaybookControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test data for Release_Playbook__c
        RecordType rtTemplate = [SELECT Id FROM RecordType WHERE Name = 'Release Playbook Template' AND SObjectType = 'Release_Playbook__c' LIMIT 1];
        RecordType rtItemTemplate = [SELECT Id FROM RecordType WHERE Name = 'Release Item Templates' AND SObjectType = 'Release_Playbook_Item__c' LIMIT 1];
        RecordType rtAssignment = [SELECT Id FROM RecordType WHERE Name = 'Template Release Assignments' AND SObjectType = 'Release_Assignment__c' LIMIT 1];
        RecordType rtReleasePlaybook = [SELECT Id FROM RecordType WHERE Name = 'Release Playbook' AND SObjectType = 'Release_Playbook__c' LIMIT 1];
        
        Release_Playbook__c playbookTemplate = new Release_Playbook__c(RecordTypeId = rtTemplate.Id, Status__c = 'In Progress');
        insert playbookTemplate;
        
        Release_Playbook__c releasePlaybook = new Release_Playbook__c(RecordTypeId = rtReleasePlaybook.Id, Status__c = 'In Progress');
        insert releasePlaybook;
        
        Release_Playbook_Item__c itemTemplate = new Release_Playbook_Item__c(RecordTypeId = rtItemTemplate.Id, 
                                                                             Release_Playbook__c = playbookTemplate.Id,
                                                                             Area__c = 'Testing', End_Date_Time__c = DateTime.now(),
                                                                             Environment__c = 'UAT',
                                                                             Execution_Sequence__c = 'Deployment',
                                                                             Issues_Comments__c = 'None',
                                                                             Order__c = 1, Stage__c = 'Deployment',
                                                                             Start_Date_Time__c = DateTime.now(),
                                                                             Status__c = 'In Progress',
                                                                             Task_Description__c = 'Test Task');
        insert itemTemplate;
        
        Release_Assignment__c assignmentTemplate = new Release_Assignment__c(RecordTypeId = rtAssignment.Id,
                                                                             Release_Playbook__c = playbookTemplate.Id,
                                                                             Company__c = 'Test Company', Contact__c = 'Test Contact',
                                                                             Email__c = 'test@example.com',Role__c = 'DevOps');
        insert assignmentTemplate;
    }
    
    @isTest
    static void testGetTemplateRecs() {
        Test.startTest();
        List<ReleasePlaybookController.ReleasePlaybookWrapper> result = ReleasePlaybookController.getTemplateRecs();
        Test.stopTest();
        
        // Check Assertion results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Result list should not be empty');
    }
    
    @isTest
    static void testCreateReleasePlaybookItems() {
        Id releasePlaybookId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook' LIMIT 1].Id;
        Id selectedTemplateId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook Template' LIMIT 1].Id;
        
        Test.startTest();
        try {
            ReleasePlaybookController.createReleasePlaybookItems(releasePlaybookId, selectedTemplateId);
        } catch (Exception e) {
            System.debug('Exception thrown: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
        Test.stopTest();
        
        List<Release_Playbook_Item__c> items = [SELECT Id FROM Release_Playbook_Item__c WHERE Release_Playbook__c = :releasePlaybookId];
        List<Release_Assignment__c> assignments = [SELECT Id FROM Release_Assignment__c WHERE Release_Playbook__c = :releasePlaybookId];
        
        System.assert(items.size() > 0, 'There should be new Release Playbook Items created.');
        System.assert(assignments.size() > 0, 'There should be new Release Assignments created.');
    }
    
    @isTest
    static void testCreateReleasePlaybookItems_noTemplateId() {
        Id releasePlaybookId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook' LIMIT 1].Id;
        
        Test.startTest();
        try {
            ReleasePlaybookController.createReleasePlaybookItems(releasePlaybookId, null);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected error message.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateReleasePlaybookItems_itemsAlreadyExist() {
        Id releasePlaybookId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook' LIMIT 1].Id;
        Id selectedTemplateId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook Template' LIMIT 1].Id;
        
        // Insert an item to simulate existing items
        Release_Playbook_Item__c existingItem = new Release_Playbook_Item__c(Release_Playbook__c = releasePlaybookId, Area__c = 'Testing');
        insert existingItem;
        
        Test.startTest();
        try {
            ReleasePlaybookController.createReleasePlaybookItems(releasePlaybookId, selectedTemplateId);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected error message.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateReleasePlaybookItems_noChildTemplates() {
        Id releasePlaybookId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook' LIMIT 1].Id;
        Id selectedTemplateId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook Template' LIMIT 1].Id;
        
        // Remove child templates to simulate no child templates
        List<Release_Playbook_Item__c> childTemplates = [SELECT Id FROM Release_Playbook_Item__c WHERE Release_Playbook__c = :selectedTemplateId];
        delete childTemplates;
        
        Test.startTest();
        try {
            ReleasePlaybookController.createReleasePlaybookItems(releasePlaybookId, selectedTemplateId);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected error message.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateReleasePlaybookItems_noAssignments() {
        Id releasePlaybookId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook' LIMIT 1].Id;
        Id selectedTemplateId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook Template' LIMIT 1].Id;
        
        // Remove assignments to simulate no assignments
        List<Release_Assignment__c> assignments = [SELECT Id FROM Release_Assignment__c WHERE Release_Playbook__c = :selectedTemplateId];
        delete assignments;
        
        Test.startTest();
        try {
            ReleasePlaybookController.createReleasePlaybookItems(releasePlaybookId, selectedTemplateId);
        } catch (Exception e) {
            System.debug('Exception thrown: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
        Test.stopTest();
        
        List<Release_Playbook_Item__c> items = [SELECT Id FROM Release_Playbook_Item__c WHERE Release_Playbook__c = :releasePlaybookId];
        List<Release_Assignment__c> newAssignments = [SELECT Id FROM Release_Assignment__c WHERE Release_Playbook__c = :releasePlaybookId];
        
        System.assert(items.size() > 0, 'There should be new Release Playbook Items created.');
        System.assertEquals(0, newAssignments.size(), 'There should be no new Release Assignments created.');
    }
    
    @isTest
    static void testCreateReleasePlaybookItems_InvalidTemplateId() {
        Id releasePlaybookId = [SELECT Id FROM Release_Playbook__c WHERE RecordType.Name = 'Release Playbook' LIMIT 1].Id;
        Id invalidTemplateId = 'a2g7d000002aryXAAQ';
        
        Test.startTest();
        try {
            ReleasePlaybookController.createReleasePlaybookItems(releasePlaybookId, invalidTemplateId);
            System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected error message.');
        }
        Test.stopTest();
    }
    
}