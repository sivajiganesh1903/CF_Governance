@isTest
public class RenameBackPromotionDeploymentTest {

    @isTest
    static void testComputeDeploymentName_BackPromotion() {
        copado__Promotion__c promo = new copado__Promotion__c();
        promo.put('copado__Back_Promotion__c', true);
        copado__User_Story__c us = new copado__User_Story__c();
        us.put('copado__User_Story_Title__c', 'US_BACK');

        // Also exercise process(...) using injected maps and an in-memory deployment
        RenameBackPromotionDeploymentHandler.testPromotionMap = new Map<Id, copado__Promotion__c>{
            (Id) '069000000000000AAA' => promo
        };
        RenameBackPromotionDeploymentHandler.testPromotionToUserStoryMap = new Map<Id, copado__User_Story__c>{
            (Id) '069000000000000AAA' => us
        };

        List<copado__Deployment__c> inputs = new List<copado__Deployment__c>{ new copado__Deployment__c(copado__Promotion__c = (Id) '069000000000000AAA') };

        RenameBackPromotionDeploymentHandler.process(inputs);

        // Verify the handler captured the update and computed a name
        System.assertNotEquals(null, RenameBackPromotionDeploymentHandler.testCapturedUpdates, 'Handler should capture updates in test mode');
        System.assert(RenameBackPromotionDeploymentHandler.testCapturedUpdates.size() == 1, 'One update expected');
        String capturedName = RenameBackPromotionDeploymentHandler.testCapturedUpdates[0].Name;
        System.assert(capturedName != null && capturedName.startsWith('Backpromotion-') && capturedName.contains('US_BACK'), 'Captured name should include prefix and US title');
    }
    
    @isTest
    static void testComputeDeploymentName_NoBackPromotion() {
        copado__Promotion__c promo = new copado__Promotion__c();
        promo.put('copado__Back_Promotion__c', false);
        copado__User_Story__c us = new copado__User_Story__c();
        us.put('copado__User_Story_Title__c', 'US_FWD');

        // Inject maps and run process to verify no updates are captured
        RenameBackPromotionDeploymentHandler.testPromotionMap = new Map<Id, copado__Promotion__c>{ (Id) '069000000000000AAB' => promo };
        RenameBackPromotionDeploymentHandler.testPromotionToUserStoryMap = new Map<Id, copado__User_Story__c>{ (Id) '069000000000000AAB' => us };
        RenameBackPromotionDeploymentHandler.testCapturedUpdates = null;

        List<copado__Deployment__c> inputs = new List<copado__Deployment__c>{ new copado__Deployment__c(copado__Promotion__c = (Id) '069000000000000AAB') };
        RenameBackPromotionDeploymentHandler.process(inputs);

        System.assertEquals(null, RenameBackPromotionDeploymentHandler.testCapturedUpdates, 'No updates should be captured for non-back promotion');
    }

    @isTest
    static void testComputeDeploymentName_Nulls() {
        System.assertEquals(null, RenameBackPromotionDeploymentHandler.computeDeploymentName(null, null));
        copado__Promotion__c promo = new copado__Promotion__c();
        promo.put('copado__Back_Promotion__c', true);
        System.assertEquals(null, RenameBackPromotionDeploymentHandler.computeDeploymentName(promo, null));
    }

    @isTest
    static void testProcess_NoPromotionsInInput() {
        // No deployments or deployments with null promotion should be no-op
        RenameBackPromotionDeploymentHandler.testPromotionMap = null;
        RenameBackPromotionDeploymentHandler.testPromotionToUserStoryMap = null;
        RenameBackPromotionDeploymentHandler.testCapturedUpdates = null;

        List<copado__Deployment__c> inputs = new List<copado__Deployment__c>{ new copado__Deployment__c(), new copado__Deployment__c(copado__Promotion__c = null) };
        // Should not throw and should not capture any updates
        RenameBackPromotionDeploymentHandler.process(inputs);
        System.assertEquals(null, RenameBackPromotionDeploymentHandler.testCapturedUpdates, 'No updates should be captured when promotions are absent');
    }

