@IsTest
private class jiraconnectorhelperTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Change Story
        Change_Story__c testChangeStory = new Change_Story__c(
            Name = 'TEST-123',
            Id__c = '12345',
            Status__c = 'Open'
        );
        insert testChangeStory;
        
        // Create test User Story
        Copado__User_Story__c testUserStory = new Copado__User_Story__c(
            copado__User_Story_Title__c = 'Test User Story',
            copadoconnect__External_ID__c = '67890'
        );
        insert testUserStory;
        
        // Create additional Change Story for testing
        Change_Story__c testChangeStory2 = new Change_Story__c(
            Name = 'TEST-456',
            Id__c = '45678',
            Status__c = 'Open'
        );
        insert testChangeStory2;
    }
    
    @IsTest
    static void testStorycreated() {
        Map<String, Object> payload = new Map<String, Object>{
            'issue' => new Map<String, Object>{
                'key' => 'TEST-456',
                'id' => '456789',
                'fields' => new Map<String, Object>{
                    'status' => new Map<String, Object>{
                        'name' => 'In Progress'
                    }
                }
            }
        };
        
        Test.startTest();
        jiraconnectorhelper.storycreated(payload);
        Test.stopTest();
        
        List<Change_Story__c> stories = [SELECT Id, Name, Id__c, Status__c FROM Change_Story__c WHERE Id__c = '456789'];
        System.assertEquals(1, stories.size(), 'Change Story should be created');
        System.assertEquals('TEST-456', stories[0].Name);
        System.assertEquals('In Progress', stories[0].Status__c);
    }
    
    @IsTest
    static void testIssuelinkCreated_ChangeStoryToUserStory() {
        Map<String, Object> payload = new Map<String, Object>{
            'issueLink' => new Map<String, Object>{
                'id' => 'link123',
                'destinationIssueId' => '12345',
                'sourceIssueId' => '67890'
            }
        };
        
        Test.startTest();
        jiraconnectorhelper.issuelinkcreated(payload);
        Test.stopTest();
        
        List<Change_Story_List__c> cslList = [SELECT Id FROM Change_Story_List__c WHERE Issue_Link_ID__c = 'link123'];
        System.assertEquals(1, cslList.size(), 'Change Story List should be created');
    }
    
    @IsTest
    static void testIssuelinkCreated_UserStoryToChangeStory() {
        Map<String, Object> payload = new Map<String, Object>{
            'issueLink' => new Map<String, Object>{
                'id' => 'link456',
                'destinationIssueId' => '67890',
                'sourceIssueId' => '12345'
            }
        };
        
        Test.startTest();
        jiraconnectorhelper.issuelinkcreated(payload);
        Test.stopTest();
        
        List<Change_Story_List__c> cslList = [SELECT Id FROM Change_Story_List__c WHERE Issue_Link_ID__c = 'link456'];
        System.assertEquals(1, cslList.size(), 'Change Story List should be created');
    }
    
    @IsTest
    static void testIssuelinkdeleted() {
        Change_Story_List__c testCSL = new Change_Story_List__c(
            Issue_Link_ID__c = 'deleteLink123',
            Change_Story__c = [SELECT Id FROM Change_Story__c WHERE Id__c = '12345' LIMIT 1].Id,
            User_Story__c = [SELECT Id FROM Copado__User_Story__c LIMIT 1].Id
        );
        insert testCSL;
        
        Map<String, Object> payload = new Map<String, Object>{
            'issueLink' => new Map<String, Object>{
                'id' => 'deleteLink123'
            }
        };
        
        Test.startTest();
        jiraconnectorhelper.issuelinkdeleted(payload);
        Test.stopTest();
        
        List<Change_Story_List__c> remainingCSL = [SELECT Id FROM Change_Story_List__c WHERE Issue_Link_ID__c = 'deleteLink123'];
        System.assertEquals(0, remainingCSL.size(), 'Change Story List should be deleted');
    }
    
    @IsTest
    static void testIssueupdated() {
        Change_Story__c existingCS = [SELECT Id FROM Change_Story__c WHERE Id__c = '12345' LIMIT 1];
        
        // Create Change Story List record
        Change_Story_List__c csl = new Change_Story_List__c(
            Change_Story__c = existingCS.Id,
            Status__c = 'Open'
        );
        insert csl;
        
        Map<String, Object> payload = new Map<String, Object>{
            'issue' => new Map<String, Object>{
                'id' => '12345',
                'fields' => new Map<String, Object>{
                    'status' => new Map<String, Object>{
                        'name' => 'Completed'
                    }
                }
            }
        };
        
        Test.startTest();
        jiraconnectorhelper.issueupdated(payload);
        Test.stopTest();
        
        Change_Story__c updatedCS = [SELECT Status__c FROM Change_Story__c WHERE Id = :existingCS.Id];
        System.assertEquals('Completed', updatedCS.Status__c);
        
        Change_Story_List__c updatedCSL = [SELECT Status__c FROM Change_Story_List__c WHERE Id = :csl.Id];
        System.assertEquals('Completed', updatedCSL.Status__c);
    }
    
    @IsTest
    static void testEdgeCases() {
        // Test null payload for issuelinkcreated
        jiraconnectorhelper.issuelinkcreated(new Map<String, Object>());
        
        // Test issuelinkdeleted with non-existent link
        Map<String, Object> payload = new Map<String, Object>{
            'issueLink' => new Map<String, Object>{
                'id' => 'nonexistent'
            }
        };
        jiraconnectorhelper.issuelinkdeleted(payload);
        
        // Verify no exceptions were thrown
        System.assert(true, 'Edge cases should be handled without exceptions');
    }
}