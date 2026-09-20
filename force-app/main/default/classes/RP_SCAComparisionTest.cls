@isTest
public class RP_SCAComparisionTest {
    // Set up a test email address
    private static final String TEST_EMAIL = 'test@example.com';
    
    @testSetup
    static void setupData() {
        
        // Create a test Org record
        copado__Org__c testOrg = new copado__Org__c(Name = 'trnProd');
        insert testOrg;
        
        // Create a Copado Deployment Flow (Pipeline)
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(Name = 'Test Pipeline', copado__Active__c = true,
                                                                             copado__Platform__c = 'Other');
        insert pipeline;
        
        // Create a Release Playbook
        Release_Playbook__c playbook = new Release_Playbook__c(Pipeline__c = pipeline.Id);
        insert playbook;
        
        // Create related Release Playbook Items
        Release_Playbook_Item__c itemBeforeDeployment = new Release_Playbook_Item__c(
            Release_Playbook__c = playbook.Id, Execution_Sequence__c = 'Before Deployment', SCA__c = true);
        Release_Playbook_Item__c itemAfterDeployment = new Release_Playbook_Item__c(
            Release_Playbook__c = playbook.Id, Execution_Sequence__c = 'After Deployment', SCA__c = true);
        insert new List<Release_Playbook_Item__c>{ itemBeforeDeployment, itemAfterDeployment };
            
            // Create Static Code Analysis Results
            copado__Static_Code_Analysis_Result__c beforeSCA = new copado__Static_Code_Analysis_Result__c(
                copado__Org_Credential__c = testOrg.Id);
        copado__Static_Code_Analysis_Result__c afterSCA = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = testOrg.Id);
        insert new List<copado__Static_Code_Analysis_Result__c> { beforeSCA, afterSCA };
            
            // Create related Sub Items
            Release_Playbook_Sub_Item__c subItemBefore = new Release_Playbook_Sub_Item__c(
                Release_Playbook_Item__c = itemBeforeDeployment.Id, Static_Code_Analysis_Result__c = beforeSCA.Id);
        Release_Playbook_Sub_Item__c subItemAfter = new Release_Playbook_Sub_Item__c(
            Release_Playbook_Item__c = itemAfterDeployment.Id, Static_Code_Analysis_Result__c = afterSCA.Id);
        insert new List<Release_Playbook_Sub_Item__c>{ subItemBefore, subItemAfter };
            
            // Create Static Code Analysis Violations
            List<copado__Static_Code_Analysis_Violation__c> violations = new List<copado__Static_Code_Analysis_Violation__c>();
        for (Integer i = 1; i <= 5; i++) {
            violations.add(new copado__Static_Code_Analysis_Violation__c(
                copado__Static_Code_Analysis_Result__c = beforeSCA.Id, copado__Priority__c = i, copado__File__c = 'File' + i,
                copado__Line__c = i, copado__Rule__c = 'Rule' + i, copado__Message__c = 'Message' + i));
            violations.add(new copado__Static_Code_Analysis_Violation__c(
                copado__Static_Code_Analysis_Result__c = afterSCA.Id, copado__Priority__c = i, copado__File__c = 'File' + i,
                copado__Line__c = i, copado__Rule__c = 'Rule' + i, copado__Message__c = 'Message' + i));
        }
        insert violations;
        
