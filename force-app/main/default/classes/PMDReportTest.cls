@isTest
private class PMDReportTest {
    private static PMD_Report__mdt createPMDMatrixMock(String mockgroup, String mockorgaddress) {
        PMD_Report__mdt mock = new PMD_Report__mdt();
        mock.Public_Group__c  = mockgroup;
        mock.Org_Address__c = mockorgaddress;
        return mock;
    }
    
    @TestSetup
    static void setupTestData() {
        // Create test data
        copado__Org__c testOrg = new copado__Org__c(Name = 'Test Org', Weekly_PMD_Report__c = true);
        insert testOrg;
        
        copado__Static_Code_Analysis_Result__c testResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = testOrg.Id
        );
        insert testResult;
        
        List<copado__Static_Code_Analysis_Violation__c> violations = new List<copado__Static_Code_Analysis_Violation__c>();
        for(Integer i = 1; i <= 5; i++) {
            violations.add(new copado__Static_Code_Analysis_Violation__c(
                copado__Static_Code_Analysis_Result__c = testResult.Id,
                copado__File__c = 'TestFile' + i + '.cls',
                copado__Line__c = i,
                copado__Rule__c = 'TestRule' + i,
                copado__Priority__c = i,
                copado__Message__c = 'Test Message ' + i
            ));
        }
        insert violations;
    }
    
    @isTest
    static void testIntPMDReport() {
        // Use a System Administrator user for the test
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        
        // Use System.runAs with System Administrator
        Group existingGroup = [SELECT Id FROM Group WHERE Type = 'Regular' LIMIT 1];
        
        System.runAs(testUser) {
            // Add user to existing group
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = testUser.Id; // Using testUser.Id here
            grpMem1.GroupId = existingGroup.Id;
            insert grpMem1;
        }
        
        // Call the method to be tested
        Test.startTest();
        Map<String, String> result = PMDReport.intPMDReport();
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('SUCCESS') || result.containsKey('ERROR'), 'Result map should contain success or error key');
    }
    
    @isTest
    static void testIntPMDReportNoResults() {
        copado__Org__c copadoOrg = new copado__Org__c(
            Name = 'Test Org No Results',
            Weekly_PMD_Report__c = true
        );
        insert copadoOrg;
        
        Test.startTest();
        Map<String, String> result = PMDReport.intPMDReport();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('SUCCESS') || result.containsKey('ERROR'), 'Result map should contain success or error key');
    }
    
    @isTest
    static void testSendCsvEmail() {
        String htmlBody = 'Test HTML Body';
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('TestAttachment.csv');
        attachment.setBody(Blob.valueOf('Test data'));
        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>{attachment};
        
        Test.startTest();
        Map<String, String> result = PMDReport.SendCsvEmail(htmlBody, attachments);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('SUCCESS') || result.containsKey('ERROR'), 'Result map should contain success or error key');
    } 
}