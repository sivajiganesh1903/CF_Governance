@isTest
public class PMDViolationsTest {

    @testSetup
    static void setupTestData() {
        // Create a copado Org record
        copado__Org__c org = new copado__Org__c(Name = 'Eric Varela TrnProd2');
        insert org;

        // Create Static Code Analysis Results (before and after deployment)
        copado__Static_Code_Analysis_Result__c beforeResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = org.Id
        );
        copado__Static_Code_Analysis_Result__c afterResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = org.Id
        );
        insert new List<copado__Static_Code_Analysis_Result__c> { beforeResult, afterResult };

        // Scenario 1: Violation decreased
        copado__Static_Code_Analysis_Violation__c beforeViolation1 = new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = beforeResult.Id, copado__File__c = 'FileA', copado__Line__c = 10,
            copado__Rule__c = 'Rule1', copado__Priority__c = 1, copado__Message__c = 'Before violation - High Priority'
        );
        copado__Static_Code_Analysis_Violation__c afterViolation1 = new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = afterResult.Id, copado__File__c = 'FileA', copado__Line__c = 10,
            copado__Rule__c = 'Rule1', copado__Priority__c = 3, copado__Message__c = 'After violation - Low Priority'
        );

        // Scenario 2: Violation increased
        copado__Static_Code_Analysis_Violation__c beforeViolation2 = new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = beforeResult.Id, copado__File__c = 'FileB', copado__Line__c = 15,
            copado__Rule__c = 'Rule2', copado__Priority__c = 3, copado__Message__c = 'Before violation - Low Priority'
        );
        copado__Static_Code_Analysis_Violation__c afterViolation2 = new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = afterResult.Id, copado__File__c = 'FileB', copado__Line__c = 15,
            copado__Rule__c = 'Rule2', copado__Priority__c = 1, copado__Message__c = 'After violation - High Priority'
        );
        
        // Scenario 3: No change in Violation
        copado__Static_Code_Analysis_Violation__c beforeViolation3 = new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = beforeResult.Id, copado__File__c = 'FileB', copado__Line__c = 15,
            copado__Rule__c = 'Rule2', copado__Priority__c = 3, copado__Message__c = 'Before violation - No Change'
        );
        copado__Static_Code_Analysis_Violation__c afterViolation3 = new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = afterResult.Id, copado__File__c = 'FileB', copado__Line__c = 15,
            copado__Rule__c = 'Rule2', copado__Priority__c = 3, copado__Message__c = 'After violation - No Change'
        );

        insert new List<copado__Static_Code_Analysis_Violation__c> { beforeViolation1, afterViolation1, beforeViolation2, afterViolation2,beforeViolation3, afterViolation3 };

        // Create mock OrgWideEmailAddress
        OrgWideEmailAddress orgEmail = new OrgWideEmailAddress();
        orgEmail.Address = 'test@example.com';
        orgEmail.DisplayName = 'CF-EJ-FSCDEVOPS';

        // Create mock PMD_Report__mdt records
        PMD_Report__mdt mockReport = new PMD_Report__mdt();
        mockReport.Org_Address__c = orgEmail.Address; // Set the Org Address
        mockReport.Email_Address__c = 'test@example.com'; // Use the same address
        // Note: Do not insert OrgWideEmailAddress and PMD_Report__mdt in test, it should exist in org
    }

    @isTest
    static void testCredRelatedViolations() {
        Test.startTest();

        // Call the method being tested
        PMDViolations.credRelatedViolations();

        Test.stopTest();

        // Assert that the email has been sent by querying the EmailMessage object
        List<EmailMessage> sentEmails = [SELECT Subject, HtmlBody FROM EmailMessage];
        System.assertEquals(1, sentEmails.size(), 'An email should be sent');

     /*   // Check for messages indicating the change in violations
        System.assert(sentEmails[0].HtmlBody.contains('Post-deployment violations have decreased.'), 
            'Email should indicate that violations have decreased');
        System.assert(sentEmails[0].HtmlBody.contains('Post-deployment violations have increased.'), 
            'Email should indicate that violations have increased');   */
    }
}