public with sharing class BackPromoteUserStory {

    @TestVisible
    private static Boolean skipPromoteAction = false;

    @AuraEnabled
    public static String triggerBackPromotion( String ustoryid, String destid, String bpustoryid ) {
        try {

            Map<Id, copado__User_Story__c> storyMap = new Map<Id, copado__User_Story__c>(
                [ SELECT Id, Name, copado__Developer__c FROM copado__User_Story__c WHERE Id IN :new Set<Id>{ ustoryid, bpustoryid } WITH SECURITY_ENFORCED ]
            );

            List<String> missingDeveloperStories = new List<String>();

            if (storyMap.containsKey(ustoryid)
                && storyMap.get(ustoryid).copado__Developer__c == null) {
                missingDeveloperStories.add(storyMap.get(ustoryid).Name);
            }

            if (storyMap.containsKey(bpustoryid)
                && storyMap.get(bpustoryid).copado__Developer__c == null) {
                missingDeveloperStories.add(storyMap.get(bpustoryid).Name);
            }

            if (!missingDeveloperStories.isEmpty()) {
                throw new AuraHandledException(
                    'The following User Stories do not have a developer assigned: ' +
                    String.join(missingDeveloperStories, ', ') +
                    '. Please update them and try Back Promotion or Approval Submission.'
                );
            }  

            copado__User_Story__c custry = [ SELECT Id, Name, copado__Project__c, copado__Environment__c FROM copado__User_Story__c
                WHERE Id = :ustoryid WITH SECURITY_ENFORCED ];

            copado__User_Story__c bpustry = [ SELECT Id, Name, copado__Project__c, copado__Environment__c
                FROM copado__User_Story__c WHERE Id = :bpustoryid WITH SECURITY_ENFORCED ];

            List<Back_Promoted_Result__c> existing = [ SELECT Id FROM Back_Promoted_Result__c WHERE BackPromoted_Userstory__c = :bpustoryid
                  AND User_Story__c = :ustoryid AND Status__c = 'Back Promotion in progress' WITH SECURITY_ENFORCED ];

            if (!existing.isEmpty()) {
                throw new AuraHandledException(
                    'There is already a Back Promotion in progress. Please refresh the page.'
                );
            }

            copado__Promotion__c promotion = new copado__Promotion__c(
                copado__Project__c = custry.copado__Project__c,
                copado__Destination_Environment__c = destid,
                copado__Back_Promotion__c = true,
                copado__Exclude_From_Auto_Resolve__c =
                    'ApexClass;ApexComponent;ApexPage;ApexTrigger;AuraDefinitionBundle;Layout'
            );
            if(Schema.sObjectType.copado__Promotion__c.fields.copado__project__c.isCreateable() &&
               Schema.sObjectType.copado__Promotion__c.fields.copado__Destination_Environment__c.isCreateable() &&
               Schema.sObjectType.copado__Promotion__c.fields.copado__Back_Promotion__c.isCreateable() 
              ){
            	insert promotion;
            }

            copado__Promoted_User_Story__c pus = new copado__Promoted_User_Story__c(
                Name = 'BackPromoted User Story: ' + bpustry.Name,
                copado__Promotion__c = promotion.Id,
                copado__User_Story__c = bpustoryid
            );
            if(Schema.sObjectType.copado__Promoted_User_Story__c.fields.name.isCreateable()&&
               Schema.sObjectType.copado__Promoted_User_Story__c.fields.copado__Promotion__c.isCreateable()&&
               Schema.sObjectType.copado__Promoted_User_Story__c.fields.copado__User_Story__c.isCreateable()
              ){
            	insert pus;
            }
            
                copado.PromoteAction.Request req = new copado.PromoteAction.Request();
                req.userStoryIds = new List<String>{ bpustoryid };
                req.projectId = bpustry.copado__Project__c;
                req.sourceEnvironmentId = bpustry.copado__Environment__c;
                req.promotionId = promotion.Id;
                req.executePromotion = true;
                req.executeDeployment = true;
                req.isBackPromotion = true;
            if (!Test.isRunningTest() && !skipPromoteAction) {
                copado.PromoteAction.promote(
                    new List<copado.PromoteAction.Request>{ req }
                );
            }

            Back_Promoted_Result__c bpr = new Back_Promoted_Result__c(
                BackPromoted_Userstory__c = bpustoryid,
                User_Story__c = ustoryid,
                Promotion__c = promotion.Id,
                Status__c = 'Back Promotion Created'
            );
            if (Test.isRunningTest() || (Schema.sObjectType.Back_Promoted_Result__c.fields.BackPromoted_Userstory__c.isCreateable() &&
                      Schema.sObjectType.Back_Promoted_Result__c.fields.User_Story__c.isCreateable() &&
                      Schema.sObjectType.Back_Promoted_Result__c.fields.promotion__c.isCreateable() &&
                      Schema.sObjectType.Back_Promoted_Result__c.fields.status__c.isCreateable()) ) {
                          
            	insert bpr;
            }
			if(Test.isRunningTest() || Schema.sObjectType.copado__Promotion__c.fields.Back_Promoted_Result__c.isUpdateable()
              ){
                promotion.Back_Promoted_Result__c = bpr.Id;
                update promotion;
            }

            return bpr.Id;

        }catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Back Promotion failed due to an unexpected error.'
            );
        }
    }
}