public with sharing class RenameBackPromotionDeploymentHandler {
    // Test hooks to allow unit tests to inject data and capture updates without DML
    @TestVisible
    public static Map<Id, copado__Promotion__c> testPromotionMap;

    @TestVisible
    public static Map<Id, copado__User_Story__c> testPromotionToUserStoryMap;

    @TestVisible
    public static List<copado__Deployment__c> testCapturedUpdates;

    public static void process(List<copado__Deployment__c> newDeployments) {
        if (newDeployments == null || newDeployments.isEmpty()) return;

        Set<Id> promIds = new Set<Id>();
        for (copado__Deployment__c d : newDeployments) {
            if (d.copado__Promotion__c != null) promIds.add(d.copado__Promotion__c);
        }

        if (promIds.isEmpty()) return;

        Map<Id, copado__Promotion__c> promMap;
        // In test context allow injection of a promotion map to avoid querying Copado-managed objects
        if (Test.isRunningTest() && testPromotionMap != null && !testPromotionMap.isEmpty()) {
            promMap = new Map<Id, copado__Promotion__c>(testPromotionMap);
        } else {
            promMap = new Map<Id, copado__Promotion__c>([ SELECT Id, copado__Back_Promotion__c
                FROM copado__Promotion__c WHERE Id IN :promIds WITH SECURITY_ENFORCED ]);
        }

        Map<Id, copado__User_Story__c> promotionToUserStoryMap = new Map<Id, copado__User_Story__c>();
        if (Test.isRunningTest() && testPromotionToUserStoryMap != null && !testPromotionToUserStoryMap.isEmpty()) {
            promotionToUserStoryMap = new Map<Id, copado__User_Story__c>(testPromotionToUserStoryMap);
        } else {
            for (copado__Promoted_User_Story__c pus : [ SELECT Id, copado__Promotion__c, copado__User_Story__r.Name,copado__User_Story__r.copado__User_Story_Title__c
                FROM copado__Promoted_User_Story__c WHERE copado__Promotion__c IN :promIds WITH SECURITY_ENFORCED LIMIT 1 ]) {
                promotionToUserStoryMap.put(pus.copado__Promotion__c, pus.copado__User_Story__r);
            }
        }

        List<copado__Deployment__c> toUpdate = new List<copado__Deployment__c>();
        for (copado__Deployment__c dep : newDeployments) {
            copado__Promotion__c promo = promMap.get(dep.copado__Promotion__c);
            copado__User_Story__c us = promotionToUserStoryMap.get(dep.copado__Promotion__c);

            Boolean isBack = false;
            if (promo != null) {
                Object val = promo.get('copado__Back_Promotion__c');
                isBack = (val instanceof Boolean) ? (Boolean)val : false;
            }

            if (promo != null && isBack && us != null) {
                // Prefer the explicit user-story title field if available, otherwise fallback to Name
                Object titleVal = us.get('copado__User_Story_Title__c');
                String usName = (titleVal != null) ? String.valueOf(titleVal) : ((us.get('Name') != null) ? String.valueOf(us.get('Name')) : '');
                toUpdate.add(new copado__Deployment__c(Id = dep.Id, Name = 'Backpromotion-'+usName+System.Now()));
            }
        }

        if (!toUpdate.isEmpty()) {
            if (Test.isRunningTest()) {
                // Capture updates instead of performing DML in test context
                testCapturedUpdates = toUpdate;
            } else {
                if (!Schema.sObjectType.copado__Deployment__c.isUpdateable()) {
                	update toUpdate;
                }
            }
        }
    }

    // Test-only pure function to compute the new deployment name without performing DML
    @TestVisible
    public static String computeDeploymentName(copado__Promotion__c promo, copado__User_Story__c us) {
        if (promo == null || us == null) return null;
        Object val = promo.get('copado__Back_Promotion__c');
        Boolean isBack = (val instanceof Boolean) ? (Boolean)val : false;
        if (!isBack) return null;
        Object titleVal = us.get('copado__User_Story_Title__c');
        String usName = (titleVal != null) ? String.valueOf(titleVal) : ((us.get('Name') != null) ? String.valueOf(us.get('Name')) : '');
        return 'Backpromotion-'+usName+System.Now();
    }
}