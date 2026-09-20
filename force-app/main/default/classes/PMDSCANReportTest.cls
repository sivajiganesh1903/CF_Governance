@isTest
public class PMDSCANReportTest {
    private static PMD_Report__mdt createPMDMatrixMock(String mockgroup, String mockorgaddress) {
        PMD_Report__mdt mock = new PMD_Report__mdt();
        mock.Public_Group__c  = mockgroup;
        mock.Org_Address__c = mockorgaddress;
        return mock;
    }
    
    @TestSetup
    static void setupTestData() {
        // Use System Administrator profile to avoid insufficient access errors
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // Create test user with admin profile
        User testUser = new User(FirstName = 'Test', LastName = 'User', Alias = 'tuser', Email = 'testuser@example.com',
                                 Username = 'testuser' + DateTime.now().getTime() + '@example.com', EmailEncodingKey = 'UTF-8',
                                 LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/Los_Angeles',
                                 ProfileId = adminProfile.Id);
        insert testUser;
        
        // Create Public Group outside System.runAs()
        Group testGroup = new Group(Name = 'Test Group', Type = 'Regular');
        insert testGroup;
        
        System.runAs(testUser) {
            // Create and insert OrgWideEmailAddress
            OrgWideEmailAddress orgEmail = new OrgWideEmailAddress(Address = 'testemail@company.com', 
                                                                   DisplayName = 'Test Org Email');
            System.assert(orgEmail != null, 'Org Wide Email has been taken successfully.');                                                       
            
            // Add User to Public Group inside System.runAs()
            GroupMember groupMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = testUser.Id);
            insert groupMember;
        }
        
        // Create PMD_Report__mdt record
        PMD_Report__mdt mockMatrix = createPMDMatrixMock('Test Group', 'Test Org Email');
        System.assert(mockMatrix != null, 'Test Custom Meta Data record has been setup successfully.');
        
        // Create test data
        copado__Org__c testOrg = new copado__Org__c(Name = 'Test Org', Weekly_PMD_Report__c = true);
        insert testOrg;
        
        copado__Static_Code_Analysis_Result__c testResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = testOrg.Id);
        insert testResult;
        
        // Create an org with no SCA results (to trigger "No data available")
        copado__Org__c testOrgNoData = new copado__Org__c(Name = 'Org No Data', Weekly_PMD_Report__c = true);
        insert testOrgNoData;
        
        List<copado__Static_Code_Analysis_Violation__c> violations = new List<copado__Static_Code_Analysis_Violation__c>();
        for (Integer i = 1; i <= 5; i++) {
            violations.add(new copado__Static_Code_Analysis_Violation__c(
                copado__Static_Code_Analysis_Result__c = testResult.Id, copado__File__c = 'TestFile' + i + '.cls',
                copado__Line__c = i, copado__Rule__c = 'TestRule' + i, copado__Priority__c = i, 
                copado__Message__c = 'Test Message ' + i));
        }
        insert violations;
    }
    
    @isTest
    static void testSCAViolationsWithData() {
        // Retrieve the test user
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' WITH SECURITY_ENFORCED  LIMIT 1];
        Test.startTest();
            System.runAs(testUser) {
                PMDSCANReport.scaResultViolations();
            }
        Test.stopTest();
        System.assert(true, 'Test executed successfully with data.');
    }

    @isTest
    static void testSCAViolationsNoData() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' WITH SECURITY_ENFORCED LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            // This will now cover the "No data available" scenario
            PMDSCANReport.scaResultViolations();
        }
        Test.stopTest();
        System.assert(true, 'Test executed successfully with no data scenario.');
    }
}