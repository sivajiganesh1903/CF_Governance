public class UserPermissionFetcherControllerV2 {
private static final String API_VERSION = '59.0';
    private static final String TIMEZONE = 'Asia/Kolkata';
    private static final String LOCALE = 'en_US';
    private static final String LANGUAGE = 'en_US';
    private static final String EMAIL_ENCODING = 'UTF-8';

    @AuraEnabled
    public static List<Map<String, Object>> createOrUpdateUsers(List<Id> uamIds) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        System.debug('--- START createOrUpdateUsers ---');

        try {
            Map<Id, User_Access_Managment__c> uamMap = new Map<Id, User_Access_Managment__c>(
                [SELECT Id, Persona_New__c, Requested_Environment__c, isApproved__c, Need_Admin_Access__c, Access_Period_End__c, 
                 Persona_New__r.IsSensitive__c, (SELECT Id, First_Name__c, Last_Name__c, Email__c, Federation_ID__c FROM 
                                                 User_Requests__r) FROM User_Access_Managment__c WHERE Id IN :uamIds]);

            Map<Id, Map<String, Set<String>>> personaComponentMap = getComponentIdsFromPersonas(uamMap);

            for (User_Access_Managment__c uamDetails : uamMap.values()) {
                Boolean isSensitive = uamDetails.Persona_New__r != null && uamDetails.Persona_New__r.IsSensitive__c;

                if (uamDetails.User_Requests__r.isEmpty()) {
                    System.debug('No User Request records found for UAM: ' + uamDetails.Id);
                    continue;
                }

                for (User_Request__c userReq : uamDetails.User_Requests__r) {
                    Map<String, Object> result = new Map<String, Object>();
                    results.add(result);

                    try {
                        if (uamDetails.Requested_Environment__c == null) {
                            result.put('message', 'Requested Environment (Org Id) is missing');
                            continue;
                        }

                        Id orgId = uamDetails.Requested_Environment__c;
                        RefreshTokenHelper.RefreshToken tokenDetails = RefreshTokenHelper.getAccessToken(orgId);
                        Map<String, Set<String>> componentIds = personaComponentMap.get(uamDetails.Id);

                        String profileIdToUse = null;

                        if (isSensitive) {
                            if (uamDetails.isApproved__c && uamDetails.Need_Admin_Access__c) {
                                Set<String> profileIds = componentIds.get('ProfileIds');
                                if (profileIds.isEmpty()) {
                                    result.put('message', 'No ProfileId found for sensitive persona');
                                    continue;
                                }
                                profileIdToUse = profileIds.iterator().next();
                            } else {
                                result.put('message', 'Sensitive persona conditions not met');
                                continue;
                            }
                        } else {
                            Set<String> profileIds = componentIds.get('ProfileIds');
                            if (profileIds.isEmpty()) {
                                result.put('message', 'No ProfileId found');
                                continue;
                            }
                            profileIdToUse = profileIds.iterator().next();
                        }

                        // Check if user exists
                        String soql = 'SELECT Id FROM User WHERE FederationIdentifier = \'' +
                            String.escapeSingleQuotes(userReq.Federation_ID__c) + '\'';
                        List<Map<String, Object>> existingUsers = queryRecords(tokenDetails, soql);
                        String userId;

                        if (!existingUsers.isEmpty()) {
                            userId = (String) existingUsers[0].get('Id');
                            updateUserProfile(tokenDetails, userId, profileIdToUse);
                            removeUserPermissionAssignments(tokenDetails, userId);
                            result.put('message', 'User updated');
                        } else {
                            Map<String, Object> userPayload = new Map<String, Object>{
                                'FirstName' => userReq.First_Name__c,
                                'LastName' => userReq.Last_Name__c,
                                'Email' => userReq.Email__c,
                                'Username' => userReq.Email__c,
                                'FederationIdentifier' => userReq.Federation_ID__c,
                                'Alias' => '@' + userReq.Federation_ID__c,
                                'IsActive' => true,
                                'EmailEncodingKey' => EMAIL_ENCODING,
                                'TimeZoneSidKey' => TIMEZONE,
                                'LocaleSidKey' => LOCALE,
                                'LanguageLocaleKey' => LANGUAGE,
                                'ProfileId' => profileIdToUse
                            };

                            String endpoint = tokenDetails.domainUrl + '/services/data/v' + API_VERSION + '/sobjects/User/';
                            HttpRequest req = new HttpRequest();
                            req.setEndpoint(endpoint);
                            req.setMethod('POST');
                            req.setHeader('Authorization', 'Bearer ' + tokenDetails.accessToken);
                            req.setHeader('Content-Type', 'application/json');
                            req.setBody(JSON.serialize(userPayload));

                            Http http = new Http();
                            HttpResponse res = http.send(req);
                            if (res.getStatusCode() == 201) {
                                Map<String, Object> createResp = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                                userId = (String) createResp.get('id');
                                result.put('message', 'User created');
                            } else {
                                result.put('message', 'Error creating user: ' + res.getBody());
                                continue;
                            }
                        }

                        result.put('userId', userId);
                        assignPermissions(tokenDetails, userId, componentIds, uamDetails.Access_Period_End__c);

                    } catch (Exception e) {
                        result.put('message', 'Exception: ' + e.getMessage());
                        System.debug('Exception processing request: ' + e.getMessage());
                    }
                }
            }

        } catch (Exception eOuter) {
            System.debug('Outer Exception: ' + eOuter.getMessage());
        }

        System.debug('--- END createOrUpdateUsers ---');
        return results;
    }

    private static void assignPermissions(RefreshTokenHelper.RefreshToken tokenDetails, String userId, Map<String, Set<String>> componentIds, Date expirationDate) {
        for (String psId : componentIds.get('PermissionSetIds')) {
            assignPermission(tokenDetails, userId, 'PermissionSetId', psId, expirationDate);
        }
        for (String psgId : componentIds.get('PermissionSetGroupIds')) {
            assignPermission(tokenDetails, userId, 'PermissionSetGroupId', psgId, expirationDate);
        }
    }

    private static void assignPermission(RefreshTokenHelper.RefreshToken tokenDetails, String userId, String key, String value, Date expirationDate) {
        try {
            Map<String, Object> payload = new Map<String, Object>{ 'AssigneeId' => userId };
            payload.put(key, value);
            if (expirationDate != null) {
                payload.put('ExpirationDate', String.valueOf(expirationDate)); // Format: YYYY-MM-DD
            }

            String endpoint = tokenDetails.domainUrl + '/services/data/v' + API_VERSION + '/sobjects/PermissionSetAssignment/';
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + tokenDetails.accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Assign ' + key + ' Response: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Exception in assignPermission: ' + e.getMessage());
        }
    }
    
    private static void updateUserProfile(RefreshTokenHelper.RefreshToken tokenDetails, String userId, String profileId) {
        try {
            Map<String, Object> payload = new Map<String, Object>{ 'ProfileId' => profileId, 'IsActive' => true };
            String endpoint = tokenDetails.domainUrl + '/services/data/v' + API_VERSION + '/sobjects/User/' + userId;
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('PATCH');
            req.setHeader('Authorization', 'Bearer ' + tokenDetails.accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Update User Profile Response: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Exception in updateUserProfile: ' + e.getMessage());
        }
    }

    private static void removeUserPermissionAssignments(RefreshTokenHelper.RefreshToken tokenDetails, String userId) {
        try {
            String soql = 'SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = \'' + String.escapeSingleQuotes(userId) + '\'';
            List<Map<String, Object>> psaList = queryRecords(tokenDetails, soql);
            for (Map<String, Object> psa : psaList) {
                String psaId = (String) psa.get('Id');
                if (psaId != null) {
                    String endpoint = tokenDetails.domainUrl + '/services/data/v' + API_VERSION + '/sobjects/PermissionSetAssignment/' + psaId;
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(endpoint);
                    req.setMethod('DELETE');
                    req.setHeader('Authorization', 'Bearer ' + tokenDetails.accessToken);
                    req.setHeader('Content-Type', 'application/json');

                    Http http = new Http();
                    HttpResponse res = http.send(req);
                    System.debug('Deleted PSA ' + psaId + ': ' + res.getStatusCode() + ' Body: ' + res.getBody());
                }
            }
        } catch (Exception e) {
            System.debug('Exception in removeUserPermissionAssignments: ' + e.getMessage());
        }
    }
    
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
                List<Object> recs = (List<Object>) respMap.get('records');
                for (Object rec : recs) {
                    result.add((Map<String, Object>) rec);
                }
            }
        } catch (Exception e) {
            System.debug('Exception in queryRecords: ' + e.getMessage());
        }
        return result;
    }
    
    private static Map<Id, Map<String, Set<String>>> getComponentIdsFromPersonas(Map<Id, User_Access_Managment__c> uamMap) {
        Map<Id, Map<String, Set<String>>> personaMap = new Map<Id, Map<String, Set<String>>>();
        try {
            Set<Id> personaIds = new Set<Id>();
            for (User_Access_Managment__c uam : uamMap.values()) {
                if (uam.Persona_New__c != null) {
                    personaIds.add(uam.Persona_New__c);
                }
            }

            Map<Id, List<ContentDocumentLink>> linkMap = new Map<Id, List<ContentDocumentLink>>();
            for (ContentDocumentLink l : [
                SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :personaIds
            ]) {
                if (!linkMap.containsKey(l.LinkedEntityId)) {
                    linkMap.put(l.LinkedEntityId, new List<ContentDocumentLink>());
                }
                linkMap.get(l.LinkedEntityId).add(l);
            }

            Set<Id> docIds = new Set<Id>();
            for (List<ContentDocumentLink> links : linkMap.values()) {
                for (ContentDocumentLink l : links) {
                    docIds.add(l.ContentDocumentId);
                }
            }

            Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>();
            for (ContentVersion v : [
                SELECT ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId IN :docIds AND IsLatest = true
            ]) {
                versionMap.put(v.ContentDocumentId, v);
            }

            for (User_Access_Managment__c uam : uamMap.values()) {
                Map<String, Set<String>> resultMap = new Map<String, Set<String>>{
                    'ProfileIds' => new Set<String>(),
                    'PermissionSetIds' => new Set<String>(),
                    'PermissionSetGroupIds' => new Set<String>()
                };

                if (uam.Persona_New__c != null && linkMap.containsKey(uam.Persona_New__c)) {
                    for (ContentDocumentLink l : linkMap.get(uam.Persona_New__c)) {
                        ContentVersion v = versionMap.get(l.ContentDocumentId);
                        if (v != null && v.VersionData != null) {
                            try {
                                String content = v.VersionData.toString();
                                List<Object> items = (List<Object>) JSON.deserializeUntyped(content);
                                for (Object o : items) {
                                    Map<String, Object> mapItem = (Map<String, Object>) o;
                                    String type = (String) mapItem.get('ComponentType');
                                    String cid = (String) mapItem.get('Id');
                                    if (type == 'Profile') resultMap.get('ProfileIds').add(cid);
                                    if (type == 'PermissionSet') resultMap.get('PermissionSetIds').add(cid);
                                    if (type == 'PermissionSetGroup') resultMap.get('PermissionSetGroupIds').add(cid);
                                }
                            } catch (Exception eInner) {
                                System.debug('Error parsing JSON: ' + eInner.getMessage());
                            }
                        }
                    }
                }
                personaMap.put(uam.Id, resultMap);
            }
        } catch (Exception eOuter) {
            System.debug('Exception in getComponentIdsFromPersonas: ' + eOuter.getMessage());
        }

        return personaMap;
    }
}