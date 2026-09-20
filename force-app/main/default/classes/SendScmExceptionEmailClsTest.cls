@isTest
public class SendScmExceptionEmailClsTest {
    @isTest
    static void testSendExceptionEmail() {
        // Step 1: Create Test Data

        Profile p = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'unique_testuser_' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            ProfileId = p.Id
        );
        insert u;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Shared_Component_Matrix_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.id;
        psa.PermissionSetId = ps.id;
        insert psa;
        System.runAs(u){
        // Create a test user
        User reviewerUser = new User(
            FirstName = 'Alice',
            LastName = 'Smith',
            Alias = 'asmith',
            Email = 'reviewer@example.com',
            Username = 'reviewer@example.com' + System.currentTimeMillis(),
            CommunityNickname = 'asmith',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert reviewerUser;

        // Create the Reviewer object linked to the User
        Reviewer__c reviewer = new Reviewer__c(
            Reviewer_Name__c = reviewerUser.Id
        );
        insert reviewer;

        // Create the Exception record linked to the Reviewer
        SC_Matrix_Exception_Approval__c exceptions = new SC_Matrix_Exception_Approval__c(
            Reviewer__c = reviewer.Id
        );
        insert exceptions;

        // Create the Requested User Story
        copado__User_Story__c requestedUserStory = new copado__User_Story__c(
            copado__User_Story_Title__c = 'Requested User Story Exception'
        );
        insert requestedUserStory;

        // Step 2: Prepare the Exception Request Object
        List<SendScmExceptionEmailCls.SCMatrixExceptionRequest> requests = new List<SendScmExceptionEmailCls.SCMatrixExceptionRequest>();
        SendScmExceptionEmailCls.SCMatrixExceptionRequest request = new SendScmExceptionEmailCls.SCMatrixExceptionRequest();
        request.ReviewerEmail = reviewerUser.Email;
        request.ReviewerLastName = reviewerUser.LastName;
        request.ReviewerFirstName = reviewerUser.FirstName;
        request.RequestedUserStoryName = requestedUserStory.copado__User_Story_Title__c;
        request.RequestedUserStoryId = requestedUserStory.Id;
        requests.add(request);

        
        // Step 4: Call the Exception Method
        Test.startTest();
        SendScmExceptionEmailCls.sendExceptionEmail(requests);
        Test.stopTest();

        // Step 5: Assertions (Optional)
        // Validate the email details
        System.assertEquals(1, requests.size(), 'There should be one exception email request.');
        System.assertEquals('reviewer@example.com', requests[0].ReviewerEmail, 'Reviewer email should match.');
        System.assertEquals('Smith', requests[0].ReviewerLastName, 'Reviewer last name should match.');
        System.assertEquals('Alice', requests[0].ReviewerFirstName, 'Reviewer first name should match.');
        System.assertEquals(requestedUserStory.copado__User_Story_Title__c, requests[0].RequestedUserStoryName, 'User story name should match.');
        }
    }
}