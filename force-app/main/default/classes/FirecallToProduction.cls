public with sharing class FirecallToProduction {
    @InvocableMethod(label='Freeze/Unfreeze Users' description='Freeze or unfreeze users based on Release Dates')
    public static void processUserFreezeUnfreeze(List<String> playbookIds) {
        if (playbookIds == null || playbookIds.isEmpty()) {
            System.debug('Error: Playbook ID list is null or empty');
            return;
        }
        
        // Fetch the Playbook and Named Credential
        Release_Playbook__c playbook = [
            SELECT Id, Release_Start_Date__c, Release_End_Date__c, Named_Credential__c 
            FROM Release_Playbook__c 
            WHERE Id IN :playbookIds LIMIT 1
        ];
        
        String NAMED_CREDENTIAL = playbook.Named_Credential__c;
        System.debug('Named Credential: ' + NAMED_CREDENTIAL);

        String playbookId = playbookIds[0]; // Extract the first Playbook ID
        System.debug('Processing Release_Playbook__c ID: ' + playbookId);

        List<Release_Assignment__c> assignments = [ SELECT Name__c, Email__c, Role__c, Release_Playbook__r.Release_Start_Date__c, 
                   Release_Playbook__r.Release_End_Date__c FROM Release_Assignment__c WHERE Release_Playbook__c = :playbookId ];

        System.debug('Total Users Found: ' + assignments.size());

        DateTime nowDT = System.now(); // Get current DateTime
        System.debug('nowDT: '+nowDT);

        for (Release_Assignment__c assignment : assignments) {
            DateTime releaseStartDate = assignment.Release_Playbook__r.Release_Start_Date__c;
            System.debug('releaseStartDate: '+releaseStartDate);
            
			DateTime releaseEndDate = assignment.Release_Playbook__r.Release_End_Date__c;            
            System.debug('releaseEndDate: '+releaseEndDate);

            Boolean shouldUnfreeze = (releaseStartDate != null && nowDT >= releaseStartDate) &&
                         (releaseEndDate != null && nowDT <= releaseEndDate);
            System.debug('shouldUnfreeze: '+shouldUnfreeze);

			Boolean shouldFreeze = (releaseEndDate != null && nowDT > releaseEndDate);
            System.debug('shouldFreeze: '+shouldFreeze);


            System.debug('Processing User: ' + assignment.Name__c + ' | Email: ' + assignment.Email__c + 
                         ' | Start Date: ' + releaseStartDate + ' | End Date: ' + releaseEndDate);
            
            if (shouldUnfreeze) {
                System.debug('Unfreezing User: ' + assignment.Email__c);
                updateUserStatus(NAMED_CREDENTIAL, assignment.Email__c, true); // Unfreeze user
            } else if (shouldFreeze) {
                System.debug('Freezing User: ' + assignment.Email__c);
                updateUserStatus(NAMED_CREDENTIAL, assignment.Email__c, false); // Freeze user
            } else {
                System.debug('No action needed for User: ' + assignment.Email__c);
            }
        }
    }

    private static void updateUserStatus(String NAMED_CREDENTIAL, String userEmail, Boolean shouldUnfreeze) {
        try {
            // Step 1: Get User Id from Target Org based on Email
            HttpRequest userReq = new HttpRequest();
            userReq.setEndpoint('callout:' + NAMED_CREDENTIAL + '/services/data/v59.0/query/?q=' +
                EncodingUtil.urlEncode('SELECT Id FROM User WHERE Email = \'' + userEmail + '\'', 'UTF-8'));
            userReq.setMethod('GET');
    
            Http userHttp = new Http();
            HttpResponse userRes = userHttp.send(userReq);
            System.debug('User query response status: ' + userRes.getStatusCode());
			System.debug('User query response body: ' + userRes.getBody());

    
            if (userRes.getStatusCode() == 200) {
                Map<String, Object> userResponse = (Map<String, Object>) JSON.deserializeUntyped(userRes.getBody());
                List<Object> userRecords = (List<Object>) userResponse.get('records');
                if (!userRecords.isEmpty()) {
                    String userId = (String) ((Map<String, Object>) userRecords[0]).get('Id');
                    system.debug('userId: '+ userId);
    
                    // Step 2: Get UserLogin Id using UserId
                    HttpRequest loginReq = new HttpRequest();
                    loginReq.setEndpoint('callout:' + NAMED_CREDENTIAL + '/services/data/v59.0/query/?q=' +
                        EncodingUtil.urlEncode('SELECT Id, IsFrozen FROM UserLogin WHERE UserId = \'' + userId + '\'', 'UTF-8'));
                    loginReq.setMethod('GET');
    
                    Http loginHttp = new Http();
                    HttpResponse loginRes = loginHttp.send(loginReq);
    
                    if (loginRes.getStatusCode() == 200) {
                        Map<String, Object> loginResponse = (Map<String, Object>) JSON.deserializeUntyped(loginRes.getBody());
                        List<Object> loginRecords = (List<Object>) loginResponse.get('records');
                        if (!loginRecords.isEmpty()) {
                            String loginId = (String) ((Map<String, Object>) loginRecords[0]).get('Id');
    
                            // Step 3: Freeze or Unfreeze the UserLogin record
                            HttpRequest freezeReq = new HttpRequest();
                            freezeReq.setEndpoint('callout:' + NAMED_CREDENTIAL + '/services/data/v59.0/sobjects/UserLogin/' + loginId);
                            freezeReq.setMethod('PATCH');
                            freezeReq.setHeader('Content-Type', 'application/json');
                            freezeReq.setBody(JSON.serialize(new Map<String, Object>{ 'IsFrozen' => !shouldUnfreeze }));
    
                            Http freezeHttp = new Http();
                            HttpResponse freezeRes = freezeHttp.send(freezeReq);
    
                            if (freezeRes.getStatusCode() == 204) {
                                System.debug('SUCCESS: UserLogin ' + loginId + ' updated. IsFrozen: ' + (!shouldUnfreeze));
                            } else {
                                System.debug('ERROR updating UserLogin: ' + freezeRes.getBody());
                            }
                        } else {
                            System.debug('No UserLogin found for userId: ' + userId);
                        }
                    } else {
                        System.debug('Error fetching UserLogin: ' + loginRes.getBody());
                    }
                } else {
                    System.debug('No user found with email: ' + userEmail);
                }
            } else {
                System.debug('Error fetching user ID: ' + userRes.getBody());
            }
        } catch (Exception e) {
            System.debug('API callout failed: ' + e.getMessage());
        }
    }

}