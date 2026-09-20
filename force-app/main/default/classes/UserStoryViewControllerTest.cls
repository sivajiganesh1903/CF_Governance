@isTest
private class UserStoryViewControllerTest {    
    @testSetup
    static void setupTestData() {
        // Create test Environment
        copado__Environment__c testEnv = new copado__Environment__c(Name = 'UAT', Type__c = 'DEV');
        insert testEnv;
        
        // Create test credential
        copado__Org__c testOrg = new copado__Org__c(Name = 'Test Org');
        insert testOrg;

        // Create a single test Deployment Flow (Pipeline)
        copado__Deployment_Flow__c testFlow = new copado__Deployment_Flow__c(Name = 'Test Pipeline', copado__Active__c = true,
            copado__Platform__c = 'Salesforce');
        insert testFlow;
        
        // Create test Project
        copado__Project__c testProject = new copado__Project__c(Name = 'Test Project', copado__Description__c = 'Test project', 
                                                                copado__Start_Date__c = Date.today(),
                                                                copado__End_Date__c = Date.today().addMonths(6), 
                                                                copado__Status__c = 'In Progress', 
                                                                copado__Deployment_Flow__c = testFlow.Id );
        insert testProject;

        // Create test story (as What object)
        copado__User_Story__c testStory = new copado__User_Story__c(copado__User_Story_Title__c = 'Test Story', 
                                                                    copado__Org_Credential__c = testOrg.Id, 
                                                                    copado__Project__c = testProject.Id);
        insert testStory;
        
        // Create test Tasks with a matching status and environment
    List<Task> testTasks = new List<Task>();
    for(Integer i = 0; i < 5; i++) {
        testTasks.add(new Task(Subject = 'Test Task ' + i, Environment__c = testEnv.Id, Status = 'Open', 
                               Jira_Key__c = 'JIRA-' + i, Priority = 'Normal', WhatId = testStory.Id));
    }
    insert testTasks;
    }
    
    @isTest
static void testGetTasks() {
    Test.startTest();
    // Calling the getTasks() method to retrieve the tasks
    List<UserStoryViewController.TaskWrapper> result = UserStoryViewController.getTasks();
    Test.stopTest();
    
    // Assert that some tasks are returned
    System.assertNotEquals(0, result.size(), 'Should return some tasks');
    
    // Assert that exactly 5 tasks are returned (as created in @testSetup)
    System.assertEquals(5, result.size(), 'Should return 5 tasks');
    
    for (UserStoryViewController.TaskWrapper tw : result) {
        System.assertNotEquals(null, tw.id, 'Task ID should not be null');
        System.assertNotEquals(null, tw.whatId, 'What ID should not be null');
        System.assertEquals('UAT', tw.environment, 'Environment should be TrnUat');
        System.assertEquals('Open', tw.status, 'Status should be Open');
    }
}  
    @isTest
    static void testGetTasksWithNoData() {
        // Delete all tasks
        delete [SELECT Id FROM Task];
        
        Test.startTest();
        List<UserStoryViewController.TaskWrapper> result = UserStoryViewController.getTasks();
        Test.stopTest();
        
        // Assertions
        System.assertEquals(0, result.size(), 'Should return no tasks when no data exists');
    }
    
    @isTest
    static void testTaskWrapper() {
        UserStoryViewController.TaskWrapper tw = new UserStoryViewController.TaskWrapper('testId', 'testWhatId', 
                                                                                         'testWhatName', 'testEnvironment', 
                                                                                         'testStatus');
        
        // Assertions
        System.assertEquals('testId', tw.id, 'ID should match');
        System.assertEquals('testWhatId', tw.whatId, 'What ID should match');
        System.assertEquals('testWhatName', tw.whatName, 'What Name should match');
        System.assertEquals('testEnvironment', tw.environment, 'Environment should match');
        System.assertEquals('testStatus', tw.status, 'Status should match');
    }
}