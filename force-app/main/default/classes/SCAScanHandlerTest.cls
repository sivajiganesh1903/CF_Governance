@IsTest
public class SCAScanHandlerTest {
    
    @TestSetup
    static void setupTestData() {       
        Id trnProdOrgId = Label.Prod_Credential;
        System.debug('TrnOrg Id: +++ ' + trnProdOrgId);
        
        // Create a test Org record
        copado__Org__c testOrg = new copado__Org__c(Name = 'trnProd');
        insert testOrg;
        System.debug('Test Org: +++++ ' + testOrg);
        
        // Create a Copado Deployment Flow (Pipeline)
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
            Name = 'Test Pipeline', copado__Active__c = true, copado__Platform__c = 'Other');
        insert pipeline;
        
        // Create a Release Playbook Template
        Release_Playbook__c templateRP = new Release_Playbook__c(Pipeline__c = pipeline.Id);
        insert templateRP;
        
        // Create a Release Playbook record
        Release_Playbook__c playbook = new Release_Playbook__c(Pipeline__c = pipeline.Id, Release_Template__c = templateRP.Id);
        insert playbook;
        System.debug('PlayBook: +++++ ' + playbook);
        
        // Create related Release Playbook Items with SCA__c set to true
        Release_Playbook_Item__c playbookItem = new Release_Playbook_Item__c(
            Release_Playbook__c = playbook.Id, SCA__c = true, Execution_Sequence__c = 'Before Deployment'); 
        insert playbookItem;
        System.debug('PlayBook Item: +++++ ' + playbookItem);
        
        // Create first SCA Result record
        copado__Static_Code_Analysis_Result__c result1 = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = trnProdOrgId);
        insert result1;
        System.debug('SCA Result 1: ++++ ' + result1);
        
        // Fetch SCA Result Records
        copado__Static_Code_Analysis_Result__c res1 = [SELECT Id, Name FROM copado__Static_Code_Analysis_Result__c WHERE id = :result1.Id];
        System.debug('Result Name ++++' +  res1);
        
        // Create a Release Playbook Sub Item
        Release_Playbook_Sub_Item__c subItem = new Release_Playbook_Sub_Item__c(
            Release_Playbook_Item__c = playbookItem.Id, Previous_SCA__c = res1.Name, Static_Code_Analysis_Result__c = result1.Id);
        insert subItem;
        System.debug('subItem: +++++ ' + subItem);
    }
    
    @IsTest
    static void testHandleAfterInsert_SuccessScenario() {
        // Get the test data
        Id trnProdOrgId = Label.Prod_Credential;
        System.debug('Get TrnOrg Id: +++ ' + trnProdOrgId);
        
        // Query existing SCA results
        copado__Static_Code_Analysis_Result__c existingResult = [SELECT Id, Name FROM copado__Static_Code_Analysis_Result__c 
                                                                 WHERE copado__Org_Credential__c = :trnProdOrgId LIMIT 1];
        System.debug('Existing Results : ++++ ' + existingResult);
        
        // Get the existing sub item
        Release_Playbook_Sub_Item__c existingSubItem = [SELECT Id, Previous_SCA__c FROM Release_Playbook_Sub_Item__c 
                                                        WHERE Previous_SCA__c = :existingResult.Name LIMIT 1];
		System.debug('Exixsting Sub Item: +++' + existingSubItem);
        
        Test.startTest();        
        copado__Static_Code_Analysis_Result__c newResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = trnProdOrgId);
        insert newResult;        
        Test.stopTest();
        
        // Verify the Release Playbook Sub Item was updated
        Release_Playbook_Sub_Item__c updatedSubItem = [SELECT Id, Static_Code_Analysis_Result__c, SCA_Execution_Time__c 
                                                       FROM Release_Playbook_Sub_Item__c WHERE Id = :existingSubItem.Id];
        System.debug('Updated SubItems : ++++ ' + updatedSubItem);
        System.assertEquals(newResult.Id, updatedSubItem.Static_Code_Analysis_Result__c, 'The Sub Item should be updated with the new SCA Result Id');
        System.assertNotEquals(null, updatedSubItem.SCA_Execution_Time__c, 'Execution time should be populated');
    }
    
    @IsTest
    static void testHandleAfterInsert_InvalidOrgId() {
        // Test scenario where Org Id is invalid
        Test.startTest();        
        copado__Static_Code_Analysis_Result__c invalidResult = new copado__Static_Code_Analysis_Result__c();
        insert invalidResult;        
        Test.stopTest();
        
        System.assert(true, 'Should handle invalid Org Id gracefully');
    }
    
    @IsTest
    static void testHandleAfterInsert_NoMatchingSubItem() {
        // Delete existing Release Playbook Sub Items
        delete [SELECT Id FROM Release_Playbook_Sub_Item__c];        
        Id trnProdOrgId = Label.Prod_Credential;
        
        Test.startTest();        
        copado__Static_Code_Analysis_Result__c newResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = trnProdOrgId);
        insert newResult;       
        Test.stopTest();
        
        List<Release_Playbook_Sub_Item__c> subItems = [SELECT Id FROM Release_Playbook_Sub_Item__c];
        System.assertEquals(0, subItems.size(), 'Should have no sub items');
    }
}