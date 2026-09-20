@isTest
public class TaskTriggerHandlerTest {
    
    @testSetup
    static void createObjectData(){                                             //creating all object Data
        
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense UL = new copado.GlobalAPI.UserLicense();
        
        UL.isCADEnabled = false; //Agile delivery license
        UL.isCCHEnabled = false; //Compliance hub license
        UL.isCCMEnabled = true; //Change management (developer) license
        UL.isCopadoEnabled = true; //Enterprise (admin / release manager) license
        //UL.isCSTEnabled = true; //Copado Selenium testing license
        UL.userId = UserInfo.getUserId();
        
        copado.GlobalAPI.LicenseOperationResult result = copadoGlobalAPI.upsertCopadoLicense(UL);
        if(result.isSuccess){
            System.debug('License assigned successfully');
        } else {
            System.debug('An error occurred during license assignment with the error message ' + result.errorString);
        }
        
        // CREATE ENVIRONMENT
        copado__Environment__c objEnvi1 = new copado__Environment__c(Name='TRNDEV1',copado__Platform__c='Salesforce');
        insert objEnvi1;
        
        copado__Environment__c objEnvi2 = new copado__Environment__c(Name='TRNQA',copado__Platform__c='Salesforce');
        insert objEnvi2;
        
        
        //CREATE CREDENTIAL
        copado__Org__c objCredential1 = new copado__Org__c (Name='TRNDEV1',	copado__Org_Type__c='Sandbox' ,copado__Disable_Validation__c=true,copado__Environment__c = objEnvi1.Id);
        insert objCredential1;
        
        copado__Org__c objCredential2 = new copado__Org__c (Name='TRNQA',	copado__Org_Type__c='Sandbox' ,copado__Disable_Validation__c=true,copado__Environment__c = objEnvi2.Id);
        insert objCredential2;
        
                
        copado__Deployment__c objDep1 = New copado__Deployment__c(Name='depName1',copado__From_Org__c=objCredential1.Id);
        insert objDep1;
      
        
        copado__Deployment__c objDep2 = New copado__Deployment__c(Name='depName2',copado__From_Org__c=objCredential1.Id,copado__Status__c='Draft');
        insert objDep2;
        
        //CREATE PIPELINE
        copado__Deployment_Flow__c objPipeline = new copado__Deployment_Flow__c(Name= 'Test Pipeline Name',copado__Active__c = true,copado__Platform__c ='Salesforce'/*,copado__Deployment_Automation__c =objDep1.Id*/);
        insert objPipeline;
        
        //CREATE PIPELINE CONNECTIONS
        copado__Deployment_Flow_Step__c objPipConn = new copado__Deployment_Flow_Step__c(copado__Deployment_Flow__c = objPipeline.Id,	copado__Source_Environment__c=objEnvi1.Id, 	copado__Destination_Environment__c=objEnvi2.Id,	copado__Branch__c='trndev1');
        insert objPipConn;
        
        //CREATE STEP
        List<copado__Step__c> stepList=new List<copado__Step__c>();
        
        for(Integer i=0 ; i<20; i++){
            copado__Step__c objStep= new copado__Step__c(Name='promotion 1'+i,copado__Deployment__c=objDep1.Id,copado__Order__c=1,copado__Branch__c ='promotion',copado__Status__c='In progress',copado__CheckOnly__c=true);
            stepList.add(objStep);
        }
        Database.insert(stepList,false);
        
        system.debug('stepList  object List'+stepList);
        system.debug('stepList  object List Size'+stepList.Size());
        
        //CREATE PROJECT
        
        copado__Project__c objProject= new copado__Project__c(Name='Test Project Name',copado__Deployment_Flow__c=objPipeline.Id);
        insert objProject;
        
        
         // for Copado User Story Object
        List<copado__User_Story__c> USList = new List<copado__User_Story__c>();
        
        for(Integer i=0 ; i<20; i++){
            copado__User_Story__c objUS  = new copado__User_Story__c(copado__User_Story_Title__c = 'Test User Story'+i,
                                                                     copado__Exclude_From_CBM__c = false, 
                                                                     copado__Stop_Indexing_Metadata__c = false,
                                                                     copado__Status__c='Done');
            USList.add(objUS);
        }
        Database.insert(USList,false);
        system.debug(' User Story List'+USList);
        system.debug(' User Story List Size'+USList.size());
        //fetch one user story object record
        Test.startTest();
        copado__User_Story__c objcopUs = [select id,copado__User_Story_Title__c from copado__User_Story__c where copado__User_Story_Title__c = 'Test User Story1'];
        
        system.debug('copData'+objcopUs);
        
        //for Copado User Story Task Object
        List<copado__User_Story_Task__c> USTaskList = new List<copado__User_Story_Task__c>();
        
        for(Integer i=0 ; i<20; i++){
            copado__User_Story_Task__c objUSTask = new copado__User_Story_Task__c(copado__User_Story__c = objcopUs.id);
            USTaskList.add(objUSTask);
        }
        Database.insert(USTaskList,false);
        
        // for copado Deployment Task object
        List<copado__Deployment_Task__c> deployTaskList = new List<copado__Deployment_Task__c>();
        
        for(Integer i=0 ; i<20; i++){
            copado__Deployment_Task__c objDeployTask = new copado__Deployment_Task__c(Name = 'Test Deployment Task'+i,	copado__Type__c = 'Manual Task',copado__User_Story__c = objcopUs.id);
            deployTaskList.add(objDeployTask);
        }
        Database.insert(deployTaskList,false);
        
        // for user story Metadata Object
        List<copado__User_Story_Metadata__c> metadataList = new List<copado__User_Story_Metadata__c>();
        
        for(Integer i=0 ; i<20; i++){
            copado__User_Story_Metadata__c objUSMetadata = new copado__User_Story_Metadata__c(Name = 'Test Metadata'+i,copado__User_Story__c = objcopUs.id);
            metadataList.add(objUSMetadata);
        }
        Database.insert(metadataList,false);
        
        // for copado__Pull_Request__c object
        List<copado__Pull_Request__c> pullRequestList = new List<copado__Pull_Request__c>();
        
        for(Integer i=0 ; i<20; i++){
            copado__Pull_Request__c objPullRequest = new copado__Pull_Request__c(Name = 'Test Pull Request'+i,copado__User_Story__c = objcopUs.id);
            pullRequestList.add(objPullRequest);
        }
        Database.insert(pullRequestList,false);
        
        // for copado__User_Story_Data_Commit__c object
        
        //for data template object
        copado__Data_Template__c objDataTemplate = new copado__Data_Template__c(Name = 'Test Data Template',copado__Active__c = true);
        Database.insert(objDataTemplate,false);
        
        // for Data Set Object    
        copado__Data_Set__c objDataSet = new copado__Data_Set__c(Name='Test Data Set',copado__Data_Template__c = objDataTemplate.Id);
        Database.insert(objDataSet,false);
        
        List<copado__User_Story_Data_Commit__c> USDataCommitList = new List<copado__User_Story_Data_Commit__c>();
        
        for(Integer i=0 ; i<20; i++){
            copado__User_Story_Data_Commit__c objUSdataCommit = new copado__User_Story_Data_Commit__c(copado__User_Story__c = objcopUs.id,copado__Data_Set__c = objDataSet.Id,	copado__Commit_Message__c ='Just for testing');
            USDataCommitList.add(objUSdataCommit);
        }
        Database.insert(USDataCommitList,false);
        
        
        system.debug(' copado__User_Story_Data_Commit__c object List'+USDataCommitList);
        system.debug(' copado__User_Story_Data_Commit__c object List size '+USDataCommitList.size());
        
        //   for copado__Static_Code_Analysis_Result__c  object
        
        List<copado__Static_Code_Analysis_Result__c> SCAList = new List<copado__Static_Code_Analysis_Result__c>();
        
        for(Integer i=0 ; i<20; i++){
            copado__Static_Code_Analysis_Result__c objSCAresult = new copado__Static_Code_Analysis_Result__c(copado__User_Story__c = objcopUs.id);
            SCAList.add(objSCAresult);
        }
        Database.insert(SCAList,false);
        Test.stopTest();

        //task Object Record Creations
                // Create a sample Task related to the Account
                Task t = new Task(WhatId = objcopUs.id, Subject = 'Test Task', Status = 'Not Started');
                insert t;

        // Create a Task_Log__c record related to the Account
        Task_Log__c taskLog = new Task_Log__c(User_Story__c = objcopUs.Id, Task_ID__c = t.Id);
        insert taskLog;
    }

    
    @isTest
    static void testHandleTaskInProgress() {
        // Get the Task record
        Task t = [SELECT Id, Status FROM Task LIMIT 1];
            // Get the related Task_Log__c record and close it
        Task_Log__c taskLog = [SELECT Id, Status__c FROM Task_Log__c WHERE Task_ID__c = :t.Id LIMIT 1];
        taskLog.Status__c = 'Completed';  // or whatever status indicates it is closed in your system
        update taskLog;
        
        // Update the task status to 'In Progress'
        t.Status = 'In Progress';

        // Create the oldTaskMap
        Map<Id, Task> oldTaskMap = new Map<Id, Task>([SELECT Id, Status FROM Task WHERE Id = :t.Id]);
        
        // Update the Task
        Test.startTest();
        update t;
        Test.stopTest();

            // Verify the Task_Log__c record is not duplicated
    List<Task_Log__c> taskLogs = [SELECT Id, Status__c FROM Task_Log__c WHERE Task_ID__c = :t.Id];
    System.assertEquals(2, taskLogs.size(), 'Expected 2 Task_Log__c records: one closed and one open.');
        // Verify the open Task_Log__c record
        Task_Log__c openLog = null;
        for (Task_Log__c log : taskLogs) {
            if (log.Status__c == 'Open') {
                openLog = log;
                break;
            }
        }

        System.assertNotEquals(null, openLog, 'Expected to find an open Task_Log__c record.');
    }
    
