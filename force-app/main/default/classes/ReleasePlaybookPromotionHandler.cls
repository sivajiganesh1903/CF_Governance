public class ReleasePlaybookPromotionHandler {

    @AuraEnabled
    public static String createPromotion(String playbookId) {
        try {
            // Step 1: Fetch all releases linked to the Release Playbook
            List<copado__Release__c> releases = [
                SELECT Id, Name, Preprod_Deployment_Date__c, Preprod_User_Story_End_Date__c,
                       Production_Validation_Start_Time__c, Prod_Deployment_Date__c,
                       UAT_Deployment_Start_Date__c
                FROM copado__Release__c
                WHERE Release_Playbook__c = :playbookId
            ];
            if (releases.isEmpty()) {
                return 'No releases found for the given Release Playbook.';
            }

            // Step 2: Identify the PI Release
            copado__Release__c piRelease = null;
            for (copado__Release__c release : releases) {
                if (release.Name.startsWith('PI')) {
                    piRelease = release;
                    break;
                }
            }
            if (piRelease == null) {
                return 'No PI Release found for this Release Playbook.';
            }

            // Step 3: Validate UAT Deployment Date Range
            Date today = Date.today();
            if (today < piRelease.UAT_Deployment_Start_Date__c) {
                return 'This release has not begun yet.';
            }
            if (today > piRelease.Prod_Deployment_Date__c) {
                return 'This release is over.';
            }

            // Step 4: Determine Deployment Type
            String deploymentType = null;
            if (today >= piRelease.Preprod_Deployment_Date__c && today <= piRelease.Preprod_User_Story_End_Date__c) {
                deploymentType = 'Preprod';
            } else if (today >= piRelease.Production_Validation_Start_Time__c && today <= piRelease.Prod_Deployment_Date__c) {
                deploymentType = 'Prod';
            }
            if (deploymentType == null) {
                return 'Today\'s date does not fall under any deployment window.';
            }

            // Step 5: Fetch User Stories based on Deployment Type
            List<copado__User_Story__c> userStories = new List<copado__User_Story__c>();
            for (copado__Release__c release : releases) {
                userStories.addAll([
                    SELECT Id, Name
                    FROM copado__User_Story__c
                    WHERE copado__Release__c = :release.Id
                    AND copado__Status__c = :(
                        deploymentType == 'Preprod' ? 'Verification Complete' : 'Ready To Deploy'
                    )
                    AND copado__Org_Credential__r.Name = :(
                        deploymentType == 'Preprod' ? 'FSC UAT' : 'FSC Preprod'
                    )
                ]);
            }
            if (userStories.isEmpty()) {
                return 'No User Stories found for the selected criteria.';
            }

            // Step 6: Create Promotion Record
            copado__Promotion__c promotion = new copado__Promotion__c();
            insert promotion;

            // Step 7: Associate User Stories with the Promotion
            List<copado__Promoted_User_Story__c> userStoryLinks = new List<copado__Promoted_User_Story__c>();
            for (copado__User_Story__c userStory : userStories) {
                copado__Promoted_User_Story__c link = new copado__Promoted_User_Story__c();
                link.copado__Promotion__c = promotion.Id;
                link.copado__User_Story__c = userStory.Id;
                userStoryLinks.add(link);
            }
            insert userStoryLinks;

            return 'Promotion created successfully with ' + userStories.size() + ' User Stories.';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}