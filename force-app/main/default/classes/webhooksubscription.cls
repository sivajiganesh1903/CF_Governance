@RestResource(urlMapping='/api/webhooks/pushDetails/*')
global without sharing class webhooksubscription {
    @HttpPost
    global static void handleNotification() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        try{
            
            System.debug(request.requestURI);
            System.debug(request.requestBody.toString());
            
            String jsonString = request.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            
            // Create a new record in the custom object
            Pull_Request_Event__c event = new Pull_Request_Event__c();
            event.Entire_Payload__c = jsonString;  // Store the entire payload as a string, if needed
            event.Event_Type__c =payload.get('action').toString();
            insert event;
            String eventType = String.valueOf(payload.get('action'));

            // Publish Platform Event
            PR_Event__e pe = new PR_Event__e(
                Event_Type__c = eventType,
                Payload__c = jsonString
            );
            EventBus.publish(pe);

            response.statusCode = 200;
            response.responseBody = Blob.valueOf('{"status": "Platform Event published successfully"}');  
        }
        catch(Exception e){
            System.debug('exception +++'+ e.getMessage());
            response.statusCode = 200;
                response.responseBody = Blob.valueOf('{"status":'+ e.getMessage()+'=='+e.getLineNumber()+'}');
        }
    }
}