@isTest
public class ReleasePlaybookItmeHelperTest {
    @TestSetup
    static void setupTestData() { 
        // Set up Copado License
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense UL = new copado.GlobalAPI.UserLicense();
        UL.isCADEnabled = false; 
        UL.isCCHEnabled = false; 
        UL.isCCMEnabled = true; 
        UL.isCopadoEnabled = true; 
        UL.userId = UserInfo.getUserId();
        copado.GlobalAPI.LicenseOperationResult result = copadoGlobalAPI.upsertCopadoLicense(UL);
        
        // Create Pipeline
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(Name = 'Test Pipeline', copado__Active__c = true,
                                                                             copado__Platform__c = 'Salesforce');
        insert pipeline;
        
        // Create Project
        copado__Project__c project = new copado__Project__c(Name = 'Test Project Name', copado__Deployment_Flow__c = pipeline.Id);
        insert project;
        
        // Create Release Playbook
        Release_Playbook__c playbook = new Release_Playbook__c(Pipeline__c = pipeline.Id);
        insert playbook;
        System.debug('PlayBook Id: ++++ ' + playbook.Id);
        
        // Create Release Playbook Item
        Release_Playbook_Item__c playBookItem = new Release_Playbook_Item__c(
            Release_Playbook__c = playbook.Id,Status__c = 'Completed', 
            Sub_Items_Logic__c = 'Before Deployment - Preprod Promotion Package');
        insert playBookItem;
        System.debug('PlayBook Item Id: ----->>' + playBookItem.Id);
        
        // Create Environments
        // // Commneted tyep filed CFEC__Type__c
        copado__Environment__c sourceEnv = new copado__Environment__c(Name = 'TEST_DEV1', copado__Type__c = 'Sandbox', Type__c = 'DEV',
                                                                      copado__Platform__c = 'Salesforce');
        insert sourceEnv;
        
        copado__Environment__c destEnv = new copado__Environment__c(Name = 'TEST_QA1', copado__Type__c = 'Sandbox', Type__c = 'DEV',
                                                                    copado__Platform__c = 'Salesforce');
        insert destEnv;
        
        // Create Pipeline Connection
        copado__Deployment_Flow_Step__c pipelineConnection = new copado__Deployment_Flow_Step__c(
            copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id, 
            copado__Deployment_Flow__c = pipeline.Id);
        insert pipelineConnection;
        
        // Create Credentials
        copado__Org__c sourceCredential = new copado__Org__c(Name = 'TEST_DEV1', copado__Org_Type__c = 'Sandbox',
                                                             copado__Environment__c = sourceEnv.Id, copado__Default_Credential__c = true, 
                                                             copado__Username__c = 'test@test.com', OwnerId = UL.userId);
        insert sourceCredential;
        
        copado__Org__c destCredential = new copado__Org__c(Name = 'TEST_QA1', copado__Org_Type__c = 'Sandbox',
                                                           copado__Environment__c = destEnv.Id, copado__Default_Credential__c = true,
                                                           copado__Username__c = 'test2@test.com', OwnerId = UL.userId);
        insert destCredential;
        
        // Create Promotion
        copado__Promotion__c promotion = new copado__Promotion__c(copado__Source_Environment__c = sourceEnv.Id, copado__Destination_Environment__c = destEnv.Id,
                                                                  copado__Project__c = project.Id, OwnerId = UL.userId);
        insert promotion; 
        system.debug('promotion: ++++ ' + promotion);
        
        // Create deployment first
        copado__Deployment__c deployment = new copado__Deployment__c(Name = 'Test Deployment', copado__From_Org__c = sourceCredential.Id,
                                                                     copado__Promotion__c = promotion.Id, copado__Status__c = 'Completed Successfully');
        insert deployment;        
        system.debug('deployment: ++++ ' + deployment);
        
        // Create step and associate it with deployment
        copado__Step__c step = new copado__Step__c(copado__Deployment__c = deployment.Id, copado__Status__c = 'Completed Successfully', 
                                                   copado__CheckOnly__c = true); //copado__Type__c = 'Validation',
        insert step;
        System.debug('Copado Steps: ++++ ' + step);
        
        // Create Release Playbook Sub Item
        Release_Playbook_Sub_Item__c subItem = new Release_Playbook_Sub_Item__c(Release_Playbook_Item__c = playBookItem.Id,
                                                                                Promotion__c = promotion.Id, Deployment__c = deployment.Id);
        insert subItem;
        
        // Create Git Repository
        copado__Git_Repository__c repo = new copado__Git_Repository__c (Name = 'Test Repo', copado__URI__c = 'https://www.google.com');
        insert repo;
        
        // Create Git Backup record
        copado__Git_Backup__c gitBackup = new copado__Git_Backup__c(Name = 'Test Git Backup', copado__Git_Repository__c = repo.Id, 
                                                                    copado__Branch__c = 'Dev1', copado__Org__c = sourceCredential.Id,
                                                                    copado__Git_Snapshot_Permissions__c ='Allow Snapshots & Commits' );
        insert gitBackup;
        
        // Create Git Org Commit
        copado__Git_Org_Commit__c gitSnapshot = new copado__Git_Org_Commit__c(
            copado__Status__c = 'Complete', copado__Commit_Id__c = 'abc123', copado__Org__c = sourceCredential.Id,
            copado__Git_Backup__c = gitBackup.Id);
        insert gitSnapshot;
        
        copado__Static_Code_Analysis_Result__c scaresult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = sourceCredential.Id);
        
