public without sharing class WebhookPlatformEventHelper {
	public static void publishAccessUpdateEvent(Id recordId) {
        UserAccessUpdateEvent__e event = new UserAccessUpdateEvent__e(
            Record_Id__c = recordId,
            Update_Status__c = '' 
        );

        Database.SaveResult result = EventBus.publish(event);
        if (!result.isSuccess()) {
            System.debug('Failed to publish platform event: ' + result.getErrors()[0].getMessage());
        }
    }
}