public class OrgUsers {

    @AuraEnabled(cacheable=true)
    public static void fetchUserDetails(Id OrgId) {
        RefreshTokenHelper.RefreshToken tokenDetails = RefreshTokenHelper.getAccessToken(OrgId);
        fetchUserDetailsAsync(tokenDetails.orgId, tokenDetails.accessToken, tokenDetails.domainUrl);
    }

    @future(callout=true)
    public static void fetchUserDetailsAsync(Id orgId, String accessToken, String baseUrl) {
        try {
            SFRelease__Org__c orgRecord = [SELECT Id, Name FROM SFRelease__Org__c WHERE Id = :orgId LIMIT 1];
            List<Map<String, Object>> userDetails = fetchUsers(accessToken, baseUrl);
            System.debug('Total Active Users Fetched: ' + userDetails.size());
            // Get each user detail
            for (Map<String, Object> user : userDetails) {
                System.debug('User Details: ' + JSON.serializePretty(user));
            }
        } catch (Exception e) {
            System.debug('Exception in fetchUserDetailsAsync: ' + e.getMessage());
        }
    }

    private static List<Map<String, Object>> fetchUsers(String accessToken, String baseUrl) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        try {
            String userQuery = 'SELECT Id, Profile.Name, ProfileId, FirstName, LastName, Name, Email, FederationIdentifier, IsActive FROM User WHERE IsActive = true';
            String encodedQuery = EncodingUtil.urlEncode(userQuery, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/services/data/v59.0/query?q=' + encodedQuery);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('HTTP Response Status: ' + res.getStatusCode());
            System.debug('HTTP Response Body: ' + res.getBody());

            if (res.getStatusCode() != 200) return result;

            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> userRecords = (List<Object>) responseMap.get('records');

            for (Object obj : userRecords) {
                Map<String, Object> user = (Map<String, Object>) obj;

                Map<String, Object> item = new Map<String, Object>();
                item.put('Id', user.get('Id'));
                item.put('Name', user.get('Name'));
                item.put('FirstName', user.get('FirstName'));
                item.put('LastName', user.get('LastName'));
                item.put('Email', user.get('Email'));
                item.put('Division', user.get('Division'));
                item.put('FederationIdentifier', user.get('FederationIdentifier'));
                item.put('IsActive', user.get('IsActive'));
                item.put('ProfileId', user.get('ProfileId'));

                Map<String, Object> profile = (Map<String, Object>) user.get('Profile');
                item.put('ProfileName', profile != null ? profile.get('Name') : null);

                result.add(item);
            }

        } catch (Exception e) {
            System.debug('Error in fetchUsers: ' + e.getMessage());
        }
        return result;
    }
}