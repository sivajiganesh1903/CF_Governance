@Istest
public class PMDReport1Test {
    private class PMDReportMock implements HttpCalloutMock {
        /**
* @description This method handles the mock HTTP callout and returns a response with status code 204.
* @param req The HTTP request object.
* @return HttpResponse with status code 204.
*/
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"priority":"P1","violationCount":5}]');
            return res;
        }
    }
    @TestSetup
    static void setupTestData() {
        // Create System Administrator Test User
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User testUser = new User(
            Alias = 'usrdemo1',
            Email = 'testuser009@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Userdemo',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'githubactionspmdtestuser009@example.com'
        );
        insert testUser;
        // Create test data
        copado__Org__c testOrg = new copado__Org__c(Name = 'Test Org', Weekly_PMD_Report__c = true);
        insert testOrg;
        
        copado__Static_Code_Analysis_Result__c testResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = testOrg.Id
        );
        insert testResult;
        
        List<copado__Static_Code_Analysis_Violation__c> violations = new List<copado__Static_Code_Analysis_Violation__c>();
        for (Integer i = 1; i <= 5; i++) {
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
    static void testOrgScan() {
        // Fetch the created test user
        User testUser = [SELECT Id FROM User WHERE Username = 'githubactionspmdtestuser009@example.com' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            // Set mock callout
            Test.setMock(HttpCalloutMock.class, new PMDReportMock());        
            PMDReport1.orgscan();
            Test.stopTest();
            // Validate that the expected data is present
            Integer countViolations = [SELECT COUNT() FROM copado__Static_Code_Analysis_Violation__c];
            System.assertEquals(5, countViolations, 'Expected 5 violations to be present.');
        }
    }
    
    @isTest
    public static void testPMDReportScheduler() {
        // Fetch the created test user
        User testUser = [SELECT Id FROM User WHERE Username = 'githubactionspmdtestuser009@example.com' LIMIT 1];
        Test.startTest();
        System.runAs(testUser) { 
            // Set the mock callout before scheduling
            Test.setMock(HttpCalloutMock.class, new PMDReportMock());
            // Schedule the job
            String jobId = System.schedule('Test SCAScheduler', '0 0 0 * * ? *', new PMDReportScheduler());
            System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
            Test.stopTest();           
        }
    }
}