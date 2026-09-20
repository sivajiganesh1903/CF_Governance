@IsTest
public class PMDViolationsReportTest {
    // Helper method to simulate Custom Metadata record
    private static PMD_Report__mdt createPMDMatrixMock(String mockgroup, String mockorgaddress) {
        PMD_Report__mdt mock = new PMD_Report__mdt();
        mock.Public_Group__c  = mockgroup;
        mock.Org_Address__c = mockorgaddress;
        return mock;
    } 
    // Helper method to simulate OrgWideEmailAddress record
    private static void createOrgWideEmail() {
        OrgWideEmailAddress owe = new OrgWideEmailAddress(DisplayName = 'Test Org Email', Address = 'testorg@example.com');
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
        for(Integer i = 1; i <= 29; i++) {
            violations.add(new copado__Static_Code_Analysis_Violation__c(
                copado__Static_Code_Analysis_Result__c = testResult.Id, copado__File__c = 'TestFile' + i + '.cls',
                copado__Line__c = i, copado__Rule__c = 'TestRule' + i, copado__Priority__c = i,
                copado__Message__c = 'Test Message ' + i));
        }
        insert violations;
    }
    @isTest
    static void testBatchExecutionWithResults() {
        Test.startTest();
        PMDViolationsReport batch = new PMDViolationsReport();
        Id jobId = Database.executeBatch(batch, 200);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Batch Job should be scheduled');
    }
}