    @isTest
    static void testHandleTaskOnHold() {
        // Get the Task record
        Task t = [SELECT Id, Status FROM Task LIMIT 1];
        t.Status = 'On Hold';
        
        // Create the oldTaskMap
        Map<Id, Task> oldTaskMap = new Map<Id, Task>([SELECT Id, Status FROM Task WHERE Id = :t.Id]);
        
        // Update the Task
        Test.startTest();
        update t;
        Test.stopTest();
        
        // Verify the Task_Log__c record is updated
        List<Task_Log__c> taskLogs = [SELECT Id, Status__c, Hand_Off__c FROM Task_Log__c WHERE Task_ID__c = :t.Id];
        System.assertEquals(1, taskLogs.size());
        System.assertEquals('Hand Off', taskLogs[0].Status__c);
        System.assertNotEquals(null, taskLogs[0].Hand_Off__c);
    }
    
    @isTest
    static void testHandleTaskCompleted() {
        // Get the Task record
        Task t = [SELECT Id, Status FROM Task LIMIT 1];
        t.Status = 'Completed';
        
        // Create the oldTaskMap
        Map<Id, Task> oldTaskMap = new Map<Id, Task>([SELECT Id, Status FROM Task WHERE Id = :t.Id]);
        
        // Update the Task
        Test.startTest();
        update t;
        Test.stopTest();
        
        // Verify the Task_Log__c record is updated
        List<Task_Log__c> taskLogs = [SELECT Id, Status__c, Completed_Time__c FROM Task_Log__c WHERE Task_ID__c = :t.Id];
        System.assertEquals(1, taskLogs.size());
        System.assertEquals('Completed', taskLogs[0].Status__c);
        System.assertNotEquals(null, taskLogs[0].Completed_Time__c);
    }
    @isTest
    static void testHandleTaskErrorOnDuplicateLog() {
        // Get the Task record
        Task t = [SELECT Id, Status FROM Task LIMIT 1];
        t.Status = 'In Progress';
        
        // Create the oldTaskMap
        Map<Id, Task> oldTaskMap = new Map<Id, Task>([SELECT Id, Status FROM Task WHERE Id = :t.Id]);
        
        // Update the Task and expect an error
        Test.startTest();
        try {
            update t;
            System.assert(false, 'Expected an exception to be thrown due to duplicate Task_Log__c');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A Task Log Already exist for this task. Please close it before opening another task log on this.'));
        }
        Test.stopTest();
    }
}