    @isTest
    static void testProcess_EmptyUserStoryTitleProducesPrefixOnly() {
        copado__Promotion__c promo = new copado__Promotion__c();
        promo.put('copado__Back_Promotion__c', true);
        copado__User_Story__c us = new copado__User_Story__c();
        // no title set -> empty string fallback

        Id fakeId = (Id) '069000000000000AAC';
        RenameBackPromotionDeploymentHandler.testPromotionMap = new Map<Id, copado__Promotion__c>{ fakeId => promo };
        RenameBackPromotionDeploymentHandler.testPromotionToUserStoryMap = new Map<Id, copado__User_Story__c>{ fakeId => us };
        RenameBackPromotionDeploymentHandler.testCapturedUpdates = null;

        List<copado__Deployment__c> inputs = new List<copado__Deployment__c>{ new copado__Deployment__c(copado__Promotion__c = fakeId) };
        RenameBackPromotionDeploymentHandler.process(inputs);

        System.assertNotEquals(null, RenameBackPromotionDeploymentHandler.testCapturedUpdates, 'Updates should be captured for back promotion');
        String captured = RenameBackPromotionDeploymentHandler.testCapturedUpdates[0].Name;
        System.assert(captured.startsWith('Backpromotion-'), 'Captured name should have Backpromotion- prefix');
    }

    @isTest
    static void testProcess_MultipleDeploymentsAndPromotions() {
        // Two promotions, one back and one forward
        copado__Promotion__c pBack = new copado__Promotion__c(); pBack.put('copado__Back_Promotion__c', true);
        copado__Promotion__c pFwd = new copado__Promotion__c(); pFwd.put('copado__Back_Promotion__c', false);
        copado__User_Story__c usBack = new copado__User_Story__c(); usBack.put('copado__User_Story_Title__c', 'B1');
        copado__User_Story__c usFwd = new copado__User_Story__c(); usFwd.put('copado__User_Story_Title__c', 'F1');

        Id idBack = (Id) '069000000000000AAD';
        Id idFwd = (Id) '069000000000000AAE';

        RenameBackPromotionDeploymentHandler.testPromotionMap = new Map<Id, copado__Promotion__c>{ idBack => pBack, idFwd => pFwd };
        RenameBackPromotionDeploymentHandler.testPromotionToUserStoryMap = new Map<Id, copado__User_Story__c>{ idBack => usBack, idFwd => usFwd };
        RenameBackPromotionDeploymentHandler.testCapturedUpdates = null;

        List<copado__Deployment__c> inputs = new List<copado__Deployment__c>{ new copado__Deployment__c(copado__Promotion__c = idBack), new copado__Deployment__c(copado__Promotion__c = idFwd) };
        RenameBackPromotionDeploymentHandler.process(inputs);

        // Only one update should be captured (the back-promotion)
        System.assertNotEquals(null, RenameBackPromotionDeploymentHandler.testCapturedUpdates);
        System.assertEquals(1, RenameBackPromotionDeploymentHandler.testCapturedUpdates.size(), 'Only back promotion should trigger an update');
        System.assert(RenameBackPromotionDeploymentHandler.testCapturedUpdates[0].Name.contains('B1'));
    }

    @isTest
    static void testProcess_PromotionMissingFromMap_NoUpdate() {
        // Promotion id in deployment not present in injected map
        copado__Promotion__c promo = new copado__Promotion__c(); promo.put('copado__Back_Promotion__c', true);
        Id presentId = (Id) '069000000000000AAF';
        Id missingId = (Id) '069000000000000AB0';
        RenameBackPromotionDeploymentHandler.testPromotionMap = new Map<Id, copado__Promotion__c>{ presentId => promo };
        RenameBackPromotionDeploymentHandler.testPromotionToUserStoryMap = new Map<Id, copado__User_Story__c>{ presentId => new copado__User_Story__c() };
        RenameBackPromotionDeploymentHandler.testCapturedUpdates = null;

        List<copado__Deployment__c> inputs = new List<copado__Deployment__c>{ new copado__Deployment__c(copado__Promotion__c = missingId) };
        RenameBackPromotionDeploymentHandler.process(inputs);

        System.assertEquals(null, RenameBackPromotionDeploymentHandler.testCapturedUpdates, 'No updates should be captured when promotion is missing from map');
    }

