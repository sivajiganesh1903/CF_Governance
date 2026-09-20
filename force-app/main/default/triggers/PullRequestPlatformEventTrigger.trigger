trigger PullRequestPlatformEventTrigger on PR_Event__e (after insert) {
    for (PR_Event__e eventRecord : Trigger.New) {
        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(eventRecord.Payload__c);

            if (eventRecord.Event_Type__c == 'opened') {
                webhooksubscriptionhelper.opened(payload);
            } else if (eventRecord.Event_Type__c == 'submitted') {
                Map<String, Object> review = (Map<String, Object>) payload.get('review');
                Map<String, Object> pull_request = (Map<String, Object>) payload.get('pull_request');
                String submitId = String.valueOf(payload.get('X-GitHub-Delivery'));
                webhooksubscriptionhelper.submitted(review, submitId, pull_request);
            } else if (eventRecord.Event_Type__c == 'closed') {
                Map<String, Object> pull_request = (Map<String, Object>) payload.get('pull_request');
                webhooksubscriptionhelper.closed(pull_request);
            }
        } catch (Exception e) {
            System.debug('Error processing Platform Event: ' + e.getMessage());
        }
    }
}