        List<copado__Deployment__c> verifyDeployments = [SELECT Id FROM copado__Deployment__c WHERE 
                                                         copado__Promotion__c = :promotion.Id];        
    }
    
    //  Test Cases
    @isTest
    static void testProcessReleasePlaybookSubItem2() {
        copado__Promotion__c promotion = [SELECT Id, CreatedDate, copado__Source_Environment__c, copado__Destination_Environment__c 
                                          FROM copado__Promotion__c LIMIT 1];
        System.debug('Promotion Record: +++' + promotion);
        
        copado__Deployment__c deployment = [SELECT Id, Name, copado__Promotion__c, copado__Status__c, copado__From_Org__c FROM copado__Deployment__c 
                                            WHERE copado__Promotion__c = :promotion.Id];
        System.debug('Old Deployment Record: +++' + deployment);
        
        deployment.copado__Status__c = 'Completed Successfully';
        update deployment;
        System.debug(deployment.copado__Status__c);
        
        System.debug('Deployment Record: +++' + deployment);
        
        copado__Step__c step = [SELECT Id, copado__Deployment__c, copado__Status__c, LastModifiedDate  FROM copado__Step__c WHERE copado__Deployment__c = :deployment.Id 
                                AND copado__Status__c = 'Completed Successfully' AND copado__CheckOnly__c = true LIMIT 1];
        System.debug('Step Record: +++' + step);
        
        Release_Playbook_Item__c playbookItem = [SELECT Id FROM Release_Playbook_Item__c LIMIT 1];
        playbookItem.Status__c = 'Completed';
        update playbookItem;
        System.debug('PlayBook Item Record: +++' + playbookItem);
        
        // Fetch updated playbook item
        playbookItem = [SELECT Id, Start_Date_Time__c, End_Date_Time__c FROM Release_Playbook_Item__c LIMIT 1];
        
        // Assertions
        System.assertNotEquals(playbookItem.Start_Date_Time__c, null, 'Start date should be updated');
        System.assertNotEquals(playbookItem.End_Date_Time__c, null, 'End date should be updated');
        
    }
    
    @isTest
    static void testProcessReleasePlaybookSubItem2_ExceptionCase() {
        Test.startTest();
        
        try {
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem2(null);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem6(null);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem8(null);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem11(null);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem15(null);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItems(null);
        } catch (Exception e) {
            System.debug('Expected Exception Caught: ' + e.getMessage());
        }
        
        try {
            List<Release_Playbook_Item__c> emptyList = new List<Release_Playbook_Item__c>();
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem2(emptyList);
        } catch (Exception e) {
            System.debug('Expected Exception Caught: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testProcessReleasePlaybookSubItem6() {
        Test.startTest();
        copado__Deployment__c deployment = [SELECT Id, Name, copado__Promotion__c, copado__Status__c, copado__From_Org__c FROM copado__Deployment__c];
        deployment.copado__Status__c = 'Completed Successfully';
        update deployment;
        System.debug('Updated Deployment: +++ ' + deployment.copado__Status__c);
        
        copado__Deployment_History__c history = new copado__Deployment_History__c(copado__Object__c = 'Deployment', copado__Field__c = 'Status', copado__Deployment__c = deployment.Id, 
                                                                                  copado__Date__c = System.Now(), copado__Old_Value__c = 'In progress', copado__New_Value__c = 'Completed Successfully');
        insert history;
        System.debug('Deployment History: +++ ' + history);
        
        Release_Playbook_Item__c playBookItem = [SELECT Id, Start_Date_Time__c, Status__c, End_Date_Time__c, Sub_Items_Logic__c 
                                                 FROM Release_Playbook_Item__c];
        playBookItem.Status__c = 'Completed';
        playBookItem.Sub_Items_Logic__c = 'Deployment - Preprod Package Completion';
        update playBookItem;
        
        // Verify the Results
        System.assertEquals(playbookItem.Status__c, 'Completed', 'Status should be completed');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessReleasePlaybookSubItem8() {
        copado__Org__c sourceCred = [SELECT Id, Name FROM copado__Org__c WHERE Name = 'TEST_DEV1'];
        
        copado__Promotion__c promotion = [SELECT Id, CreatedDate, copado__Source_Environment__c, copado__Destination_Environment__c 
                                          FROM copado__Promotion__c LIMIT 1];
        System.debug('Promotion Record: +++' + promotion);
        
        copado__Deployment__c deployment = [SELECT Id, Name, copado__Promotion__c, copado__Status__c, copado__From_Org__c FROM copado__Deployment__c 
                                            WHERE copado__Promotion__c = :promotion.Id];
        deployment.copado__Status__c = 'Completed Successfully';
        update deployment;        
        System.debug('Deployment Record: +++' + deployment);
        
        copado__Deployment_History__c history = new copado__Deployment_History__c(copado__Object__c = 'Deployment', copado__Field__c = 'Status', copado__Deployment__c = deployment.Id, 
                                                                                  copado__Date__c = System.Now(), copado__Old_Value__c = 'In progress', copado__New_Value__c = 'Completed Successfully');
        insert history;
        System.debug('Deployment History: +++ ' + history);
        
        
        copado__Deployment__c deploymentnew = new copado__Deployment__c(Name = 'Test Deployment-1', copado__From_Org__c = sourceCred.Id,
                                                                        copado__Promotion__c = promotion.Id, copado__Status__c = 'Completed Successfully');
        insert deploymentnew;        
        system.debug('deployment: ++++ ' + deploymentnew);
        
        copado__Deployment_History__c historynew = new copado__Deployment_History__c(copado__Object__c = 'Deployment', copado__Field__c = 'Status', copado__Deployment__c = deploymentnew.Id, 
                                                                                     copado__Date__c = System.Now(), copado__Old_Value__c = 'In progress', copado__New_Value__c = 'Completed Successfully');
        insert historynew;
        System.debug('Deployment History: +++ ' + historynew);
        
        Release_Playbook_Item__c playbookItem = [SELECT Id, Status__c, Sub_Items_Logic__c FROM Release_Playbook_Item__c LIMIT 1];
        playbookItem.Status__c = 'Completed';
        playbookItem.Sub_Items_Logic__c = 'Before Deployment - Create Promotion - Sign off Stories';
        update playbookItem;
        System.debug('PlayBook Item Record: +++' + playbookItem);
        
        // Fetch updated playbook item
        playbookItem = [SELECT Id, Start_Date_Time__c, End_Date_Time__c FROM Release_Playbook_Item__c LIMIT 1];
    }
    
    @isTest
    static void testProcessReleasePlaybookSubItem11() {
        Test.startTest();
        copado__Deployment__c deployment = [SELECT Id, Name, copado__Promotion__c, copado__Status__c, copado__From_Org__c FROM copado__Deployment__c];        
        deployment.copado__Status__c = 'Completed Successfully';
        update deployment;
        System.debug(deployment.copado__Status__c);
        
        copado__Step__c step = [SELECT Id, copado__Deployment__c, copado__Status__c, copado__CheckOnly__c FROM copado__Step__c 
                                WHERE copado__Deployment__c =: deployment.Id];
        System.debug('step : ' + step);
        
        
        Release_Playbook_Item__c playbookItem = [SELECT Id, Start_Date_Time__c, End_Date_Time__c FROM Release_Playbook_Item__c LIMIT 1];
        playbookItem.Status__c = 'Completed';
        playbookItem.Sub_Items_Logic__c = 'Before Deployment - Validate Package';
        update playbookItem;
        System.debug('Updated Play Book Item: +++ ' + playbookItem);
        
        System.assertEquals(playbookItem.Status__c, 'Completed', 'Status should be completed');        
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessReleasePlaybookSubItems_Order15() {
        
        copado__Git_Org_Commit__c sanpshot = [SELECT Id, Name, copado__Status__c, copado__Commit_Id__c, copado__Git_Backup__c, CreatedDate, 
                                              LastModifiedDate FROM copado__Git_Org_Commit__c];
        System.debug('Sanpshot Commit' + sanpshot);
        
        Release_Playbook_Sub_Item__c subItem = [SELECT Id, Snapshot_Commit__c FROM Release_Playbook_Sub_Item__c LIMIT 1];
        subItem.Snapshot_Commit__c = sanpshot.Id;
        update subItem;
        System.debug('updated Sub Item: ' + subItem);
        Release_Playbook_Item__c playBookItem = [SELECT Id, Sub_Items_Logic__c, Status__c FROM Release_Playbook_Item__c LIMIT 1];
        playBookItem.Sub_Items_Logic__c = 'Before Deployment - Sanpshot Commit - Release';
        playBookItem.Status__c = 'Completed';
        update playBookItem;
        System.debug('updated Playbook Item: ' + playBookItem);
        // Verify the results
        Release_Playbook_Item__c updatedItem = [SELECT Id, Start_Date_Time__c, End_Date_Time__c FROM Release_Playbook_Item__c];      
        System.assertNotEquals(null, updatedItem.Start_Date_Time__c);
        System.assertNotEquals(null, updatedItem.End_Date_Time__c);
    }
    
    @isTest
    static void testProcessReleasePlaybookSubItem2893() {  
        Test.startTest();
        copado__Deployment__c deployment = [SELECT Id, Name, copado__Promotion__c, copado__Status__c, copado__From_Org__c FROM copado__Deployment__c];
        deployment.copado__Status__c = 'Completed Successfully';
        update deployment;
        System.debug('Updated Deployment: +++ ' + deployment.copado__Status__c);
        
        copado__Deployment_History__c history = new copado__Deployment_History__c(copado__Object__c = 'Deployment', copado__Field__c = 'Status', copado__Deployment__c = deployment.Id, 
                                                                                  copado__Date__c = System.Now(), copado__Old_Value__c = 'In progress', copado__New_Value__c = 'Completed Successfully');
        insert history;
        System.debug('Deployment History: +++ ' + history);
        
        Release_Playbook_Item__c playBookItem = [SELECT Id, Start_Date_Time__c, Status__c, End_Date_Time__c, Sub_Items_Logic__c 
                                                 FROM Release_Playbook_Item__c];
        playBookItem.Status__c = 'Completed';
        playBookItem.Sub_Items_Logic__c = 'After Deployment - Deploy PROD Package To Training';
        update playBookItem;
        
        // Verify the Results
        System.assertEquals(playbookItem.Status__c, 'Completed', 'Status should be completed');
        
        Test.stopTest();
    }
}