    @isTest
    static void testProcess_WithPromIdsButNoInjectedMaps() {
        // Ensure the SOQL branches are executed when no injected maps are present
        RenameBackPromotionDeploymentHandler.testPromotionMap = null;
        RenameBackPromotionDeploymentHandler.testPromotionToUserStoryMap = null;
        RenameBackPromotionDeploymentHandler.testCapturedUpdates = null;

        Id fakeId = (Id) '069000000000000AB1';
        List<copado__Deployment__c> inputs = new List<copado__Deployment__c>{ new copado__Deployment__c(copado__Promotion__c = fakeId) };

        // Should run the SOQL branch but capture nothing (no real promotions exist)
        RenameBackPromotionDeploymentHandler.process(inputs);
        System.assertEquals(null, RenameBackPromotionDeploymentHandler.testCapturedUpdates, 'No updates expected when DB has no promotions');
    }

    @isTest
    static void testComputeDeploymentName_NonBooleanBackFlag() {
        copado__Promotion__c promo = new copado__Promotion__c();
        // Put a non-Boolean value intentionally
        promo.put('copado__Back_Promotion__c', (Object)null); // simulate invalid value
        copado__User_Story__c us = new copado__User_Story__c();
        us.put('copado__User_Story_Title__c', 'TitleX');

        String res = RenameBackPromotionDeploymentHandler.computeDeploymentName(promo, us);
        System.assertEquals(null, res, 'Non-Boolean back flag should be treated as false');
    }

    @isTest
    static void testComputeDeploymentName_TitleAsNumber() {
        copado__Promotion__c promo = new copado__Promotion__c();
        promo.put('copado__Back_Promotion__c', true);
        copado__User_Story__c us = new copado__User_Story__c();
        // Title provided as a non-string value
        us.put('copado__User_Story_Title__c', String.valueOf(12345)); // Fix

        String res = RenameBackPromotionDeploymentHandler.computeDeploymentName(promo, us);
        System.assertNotEquals(null, res, 'Should compute name for numeric title');
        System.assert(res.contains('12345'));
    }


    @isTest
static void testComputeDeploymentName_NameAsNumber() {

    // Create a test user story
    copado__User_Story__c us = new copado__User_Story__c(
        copado__User_Story_Title__c = '67890 Test Story'
    );
    insert us;

    // Query including required field
    us = [
        SELECT Id, Name, copado__User_Story_Title__c
        FROM copado__User_Story__c
        WHERE Id = :us.Id
        LIMIT 1
    ];

    // Mock Promotion
    copado__Promotion__c promo = new copado__Promotion__c();
    promo.put('copado__Back_Promotion__c', true);

    // Call method
    String res = RenameBackPromotionDeploymentHandler.computeDeploymentName(promo, us);

    System.debug('>>>> GeneratedName: ' + res);
    System.debug('>>>> UserStory Name: ' + us.Name);
    System.debug('>>>> UserStory Title: ' + us.copado__User_Story_Title__c);

    // Validate output exists
    System.assertNotEquals(null, res, 'Generated deployment name should not be null');
    System.assert(res.length() > 0, 'Generated deployment name should not be empty');

    // Optional: If expected format includes user story title
    System.assert(
        res.contains(us.copado__User_Story_Title__c),
        'Generated name should include user story title'
    );
}

  

    @isTest
    static void testComputeDeploymentName_BackFlagMissingTreatedFalse() {
        copado__Promotion__c promo = new copado__Promotion__c();
        // No back-flag set at all
        copado__User_Story__c us = new copado__User_Story__c();
        us.put('copado__User_Story_Title__c', 'X');

        String res = RenameBackPromotionDeploymentHandler.computeDeploymentName(promo, us);
        System.assertEquals(null, res, 'Missing back flag should be treated as false');
    }

    @isTest
    static void testComputeDeploymentName_EmptyTitleProducesPrefixOnly() {
        copado__Promotion__c promo = new copado__Promotion__c();
        promo.put('copado__Back_Promotion__c', true);
        copado__User_Story__c us = new copado__User_Story__c();
        // Title explicitly empty
        us.put('copado__User_Story_Title__c', '');

        String res = RenameBackPromotionDeploymentHandler.computeDeploymentName(promo, us);
        System.assertNotEquals(null, res);
        System.assert(res.startsWith('Backpromotion-'));
    }
}