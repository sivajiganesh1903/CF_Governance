@isTest
public class ReleaseTriggerCustomTest {    
    @isTest
    public static void testPopulateReleaseStartDate() {
        // Test Case 1: Valid Release Name with 3 parts
        copado__Release__c validRelease = new copado__Release__c( Name = 'TRL 21.07.15', Release_Start_Date__c = null);        
        // Test Case 2: Invalid Release Name (does not split into 3 parts)
        copado__Release__c invalidRelease = new copado__Release__c(Name = 'TRL 21.07',Release_Start_Date__c = null);
        
        Test.startTest();
        insert new List<copado__Release__c>{ validRelease, invalidRelease };
        Test.stopTest();
        
        // Verify results for valid release
        copado__Release__c validReleaseResult = [SELECT Id, Release_Start_Date__c FROM copado__Release__c WHERE Id = :validRelease.Id];
        System.assertNotEquals(null, validReleaseResult.Release_Start_Date__c, 'Release Start Date should be populated.');        
        // Verify results for invalid release
        copado__Release__c invalidReleaseResult = [SELECT Release_Start_Date__c FROM copado__Release__c WHERE Id = :invalidRelease.Id];
        System.assertEquals(null, invalidReleaseResult.Release_Start_Date__c, 'Release Start Date should be null for invalid name.');
    }
    
    @isTest
    public static void testUpdateReleaseCompletionUpdate() {
        // Create initial release
        copado__Release__c release = new copado__Release__c(Name = 'TRL 21.07.15', copado__Status__c = 'In Progress');       
        insert release;
        
        // Update the release status to 'Released'
        release.copado__Status__c = 'Released';
        update release;
        
        Test.startTest();
        update release;
        Test.stopTest();
        
        // Verify results
        copado__Release__c updatedRelease = [SELECT Release_Completion_Date__c FROM copado__Release__c WHERE Id = :release.Id];
        System.assertNotEquals(null, updatedRelease.Release_Completion_Date__c, 'Release Completion Date should be populated.');
        System.assertEquals(Date.today(), updatedRelease.Release_Completion_Date__c, 'Release Completion Date should match today\'s date.');
    }
    
    @isTest
    public static void testUpdateReleaseCompletionUpdate_NoChange() {
        // Create initial release
        copado__Release__c release = new copado__Release__c(Name = 'TRL 21.07.15', copado__Status__c = 'Released');        
        insert release;       
        // Update release without changing the status
        release.Name = 'Updated Release Name';
        update release;
        
        Test.startTest();
        update release;
        Test.stopTest();
        
        copado__Release__c updatedRelease = [SELECT Release_Completion_Date__c FROM copado__Release__c WHERE Id = :release.Id];
        System.assertEquals(null, updatedRelease.Release_Completion_Date__c, 'Release Completion Date should not be updated.');
    }
    
    @isTest
    public static void testUpdateReleaseCompletionUpdate_StatusChange() {
        // Create initial release
        copado__Release__c release = new copado__Release__c(Name = 'TRL 21.07.15', copado__Status__c = 'In Progress');       
        insert release;
        
        // Update the release status to 'Cancelled'
        release.copado__Status__c = 'Cancelled';
        update release;
        
        Test.startTest();
        update release;
        Test.stopTest();
        
        // Verify results
        copado__Release__c updatedRelease = [SELECT Release_Completion_Date__c FROM copado__Release__c WHERE Id = :release.Id];
        System.assertNotEquals(null, updatedRelease.Release_Completion_Date__c, 'Release Completion Date should be populated.');
        System.assertEquals(Date.today(), updatedRelease.Release_Completion_Date__c, 'Release Completion Date should match today\'s date.');
    }
}