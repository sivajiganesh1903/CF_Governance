@isTest
public class UpdateTaskRecordTest {
    @isTest
    static void testUserStoryTrigger() {
        // Create test data - User Story and related Task
        copado__User_Story__c userStory = new copado__User_Story__c(copado__Org_Credential__c = 'a167e000002QmsFAAS');
        insert userStory;

        Task task = new Task(WhatId = userStory.Id, Credential__c = 'a167e000002QmsFAAS');
        insert task;

        // Update User Story's Credential
        userStory.copado__Org_Credential__c = 'a167e000002QmsZAAS';
        update userStory;

        // Verify that Task's Environment is updated
        Task updatedTask = [SELECT Credential__c FROM Task WHERE Id = :task.Id];
        System.assertEquals('a167e000002QmsZAAS', updatedTask.Credential__c);
    }
}