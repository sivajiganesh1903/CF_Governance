@isTest
public class UserstoryHandlerTest {
  /*  @testSetup
    static void setup() {
        // Create necessary records for the test setup
        // Create environments
        copado__Environment__c envQA = new copado__Environment__c(Name='FSC QA', CFEC__Type__c= 'DEV');
        copado__Environment__c envUAT = new copado__Environment__c(Name='FSC UAT', CFEC__Type__c= 'DEV');
        copado__Environment__c envPreprod = new copado__Environment__c(Name='FSC Preprod', CFEC__Type__c= 'DEV');
        insert new List<copado__Environment__c>{envQA, envUAT, envPreprod};

        // Create deployment flow
        copado__Deployment_Flow__c deploymentFlow = new copado__Deployment_Flow__c(Name='Test Deployment Flow');
        insert deploymentFlow;

        // Create deployment flow steps
        copado__Deployment_Flow_Step__c stepQA = new copado__Deployment_Flow_Step__c(
            copado__Deployment_Flow__c = deploymentFlow.Id,
            copado__Source_Environment__c = envQA.Id,
            copado__Destination_Environment__c = envUAT.Id
        );
        copado__Deployment_Flow_Step__c stepUAT = new copado__Deployment_Flow_Step__c(
            copado__Deployment_Flow__c = deploymentFlow.Id,
            copado__Source_Environment__c = envUAT.Id,
            copado__Destination_Environment__c = envPreprod.Id
        );
        insert new List<copado__Deployment_Flow_Step__c>{stepQA, stepUAT};

        // Create teams
        copado__Team__c team = new copado__Team__c(Name='Team A', Offshore_Devops__c=UserInfo.getUserId(), Onshore_DevOps__c=UserInfo.getUserId());
        insert team;

        // Create credentials
        copado__Org__c credentialQA = new copado__Org__c(Name='FSC QA');
        copado__Org__c credentialUAT = new copado__Org__c(Name='FSC UAT');
        copado__Org__c credentialINT = new copado__Org__c(Name='FSC INT');
        insert new List<copado__Org__c>{credentialQA, credentialUAT, credentialINT};
    }
    
    @isTest
    static void testUserstoryTrigger() {
        // Fetch created records
        copado__Team__c team = [SELECT Id, Offshore_Devops__c, Onshore_DevOps__c FROM copado__Team__c LIMIT 1];
        copado__Environment__c envQA = [SELECT Id FROM copado__Environment__c WHERE Name = 'FSC QA' LIMIT 1];
        copado__Environment__c envUAT = [SELECT Id FROM copado__Environment__c WHERE Name = 'FSC UAT' LIMIT 1];
        copado__Environment__c envPreprod = [SELECT Id FROM copado__Environment__c WHERE Name = 'FSC Preprod' LIMIT 1];
        copado__Org__c credentialQA = [SELECT Id FROM copado__Org__c WHERE Name = 'FSC QA' LIMIT 1];
        copado__Org__c credentialUAT = [SELECT Id FROM copado__Org__c WHERE Name = 'FSC UAT' LIMIT 1];
        copado__Org__c credentialINT = [SELECT Id FROM copado__Org__c WHERE Name = 'FSC INT' LIMIT 1];
        
        // Create a user story
        copado__User_Story__c userStory = new copado__User_Story__c(
            copado__User_Story_Title__c = 'Test Story',
            copado__Status__c = 'In Progress',
            copado__Org_Credential__c = credentialQA.Id,
            copado__Team__c = team.Id,
            copado__Environment__c = envQA.Id
        );
        insert userStory;
        
        // Update user story to trigger different branches
        userStory.copado__Status__c = 'Done';
        userStory.copado__Org_Credential__c = credentialUAT.Id;
        userStory.copado__Environment__c = envUAT.Id; // Matching environment with credential
        update userStory;
        
        userStory.copado__Status__c = 'Work Complete';
        userStory.copado__Org_Credential__c = credentialINT.Id;
        userStory.copado__Environment__c = envPreprod.Id; // Matching environment with credential
        update userStory;
        
        // Test completed task update scenario
        Task relatedTask = new Task(
            WhatId = userStory.Id,
            Status = 'Not Started',
            Subject = 'Test Task'
        );
        insert relatedTask;

        userStory.copado__Org_Credential__c = credentialINT.Id;
        userStory.copado__Status__c = 'Work Complete';
        userStory.copado__Environment__c = envPreprod.Id; // Matching environment with credential
        update userStory;
        
        // Assert task updates
        relatedTask = [SELECT Status FROM Task WHERE Id = :relatedTask.Id];
        System.assertEquals('Completed', relatedTask.Status);
        
        // Assert new tasks
        List<Task> insertedTasks = [SELECT Id, OwnerId, Subject FROM Task WHERE WhatId = :userStory.Id AND Status != 'Completed'];
        System.assertEquals(1, insertedTasks.size());
        System.assertEquals(team.Offshore_Devops__c, insertedTasks[0].OwnerId);

        // Assert no errors
        System.assertNotEquals(null, userStory.Id);
    } */
}