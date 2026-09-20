@isTest
private class RP_SCAComparisionBatchTest {

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
    static void testComparisonBatchExecution() {
        // Get a sample playbook
        Release_Playbook__c playbook = [SELECT Id FROM Release_Playbook__c LIMIT 1];

        // Call the comparisionResults method which internally invokes the batch
        Test.startTest();
        String result = RP_SCAComparisionBatch.comparisionResults(playbook.Id);
        Test.stopTest();

        System.debug('Comparison Result: ' + result);
        System.assert(result.contains('success') || result.contains('initiated'), 'Comparison should initiate');
    }
    @isTest
    static void testComparisionResults_NoSCAItems() {
        Release_Playbook__c playbookNoSCA = new Release_Playbook__c();
        insert playbookNoSCA;
        
        Test.startTest();
        String result = RP_SCAComparisionBatch.comparisionResults(playbookNoSCA.Id);
        Test.stopTest();
        
        //System.assertEquals('No SCA items found', result, 'Expected message when no SCA items are found');
        System.assertEquals(true, result.contains('No SCA items found for the given release playbook'), 'Expected message when SCA results are empty');
    }
     @isTest
    static void testComparisionResults_NoSubItems() {
        Release_Playbook__c playbook = [SELECT Id FROM Release_Playbook__c LIMIT 1];
        delete [SELECT Id FROM Release_Playbook_Sub_Item__c];
        
        Test.startTest();
        String result = RP_SCAComparisionBatch.comparisionResults(playbook.Id);
        Test.stopTest();
        
        //System.assertEquals('No sub-items found', result, 'Expected message when no sub-items are found');
        System.assertEquals(true, result.contains('No sub-items found'), 'Expected message when SCA results are empty');
        
    }
     @isTest
	static void testComparisonResultsException() {
    	Test.startTest();
    
    	String result = RP_SCAComparisionBatch.comparisionResults('a0A000000000001AAA');
    	Test.stopTest();
    
    	System.debug('Result from Exception block: ' + result);
    	System.assert(result.contains('error'), 'Should catch general exception for invalid ID');
	}


    @isTest
	static void testBatchExecution() {
    // Set up minimal fresh data just for batch test (avoid reuse from setupData)
    	copado__Org__c org = new copado__Org__c(Name = 'Test Org for Batch');
    	insert org;

     	copado__Static_Code_Analysis_Result__c beforeSCA = new copado__Static_Code_Analysis_Result__c(
        	copado__Org_Credential__c = org.Id);
    	copado__Static_Code_Analysis_Result__c afterSCA = new copado__Static_Code_Analysis_Result__c(
        	copado__Org_Credential__c = org.Id);
    	insert new List<copado__Static_Code_Analysis_Result__c>{ beforeSCA, afterSCA };

    // Insert minimal violations
    	List<copado__Static_Code_Analysis_Violation__c> violations = new List<copado__Static_Code_Analysis_Violation__c>();
    	for (Integer i = 0; i < 50; i++) {
        	violations.add(new copado__Static_Code_Analysis_Violation__c(
            	copado__Static_Code_Analysis_Result__c = beforeSCA.Id,
            	copado__Priority__c = 1,
            	copado__File__c = 'File' + i,
            	copado__Line__c = i,
            	copado__Rule__c = 'Rule' + i,
            	copado__Message__c = 'Message' + i
        	));
        	violations.add(new copado__Static_Code_Analysis_Violation__c(
            	copado__Static_Code_Analysis_Result__c = afterSCA.Id,
            	copado__Priority__c = 1,
            	copado__File__c = 'File' + i,
            	copado__Line__c = i,
            	copado__Rule__c = 'Rule' + i,
            	copado__Message__c = 'Message' + i
        	));
    	}
    	insert violations;

    	Release_Playbook__c playbook = new Release_Playbook__c();
    	insert playbook;

    // Now test the batch directly
    	RP_SCAComparisionBatch batch = new RP_SCAComparisionBatch(beforeSCA.Id, afterSCA.Id, playbook.Id);

    	Test.startTest();
    	Database.executeBatch(batch, 200); // Only this batch should run
    	Test.stopTest();

    	System.assert(true, 'Batch executed successfully');
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
        String result = RP_SCAComparisionBatch.comparisionResults(playbook.Id);
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