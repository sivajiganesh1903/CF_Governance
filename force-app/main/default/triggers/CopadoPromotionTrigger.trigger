trigger CopadoPromotionTrigger on copado__Promotion__c (after update) {
	if(Trigger.isAfter && Trigger.isUpdate){
        //CopadoPromotionHandler.deleteGitAttachments(Trigger.new, Trigger.oldMap);
        CopadoPromotionHandler.deleteGitReleatedAttachements(Trigger.new, Trigger.oldMap);
    }
}