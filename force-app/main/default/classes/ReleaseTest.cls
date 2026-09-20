@IsTest
public class ReleaseTest {
    @TestSetup
    public static void setupTestData() {
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
        
        // Create Release Playbook Item
        Release_Playbook_Item__c playBookItem = new Release_Playbook_Item__c(Release_Playbook__c = playbook.Id,
                                                                             Status__c = 'Not Started', Order__c = 2);
        insert playBookItem;
        
        // Create Environments
        copado__Environment__c sourceEnv = new copado__Environment__c(Name = 'TEST_DEV1', copado__Type__c = 'Sandbox',
                                                                      Type__c = 'DEV', copado__Platform__c = 'Salesforce');
        insert sourceEnv;
        
        copado__Environment__c destEnv = new copado__Environment__c(Name = 'TEST_QA1', copado__Type__c = 'Sandbox',
                                                                    Type__c = 'DEV', copado__Platform__c = 'Salesforce');
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
        copado__Promotion__c promotion = new copado__Promotion__c(copado__Source_Environment__c = sourceEnv.Id, 
                                                                  copado__Destination_Environment__c = destEnv.Id, copado__Project__c = project.Id, 
                                                                  OwnerId = UL.userId);
        insert promotion; 
        system.debug('promotion Object Data: ----->>> ' + promotion);
        
        // Create deployment first
        copado__Deployment__c deployment = new copado__Deployment__c(Name = 'Test Deployment', copado__From_Org__c = sourceCredential.Id,
                                                                     copado__Promotion__c = promotion.Id, copado__Status__c = 'Completed Successfully');
        insert deployment;        
        system.debug('deployment Object Data: ------>> ' + deployment);
        
        // Create step and associate it with deployment
        copado__Step__c step = new copado__Step__c(copado__Deployment__c = deployment.Id, copado__Type__c = 'Validation',
                                                   copado__Status__c = 'Completed Successfully', copado__CheckOnly__c = true, copado__Order__c = 1);
        insert step;
        System.debug('Copado Steps: ------> ' + step);
        
        // Create Release Playbook Sub Item
        Release_Playbook_Sub_Item__c subItem = new Release_Playbook_Sub_Item__c(Release_Playbook_Item__c = playBookItem.Id,
                                                                                Promotion__c = promotion.Id);
        insert subItem;
        
        //Latest Promotion
        copado__Promotion__c updatedPromotion = new copado__Promotion__c(copado__Source_Environment__c = sourceEnv.Id, 
                                                                         copado__Destination_Environment__c = destEnv.Id, 
                                                                         copado__Connection_Behavior__c = 'TestBehavoiur', 
                                                                         copado__Project__c = project.Id, OwnerId = UL.userId);
        insert updatedPromotion;
        system.debug('Latest Promotion: ------->> ' + deployment);
        
        // Create deployment first
        copado__Deployment__c updateDeploy = new copado__Deployment__c(Name = 'Test Deployment-1', copado__From_Org__c = sourceCredential.Id,
                                                                       copado__Promotion__c = updatedPromotion.Id, copado__Status__c = 'Completed Successfully');
        insert updateDeploy;       
        system.debug('Latest deployment: ---------->> ' + updateDeploy);
        
        // Create step and associate it with deployment
        copado__Step__c updatestep = new copado__Step__c(copado__Deployment__c = updateDeploy.Id, copado__Type__c = 'Validation',
                                                   copado__Status__c = 'Completed Successfully', copado__CheckOnly__c = true, copado__Order__c = 1);
        insert updatestep;
        system.debug('Latest Step: ---------->> ' + updatestep);
        
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
        System.debug('Deplyment Records: +++++' + verifyDeployments);
        System.assertEquals(1, verifyDeployments.size(), 'Deployment should be associated with Promotion');
        
    }
    
    
    //     ----------------------     Order - 2   -----------------------------
    
    @IsTest
    static void testProcessReleasePlaybookSubItem2_Success() {
        
        Release_Playbook_Sub_Item__c subItem = [SELECT Id, Promotion__c, Release_Playbook_Item__c, Release_Playbook_Item__r.Order__c
                                                FROM Release_Playbook_Sub_Item__c WHERE Release_Playbook_Item__r.Order__c = 2 LIMIT 1];
        System.debug('SubItem Promotion: ------>> ' + subItem.Promotion__c);
        
        copado__Promotion__c cp = [SELECT Id, copado__Connection_Behavior__c FROM copado__Promotion__c WHERE copado__Connection_Behavior__c = 'TestBehavoiur'];
        System.debug('Update SubItem Promotion: ------>> ' + cp.copado__Connection_Behavior__c);
        
        Release_Playbook_Sub_Item__c si = [select Id, Name, Promotion__c FROM Release_Playbook_Sub_Item__c WHERE 
                                           Id = :subItem.Id ];
        si.Promotion__c = cp.id;
        update si;
        System.debug('Changed Promtion : ------->' + si.Promotion__c);
        
        Release_Playbook_Item__c playBookItem = [SELECT Id FROM Release_Playbook_Item__c WHERE Id = :subItem.Release_Playbook_Item__c];
        System.debug('SubItem Release Play Book: ------>> ' + subItem.Release_Playbook_Item__c);
        
        copado__Promotion__c promotion = [SELECT Id, CreatedDate FROM copado__Promotion__c WHERE Id = :subItem.Promotion__c];
        System.debug('Promotion Id' + promotion.Id);
        
       /* Release_Playbook_Item__c playBookItem = [SELECT Id FROM Release_Playbook_Item__c WHERE Id = :subItem.Release_Playbook_Item__c];
        System.debug('SubItem Release Play Book: ------>> ' + subItem.Release_Playbook_Item__c);
        
        copado__Promotion__c promotion = [SELECT Id, CreatedDate FROM copado__Promotion__c WHERE Id = :subItem.Promotion__c];
        System.debug('Promotion Id' + promotion.Id);
        
        copado__Deployment__c deployment = [SELECT Id, copado__From_Org__c, copado__Promotion__c, copado__Status__c FROM 
                                            copado__Deployment__c WHERE copado__Promotion__c =: subItem.Promotion__c And copado__Status__c = 'Completed Successfully'];
        System.debug('Deployment Id' + Deployment.Id);
        
        copado__Step__c  step = [SELECT Id, copado__Deployment__c, copado__Type__c, copado__Status__c, copado__CheckOnly__c, 
                                 copado__Order__c FROM copado__Step__c WHERE copado__Deployment__c = :deployment.Id AND copado__Status__c = 'Completed Successfully'];
        System.debug('Step Id : -------->>> ' + step); */
        
        System.assertNotEquals(null, subItem.Promotion__c, 'Sub Item must have a Promotion.');
        
        System.assertNotEquals(null, playBookItem.Id, 'Playbook Item must exist.');
        system.debug('SubItemId In Test Class----->>>'+subItem.Id);
        
        // Verify the results
        Release_Playbook_Item__c updatedItem = [SELECT Id, Start_Date_Time__c, End_Date_Time__c FROM Release_Playbook_Item__c
                                                WHERE Id = :playBookItem.Id];
        System.assertNotEquals(System.now(), updatedItem.Start_Date_Time__c, 'Start Date should be updated.');
        System.assertNotEquals(System.now(), updatedItem.End_Date_Time__c, 'End Date should be updated.');
    }
    
}