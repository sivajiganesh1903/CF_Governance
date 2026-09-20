@isTest
public class ReleasePlaybookPromotionHandlerTest {

    @isTest
    static void testCreatePromotion_Success() {
        // Debugging
        System.debug('DEBUG: Starting testCreatePromotion_Success');

        // Create test data
        copado__Org__c orgCredential = new copado__Org__c(Name = 'FSC UAT');
        insert orgCredential;

        copado__Release__c piRelease = new copado__Release__c(
            Name = 'PI Release',
            Release_Playbook__c = 'TestPlaybookId',
            UAT_Deployment_Start_Date__c = Date.today().addDays(-10),
            Prod_Deployment_Date__c = Date.today().addDays(10),
            Preprod_Deployment_Date__c = Date.today().addDays(-5),
            Preprod_User_Story_End_Date__c = Date.today().addDays(-1),
            Production_Validation_Start_Time__c = Date.today()
        );
        insert piRelease;

        copado__User_Story__c userStory = new copado__User_Story__c(
            copado__Release__c = piRelease.Id,
            copado__Status__c = 'Verification Complete',
            copado__Org_Credential__c = orgCredential.Id
        );
        insert userStory;

        // Call the method
        Test.startTest();
        String result = ReleasePlaybookPromotionHandler.createPromotion(piRelease.Release_Playbook__c);
        Test.stopTest();

        // Assert the result
        System.assertEquals('Promotion created successfully with 1 User Stories.', result);

        // Verify promotion and junction records
        List<copado__Promotion__c> promotions = [SELECT Id FROM copado__Promotion__c];
        System.debug('DEBUG: Promotions created = ' + promotions.size());
        List<copado__Promoted_User_Story__c> links = [
            SELECT Id, copado__Promotion__c, copado__User_Story__c
            FROM copado__Promoted_User_Story__c
        ];
        System.assertEquals(1, promotions.size());
        System.assertEquals(1, links.size());
        System.assertEquals(userStory.Id, links[0].copado__User_Story__c);
    }

    // Add similar debug statements for other test methods...
}