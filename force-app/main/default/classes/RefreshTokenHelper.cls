public class RefreshTokenHelper {
    // Inner class to store the access token details
    public class RefreshToken {
        public String accessToken;	// The new Access Token retrieved from OAuth
        public String domainUrl;	// The Domain URL of the org
        public Id orgId;			// The Org Id
    }
    /**
	 * This Method fetches a new access token using the Refresh Token.
	 * @param orgId The Id of the SFRelease__Org__c record (target org)
	 * @return RefreshToken object containing access token, domain URL, and org Id
	 * @throws CalloutException when token refresh fails
	 */
    public static RefreshToken getAccessToken(Id orgId) {
        System.debug(LoggingLevel.INFO, 'Starting token refresh for Org Id: ' + orgId);
        try {
            // Query org details
            SFRelease__Org__c org = [SELECT Id, SFRelease__Access_Token__c, Name, SFRelease__Refresh_Token__c, SFRelease__Domain_URL__c
                                     FROM SFRelease__Org__c WHERE Id = :orgId LIMIT 1];
            System.debug(LoggingLevel.DEBUG, 'Org details retrieved: ' + JSON.serialize(org));
            
            // Get Connected App credentials from custom metadata
            SFRelease__ConnectedAppCredentials__c creds = SFRelease__ConnectedAppCredentials__c.getInstance();
            if (creds == null) {
                throw new CalloutException('Connected App Credentials not found.');
            }
            
            // Prepare the HTTP request for token refresh
            HttpRequest req = new HttpRequest();
            req.setEndpoint(org.SFRelease__Domain_URL__c + '/services/oauth2/token?grant_type=refresh_token' +
                            '&client_id=' + creds.SFRelease__Key__c + '&client_secret=' + creds.SFRelease__Secret__c +
                            '&refresh_token=' + org.SFRelease__Refresh_Token__c);
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('POST');
            System.debug(LoggingLevel.DEBUG, 'Sending token refresh request to: ' + req.getEndpoint());
            
            // Send the HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug(LoggingLevel.DEBUG, 'Token refresh HTTP response: ' + res.getBody());
            
            // Process the response
            if (res.getStatusCode() == 200) {
                Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = (String) tokenResponse.get('access_token');
                if (String.isBlank(accessToken)) {
                    throw new CalloutException('Access token missing in response.');
                }               
                System.debug(LoggingLevel.INFO, 'Access token retrieved successfully.');
                
                RefreshToken response = new RefreshToken();
                response.accessToken = accessToken;
                response.domainUrl = org.SFRelease__Domain_URL__c;
                response.orgId = org.Id;
                return response;
            } else {
                System.debug(LoggingLevel.ERROR, 'Token refresh failed with status: ' + res.getStatus() + ', body: ' + res.getBody());
                throw new CalloutException('Token Refresh Failed: ' + res.getStatus() + ' ' + res.getBody());
            }
        } catch (CalloutException ce) {
            System.debug(LoggingLevel.ERROR, 'CalloutException occurred: ' + ce.getMessage());
            throw ce;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Unexpected error occurred during token refresh: ' + e.getMessage());
            throw new CalloutException('Unexpected error during token refresh: ' + e.getMessage());
        }
    }  
}