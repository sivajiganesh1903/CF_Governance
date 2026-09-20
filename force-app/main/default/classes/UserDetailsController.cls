public class UserDetailsController {
    private static final String email = 'sivaji.g@cloudfulcrum.com';
    
    public static void fetchAndAttachUserDetails() {
        RefreshTokenHelper.RefreshToken tokenDetails = RefreshTokenHelper.getAccessToken('a2fD1000002xEElIAM');
        fetchUserDetailsAsync(tokenDetails.orgId, tokenDetails.accessToken, tokenDetails.domainUrl);
    }
    
    @future(callout=true)
    public static void fetchUserDetailsAsync(Id orgId, String accessToken, String baseUrl) {
        try {
            SFRelease__Org__c orgRecord = [SELECT Id, Name FROM SFRelease__Org__c WHERE Id = :orgId LIMIT 1];
            List<Map<String, Object>> userDetails = fetchUserByEmail(accessToken, baseUrl);
            
            String jsonBody = JSON.serializePretty(userDetails);
            
            Attachment att = new Attachment();
            att.ParentId = orgRecord.Id;
            att.Name = orgRecord.Name + '_User_Permissions_' + String.valueOf(Date.today());
            att.Body = Blob.valueOf(jsonBody);
            att.ContentType = 'application/json';
            insert att;
        } catch (Exception e) {
            System.debug('Exception in fetchUserDetailsAsync: ' + e.getMessage());
        }
    }
    
    private static List<Map<String, Object>> fetchUserByEmail(String accessToken, String baseUrl) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        try {
            String userQuery = 'SELECT Id, Profile.Name, ProfileId, Name, Email FROM User WHERE Email = \'' + email + '\'';
            String encodedQuery = EncodingUtil.urlEncode(userQuery, 'UTF-8');
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '/services/data/v59.0/query?q=' + encodedQuery);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() != 200) return result;
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> userRecords = (List<Object>) responseMap.get('records');
            if (userRecords.isEmpty()) return result;
            
            Map<String, Object> user = (Map<String, Object>) userRecords[0];
            String userId = (String) user.get('Id');
            
            // Add Profile info
            Map<String, Object> profileInfo = new Map<String, Object>();
            profileInfo.put('ComponentType', 'Profile');
            profileInfo.put('Name', ((Map<String, Object>) user.get('Profile')).get('Name'));
            result.add(profileInfo);
            
            // Fetch Permission Sets
            String psaQuery = 'SELECT Id, PermissionSet.Name, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = \'' + userId + '\' AND PermissionSet.IsOwnedByProfile = false';
            fetchAndAddPermissions(baseUrl, accessToken, psaQuery, 'PermissionSet', result, true);
            
            // Fetch Permission Set Groups
            String psgQuery = 'SELECT Id, PermissionSetGroup.Name, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId = \'' + userId + '\' AND PermissionSetGroupId != null';
            fetchAndAddPermissions(baseUrl, accessToken, psgQuery, 'PermissionSetGroup', result, false);
            
        } catch (Exception e) {
            System.debug('Error in fetchUserByEmail: ' + e.getMessage());
        }
        
        return result;
    }
    
    private static void fetchAndAddPermissions(String baseUrl, String accessToken, String query, String type, List<Map<String, Object>> result, Boolean isPSA) {
        try {
            String endpoint = baseUrl + '/services/data/v59.0/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> psaMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) psaMap.get('records');
                
                for (Object obj : records) {
                    Map<String, Object> record = (Map<String, Object>) obj;
                    Map<String, Object> psData = isPSA ? (Map<String, Object>) record.get('PermissionSet') : (Map<String, Object>) record.get('PermissionSetGroup');
                    
                    Map<String, Object> item = new Map<String, Object>();
                    item.put('ComponentType', type);
                    item.put('Name', psData.get('Name'));
                    if (psData.containsKey('Label')) item.put('Label', psData.get('Label'));
                    if (psData.containsKey('DeveloperName')) item.put('DeveloperName', psData.get('DeveloperName'));
                    
                    result.add(item);
                }
            }
        } catch (Exception e) {
            System.debug('Error in fetchAndAddPermissions: ' + e.getMessage());
        }
    }  
}