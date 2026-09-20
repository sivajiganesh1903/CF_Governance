public class UserPermissionFetcherController {
    private static final String API_VERSION = '59.0';

    // Fetch users by username keyword (returns users + message)
    @AuraEnabled
    public static Map<String, Object> fetchUsersByUernameKeyword(Id orgId, String usernameKeyword) {
        List<Map<String, Object>> usersList = new List<Map<String, Object>>();
        Map<String, Object> result = new Map<String, Object>();

        try {
            RefreshTokenHelper.RefreshToken tokenDetails = RefreshTokenHelper.getAccessToken(orgId);
            String soql = 'SELECT Id, Name, FirstName, LastName, Username, Email, Division, FederationIdentifier, Profile.Name FROM User WHERE Username LIKE \'%' + String.escapeSingleQuotes(usernameKeyword) + '%\' LIMIT 10';
            String endpoint = tokenDetails.domainUrl + '/services/data/v' + API_VERSION + '/query?q=' + EncodingUtil.urlEncode(soql, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + tokenDetails.accessToken);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) respMap.get('records');

                for (Object obj : records) {
                    Map<String, Object> user = (Map<String, Object>) obj;
                    Map<String, Object> profile = (Map<String, Object>) user.get('Profile');

                    Map<String, Object> userMap = new Map<String, Object>();
                    userMap.put('Id', user.get('Id'));
                    userMap.put('Name', user.get('Name'));
                    userMap.put('Username', user.get('Username'));
                    userMap.put('Email', user.get('Email'));
                    userMap.put('FirstName', user.get('FirstName'));
                    userMap.put('LastName', user.get('LastName'));
                    userMap.put('Division', user.get('Division'));
                    userMap.put('FederationIdentifier', user.get('FederationIdentifier'));
                    userMap.put('ProfileName', profile != null ? profile.get('Name') : null);
                    usersList.add(userMap);
                }

                if (usersList.isEmpty()) {
                    result.put('message', 'No matching user found');
                } else {
                    result.put('message', 'Users found');
                }

                result.put('users', usersList);

            } else {
                System.debug('Error in fetchUsersByUernameKeyword: ' + res.getBody());
                result.put('message', 'Error occurred: ' + res.getBody());
                result.put('users', new List<Map<String, Object>>());
            }
        } catch (Exception e) {
            System.debug('Exception in fetchUsersByUernameKeyword: ' + e.getMessage());
            result.put('message', 'Exception: ' + e.getMessage());
            result.put('users', new List<Map<String, Object>>());
        }

        System.debug('Users fetched: ' + JSON.serializePretty(result));
        return result;
    }

    // Fetch user permissions by UserId
    @AuraEnabled
    public static Map<String, Object> fetchUserPermissionsById(String orgId, String userId) {
        if (String.isBlank(orgId) || String.isBlank(userId)) {
            throw new AuraHandledException('Both orgId and userId are required.');
        }

        Map<String, Object> result = new Map<String, Object>();

        try {
            RefreshTokenHelper.RefreshToken tokenDetails = RefreshTokenHelper.getAccessToken(orgId);

            // Fetch Profile
            String userQuery = 'SELECT Id, Profile.Name FROM User WHERE Id = \'' + String.escapeSingleQuotes(userId) + '\'';
            Map<String, Object> userData = querySingleRecord(tokenDetails, userQuery);
            if (userData != null) {
                Map<String, Object> profile = (Map<String, Object>) userData.get('Profile');
                result.put('Profile', profile != null ? profile.get('Name') : null);
            }

            // Fetch Permission Sets
            String psQuery = 'SELECT PermissionSet.Name, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = \'' + String.escapeSingleQuotes(userId) + '\' AND PermissionSet.IsOwnedByProfile = false' +'  AND PermissionSetGroupId  = null';
            result.put('PermissionSets', queryNameLabelList(tokenDetails, psQuery, 'PermissionSet'));

            // Fetch Permission Set Groups
            String psgQuery = 'SELECT PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel FROM PermissionSetAssignment WHERE AssigneeId = \'' + String.escapeSingleQuotes(userId) + '\' AND PermissionSetGroupId != null';
            result.put('PermissionSetGroups', queryNameLabelList(tokenDetails, psgQuery, 'PermissionSetGroup'));

            // Fetch Territories
            String trQuery = 'SELECT Territory2.Name FROM UserTerritory2Association WHERE UserId = \'' + String.escapeSingleQuotes(userId);
            result.put('Territories', queryNameLabelList(tokenDetails, trQuery, 'Territory2'));

        } catch (Exception e) {
            System.debug('Exception in fetchUserPermissionsById: ' + e.getMessage());
        }

        System.debug('Permissions fetched: ' + JSON.serializePretty(result));
        return result;
    }

    // Helper: Query single User record
    private static Map<String, Object> querySingleRecord(RefreshTokenHelper.RefreshToken tokenDetails, String soql) {
        List<Map<String, Object>> records = queryRecords(tokenDetails, soql);
        return !records.isEmpty() ? records[0] : null;
    }

    // Helper: Query records
    private static List<Map<String, Object>> queryRecords(RefreshTokenHelper.RefreshToken tokenDetails, String soql) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        try {
            String endpoint = tokenDetails.domainUrl + '/services/data/v' + API_VERSION + '/query?q=' + EncodingUtil.urlEncode(soql, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + tokenDetails.accessToken);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> recordsRaw = (List<Object>) respMap.get('records');

                for (Object obj : recordsRaw) {
                    result.add((Map<String, Object>) obj);
                }
            } else {
                System.debug('Query error: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception in queryRecords: ' + e.getMessage());
        }

        return result;
    }

    // Helper: Get Name + Label list
    private static List<Map<String, String>> queryNameLabelList(RefreshTokenHelper.RefreshToken tokenDetails, String soql, String relKey) {
        List<Map<String, String>> result = new List<Map<String, String>>();
        List<Map<String, Object>> records = queryRecords(tokenDetails, soql);

        for (Map<String, Object> rec : records) {
            Map<String, Object> relObj = (Map<String, Object>) rec.get(relKey);
            if (relObj != null) {
                Map<String, String> objMap = new Map<String, String>();
                if (relObj.containsKey('Name')) {
                    objMap.put('Name', (String) relObj.get('Name'));
                }
                if (relObj.containsKey('Label')) {
                    objMap.put('Label', (String) relObj.get('Label'));
                }
                if (relObj.containsKey('MasterLabel')) {
                    objMap.put('MasterLabel', (String) relObj.get('MasterLabel'));
                }
                result.add(objMap);
            }
        }

        return result;
    }
}