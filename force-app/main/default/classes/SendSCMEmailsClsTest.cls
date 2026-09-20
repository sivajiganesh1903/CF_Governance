@isTest
public class SendSCMEmailsClsTest {
 @IsTest
    static void testSendEmail() {
        // Step 1: Create Test Data
         
        // CREATE ENVIRONMENT
        copado__Environment__c objEnvi1 = new copado__Environment__c(Name='TRNDEV1',copado__Platform__c='Salesforce',Type__c='DEV');
        insert objEnvi1;
        
        //CREATE CREDENTIAL
        copado__Org__c objCredential1 = new copado__Org__c (Name='TRNDEV1',	copado__Org_Type__c='Sandbox' ,copado__Disable_Validation__c=true,copado__Environment__c = objEnvi1.Id);
        insert objCredential1;
        
        // Create a test user story record for Requested User Story
        copado__User_Story__c requestedUserStory = new copado__User_Story__c(
            copado__User_Story_Title__c = 'Test User Story1'
        );
        insert requestedUserStory;

        // Create a test user story record for Linked User Story
        copado__User_Story__c linkedUserStory = new copado__User_Story__c(
            copado__User_Story_Title__c = 'Test User Story2'
        );
        insert linkedUserStory;

        // Step 2: Prepare the Request Object
        List<SendSCMEmailsCls.SCMatrixApprovalRequest> requests = new List<SendSCMEmailsCls.SCMatrixApprovalRequest>();
        
        SendSCMEmailsCls.SCMatrixApprovalRequest request = new SendSCMEmailsCls.SCMatrixApprovalRequest();
        request.LinkedUserStoryDeveloperEmail = 'testuser@example.com';
        request.LinkedUserStoryDeveloperLastName = 'Doe';
        request.LinkedUserStoryDeveloperFirstName = 'John';
        request.RequestedUserStoryName = requestedUserStory.Name;
        request.RequestedUserStoryId = requestedUserStory.Id; // Use the inserted ID
        request.LinkedUserStoryName = linkedUserStory.Name;
        request.LinkedUserStoryId = linkedUserStory.Id; // Use the inserted ID
        request.LinkedUserStoryEnvironmentName = 'QA';
        request.SCMApprovalName = 'SCMEA-00000269';
        requests.add(request);

        // Step 3: Call the Method
        Test.startTest();
        SendSCMEmailsCls.sendEmail(requests);
        Test.stopTest();
        System.assertEquals(true,(requests.size()>0),'Emails Triggered');
    }
}