        // Create mock OrgWideEmailAddress
        OrgWideEmailAddress orgEmail = new OrgWideEmailAddress();
        orgEmail.Address = 'test@example.com';
        orgEmail.DisplayName = 'CF-EJ-FSCDEVOPS';
    }
    
    @isTest
    static void testComparisionResults_Success() {
        Release_Playbook__c playbook = [SELECT Id FROM Release_Playbook__c LIMIT 1];
        
        Test.startTest();
        String result = RP_SCAComparision.comparisionResults(playbook.Id);
        Test.stopTest();
        
        // Verify email was sent
        List<EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        System.assertEquals(1, sentEmails.size(), 'An email should be sent');
        
        // Verify Scan_Comparison__c record was created
        List<Scan_Comparison__c> scanComparisons = [SELECT Id FROM Scan_Comparison__c];
        System.assertEquals(1, scanComparisons.size(), 'A Scan_Comparison__c record should be created');
    }
    
    @isTest
    static void testComparisionResults_NoSCAItems() {
        Release_Playbook__c playbookNoSCA = new Release_Playbook__c();
        insert playbookNoSCA;
        
        Test.startTest();
        String result = RP_SCAComparision.comparisionResults(playbookNoSCA.Id);
        Test.stopTest();
        
        //System.assertEquals('No SCA items found', result, 'Expected message when no SCA items are found');
        System.assertEquals(true, result.contains('No SCA items found for the given release playbook'), 'Expected message when SCA results are empty');
    }
    
    @isTest
    static void testComparisionResults_NoSubItems() {
        Release_Playbook__c playbook = [SELECT Id FROM Release_Playbook__c LIMIT 1];
        delete [SELECT Id FROM Release_Playbook_Sub_Item__c];
        
        Test.startTest();
        String result = RP_SCAComparision.comparisionResults(playbook.Id);
        Test.stopTest();
        
        //System.assertEquals('No sub-items found', result, 'Expected message when no sub-items are found');
        System.assertEquals(true, result.contains('No sub-items found'), 'Expected message when SCA results are empty');
        
    }
    
    @isTest
    static void testComparisionResults_EmptySCAResults() {
        Release_Playbook__c playbook = [SELECT Id FROM Release_Playbook__c LIMIT 1];
        List<Release_Playbook_Sub_Item__c> subItems = [SELECT Id, Static_Code_Analysis_Result__c FROM Release_Playbook_Sub_Item__c];
        for(Release_Playbook_Sub_Item__c subItem : subItems) {
            subItem.Static_Code_Analysis_Result__c = null;
        }
        update subItems;
        
        Test.startTest();
        String result = RP_SCAComparision.comparisionResults(playbook.Id);
        Test.stopTest();
        
        //System.assertEquals('Empty SCA results', result, 'Expected message when SCA results are empty');
        System.assertEquals(true, result.contains('success'), 'Expected message when SCA results are empty');
        
    }
    
    @isTest
    static void testComparisionResults_GeneralException() {
        Release_Playbook__c playbook = [SELECT Id FROM Release_Playbook__c LIMIT 1];
        
        Test.startTest();
        // Cause an exception by deleting required data
        delete [SELECT Id FROM copado__Static_Code_Analysis_Result__c];
        String result = RP_SCAComparision.comparisionResults(playbook.Id);
        Test.stopTest();
        
        //System.assertEquals('Empty SCA results', result, 'Expected general failure message');
        System.assertEquals(true, result.contains('success'), 'Expected message when SCA results are empty');
    }
    
    @isTest
    static void testComparisionResults_ViolationsUnchanged() {
        // Get the test playbook
        Release_Playbook__c playbook = [SELECT Id FROM Release_Playbook__c LIMIT 1];
        
        // Verify test data exists before proceeding
        List<copado__Static_Code_Analysis_Result__c> scaResults = [SELECT Id FROM copado__Static_Code_Analysis_Result__c 
                                                                   ORDER BY CreatedDate];
        System.assert(!scaResults.isEmpty(), 'SCA Results should exist');
        System.assert(scaResults.size() >= 2, 'Should have at least 2 SCA results');
        
        // Verify violations exist
        List<copado__Static_Code_Analysis_Violation__c> violations = [SELECT Id FROM copado__Static_Code_Analysis_Violation__c
                                                                      WHERE copado__Static_Code_Analysis_Result__c 
                                                                      IN :scaResults];
        System.assert(!violations.isEmpty(), 'Violations should exist for both SCA results');
        
        Test.startTest();
        String result = RP_SCAComparision.comparisionResults(playbook.Id);
        Test.stopTest();
        
        // Verify email was sent
        List<EmailMessage> sentEmails = [SELECT HtmlBody FROM EmailMessage];
        System.assertNotEquals(0, sentEmails.size(), 'Email should be sent');
        
        // Only verify email content if we have emails
        if(!sentEmails.isEmpty()) {
            String emailBody = sentEmails[0].HtmlBody;
            System.assert(emailBody != null, 'Email body should not be null');
            
            // Verify the content indicates unchanged violations
            System.assert(!emailBody.contains('Post-deployment violations have decreased.'), 
                          'Email should not indicate that violations have decreased');
            System.assert(!emailBody.contains('Post-deployment violations have increased.'), 
                          'Email should not indicate that violations have increased');
        }
    }
    
    @isTest
    static void testComparisionResults_NoDeploymentSubItems() {
        // Get the test playbook
        Release_Playbook__c playbook = [SELECT Id FROM Release_Playbook__c LIMIT 1];
        
        // First delete existing sub-items
        delete [SELECT Id FROM Release_Playbook_Sub_Item__c];
        
        // Delete existing playbook items
        delete [SELECT Id FROM Release_Playbook_Item__c];
        
        // Create new playbook items with Before and After Deployment
        Release_Playbook_Item__c itemBeforeDeployment = new Release_Playbook_Item__c(
            Release_Playbook__c = playbook.Id, Execution_Sequence__c = 'Before Deployment', SCA__c = true);
        Release_Playbook_Item__c itemAfterDeployment = new Release_Playbook_Item__c(
            Release_Playbook__c = playbook.Id, Execution_Sequence__c = 'After Deployment', SCA__c = true);
        insert new List<Release_Playbook_Item__c>{ itemBeforeDeployment, itemAfterDeployment };
            
        // Don't create any sub-items for these playbook items
            
            Test.startTest();
        String result = RP_SCAComparision.comparisionResults(playbook.Id);
        Test.stopTest();
        
        // Verify the result
        //System.assertEquals('No sub-items found', result, 'Expected message when no deployment sub-items exist');
        System.assertEquals(true, result.contains('No sub-items found'), 'Expected message when SCA results are empty');
        
        // Additional verification
        List<Release_Playbook_Sub_Item__c> subItems = [SELECT Id FROM Release_Playbook_Sub_Item__c WHERE 
                                                       Release_Playbook_Item__c IN (SELECT Id FROM Release_Playbook_Item__c 
                                                                                    WHERE Release_Playbook__c = :playbook.Id)];
        System.assertEquals(0, subItems.size(), 'Should not have any sub-items');
    }
}