@isTest
private class CopadoReleaseControllerTest {
    
    @isTest
    static void testGetUserStories() {
        // Create or query the necessary data
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(Name = 'Test Pipeline');
        insert pipeline;
        
        Release_Playbook__c releaseTemplate = new Release_Playbook__c(Status__c = 'In Progress');
        insert releaseTemplate;
        
        Release_Playbook__c playbook = new Release_Playbook__c(Pipeline__c = pipeline.Id, //Use the created Pipeline ID
                                                               Status__c = 'Not Started',
                                                               Release_Template__c = releaseTemplate.Id // Use the correct ID
                                                              );
        insert playbook;
        
        copado__Release__c release = new copado__Release__c(Name = 'Test Release', Release_Playbook__c = playbook.Id);
        insert release;
        
        copado__Team__c team = new copado__Team__c(Name = 'Test Team');
        insert team;
        
        copado__User_Story__c userStory = new copado__User_Story__c(Jira_Key__c = 'TEST-123',
                                                                    Priority_Severity__c = 'High',
                                                                    RecordTypeId = Schema.SObjectType.copado__User_Story__c.getRecordTypeInfosByName().get('User Story').getRecordTypeId(),
                                                                    copado__User_Story_Title__c = 'Test Story Title', copado__Team__c = team.Id,
                                                                    copado__Release__c = release.Id);
        insert userStory;
        
        Test.startTest();
        List<CopadoReleaseController.UserStoryWrapper> result = CopadoReleaseController.getUserStories(playbook.Id);
        Test.stopTest();
        
        System.assertEquals(1, result.size());
    }
    
    @isTest
    static void testGetCopadoReleases() {
        // Create or query the necessary data
        copado__Deployment_Flow__c deploymentFlow = new copado__Deployment_Flow__c(Name = 'FSC Salesforce');
        insert deploymentFlow;
        
        copado__Project__c project = new copado__Project__c(Name = 'Test Project', copado__Deployment_Flow__c = deploymentFlow.Id);
        insert project;
        
        copado__Release__c release = new copado__Release__c(Name = 'Test Release', copado__Project__c = project.Id);
        insert release;
        
        Test.startTest();
        List<CopadoReleaseController.ReleaseWrapper> result = CopadoReleaseController.getCopadoReleases();
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals(release.Name, result[0].releaseName);
    }
    
    @isTest
    static void testSaveRelease() {
        // Create or query the necessary data
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(Name = 'Test Pipeline');
        insert pipeline;
        
        Release_Playbook__c releaseTemplate = new Release_Playbook__c(Status__c = 'In Progress');
        insert releaseTemplate;
        
        Release_Playbook__c playbook = new Release_Playbook__c(Pipeline__c = pipeline.Id, // Use the created Pipeline ID
                                                               Status__c = 'Not Started',
                                                               Release_Template__c = releaseTemplate.Id // Use the correct ID
                                                              );
        insert playbook;
        
        copado__Release__c release1 = new copado__Release__c(Name = 'Release1', copado__Status__c = 'Draft');
        insert release1;
        
        copado__Release__c release2 = new copado__Release__c(Name = 'Release2', copado__Status__c = 'Planned');
        insert release2;
        
        List<Id> releaseIds = new List<Id>{release1.Id, release2.Id};
            
            Test.startTest();
        CopadoReleaseController.saveRelease(playbook.Id, releaseIds);
        Test.stopTest();
        
        release1 = [SELECT Release_Playbook__c FROM copado__Release__c WHERE Id = :release1.Id];
        release2 = [SELECT Release_Playbook__c FROM copado__Release__c WHERE Id = :release2.Id];
        
        System.assertEquals(playbook.Id, release1.Release_Playbook__c);
        System.assertEquals(playbook.Id, release2.Release_Playbook__c);
    }
    
    @isTest
    static void testFetchReleases() {
        // Create test data
        copado__Project__c project = new copado__Project__c(Name = 'Test Project');
        insert project;
        
        copado__Release__c release1 = new copado__Release__c(Name = 'Test Release 1',copado__Status__c = 'Draft',
                                                             copado__Project__c = project.Id);
        
        copado__Release__c release2 = new copado__Release__c(Name = 'Another Release',copado__Status__c = 'Draft',
                                                             copado__Project__c = project.Id);
        insert new List<copado__Release__c>{ release1, release2 };
            Test.startTest();
        List<CopadoReleaseController.ReleaseWrapper> releasesWithSearchKey = CopadoReleaseController.fetchReleases('Test');
        System.assertEquals(0, releasesWithSearchKey.size());
        
        // Test without searchKeyR
        List<CopadoReleaseController.ReleaseWrapper> allReleases = CopadoReleaseController.fetchReleases('');
        System.assertEquals(0, allReleases.size());
        Test.stopTest();
    }
    
    
    @isTest
    static void testGetAllUsers() {
        // Create test data
        User testUser = [SELECT Id, Name FROM User LIMIT 1];
        
        Test.startTest();
        List<User> result = CopadoReleaseController.getAllUsers();
        Test.stopTest();
        
        System.assert(!result.isEmpty());
    }
    
    @isTest
    static void testFetchUsers() {
        // Create test data
        User testUser = [SELECT Id, Name FROM User LIMIT 1];
        
        Test.startTest();
        List<User> result = CopadoReleaseController.fetchUsers(testUser.Name);
        Test.stopTest();
        
        System.assertEquals(1, result.size());
    }
    
    @isTest
    static void testSaveReleaseAssignments() {
        // Create or query the necessary data
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(Name = 'Test Pipeline');
        insert pipeline;
        
        Release_Playbook__c releaseTemplate = new Release_Playbook__c(Status__c = 'In Progress');
        insert releaseTemplate;
        
        Release_Playbook__c playbook = new Release_Playbook__c(Pipeline__c = pipeline.Id, // Use the created Pipeline ID
                                                               Status__c = 'Not Started',
                                                               Release_Template__c = releaseTemplate.Id // Use the correct ID
                                                              );
        insert playbook;
        
        User testUser = [SELECT Id FROM User LIMIT 1];
        List<Id> userIds = new List<Id>{testUser.Id};
            
            Test.startTest();
        try{
            CopadoReleaseController.saveReleaseAssignments(playbook.Id, userIds);
        } catch(exception e){
            System.debug('Exception thrown: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
        Test.stopTest();
        
        List<Release_Assignment__c> assignments = [SELECT Id, Release_Playbook__c, Name__c FROM Release_Assignment__c WHERE Release_Playbook__c = :playbook.Id];       
        System.assertEquals(0, assignments.size());
    } 
}