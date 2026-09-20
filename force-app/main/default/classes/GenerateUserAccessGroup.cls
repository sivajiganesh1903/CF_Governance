/**
 * @description
 * GenerateUserAccessGroup is responsible for fetching metadata (Permission Sets, Profiles, Permission Set Groups)
 * from a connected Salesforce org via REST API, generating a JSON file, and attaching it to the SFRelease__Org__c record.
 * Before attaching, it deletes old attachments linked to that Org record.
 */
public class GenerateUserAccessGroup {     
    /**
     * @description Entry point called from Lightning (LWC Button). Kicks off async metadata fetch.
     * @param orgId Id of the SFRelease__Org__c record (representing the connected org).
     * @return JSON string indicating success or failure status.
     */
    @AuraEnabled
    public static String fetchAndAttachMetadata(Id orgId) {
        System.debug('START fetchAndAttachMetadata for Org Id: ' + orgId);
        try {
            // Get access token and org connection details
            RefreshTokenHelper.RefreshToken tokenDetails = RefreshTokenHelper.getAccessToken(orgId);
            System.debug('Retrieved token details for org: ' + tokenDetails.orgId);
            
            // Start async processing
            fetchMetadataAsync(tokenDetails.orgId, tokenDetails.accessToken, tokenDetails.domainUrl);
            
            return '{"status":"success","message":"Metadata extraction started. A JSON file will be attached to the Org record shortly."}';
        } catch (Exception e) {
            System.debug('Error in fetchAndAttachMetadata: ' + e.getMessage());
            
            // Escape special characters in message for JSON safety
            String safeMessage = e.getMessage().replace('\\', '\\\\').replace('"', '\\"');
            return '{"status":"error","message":"Failed to initiate metadata extraction: ' + safeMessage + '"}';
        }
    }  
    
    /**
	 * @description Async method to fetch metadata, delete old attachments, and attach the JSON file.
	 * @param orgId Id of the SFRelease__Org__c record
	 * @param accessToken OAuth access token for REST API callouts
	 * @param baseUrl Domain URL of the connected org
	 */
    @future(callout=true)
    public static void fetchMetadataAsync(Id orgId, String accessToken, String baseUrl) {
        System.debug('START fetchMetadataAsync for Org Id: ' + orgId);
        try {
            // Fetch the org record
            List<SFRelease__Org__c> orgList = [SELECT Id, Name FROM SFRelease__Org__c WHERE Id = :orgId LIMIT 1];
            
            if (orgList.isEmpty()) {
                System.debug('No SFRelease__Org__c record found for ID: ' + orgId);
                return;
            }
            
            SFRelease__Org__c orgRecord = orgList[0];
            System.debug('Found Org record: ' + orgRecord.Name + ' (' + orgRecord.Id + ')');
            
            // Delete old attachments
            List<Attachment> oldAttachments = [SELECT Id FROM Attachment WHERE ParentId = :orgRecord.Id];
            
            if (!oldAttachments.isEmpty()) {
                delete oldAttachments;
                System.debug('Deleted ' + oldAttachments.size() + ' old attachments.');
            } else {
                System.debug('No old attachments found to delete.');
            }
            
            List<Map<String, Object>> allResults = new List<Map<String, Object>>();
            
            // Fetch metadata components
            allResults.addAll(fetchMetadata(baseUrl + '/services/data/v59.0/query?q=SELECT+Id,+Name,+Description+FROM+PermissionSet', accessToken, 'PermissionSet'));
            allResults.addAll(fetchMetadata(baseUrl + '/services/data/v59.0/query?q=SELECT+Id,+Name,+Description+FROM+Profile', accessToken, 'Profile'));
            allResults.addAll(fetchMetadata(baseUrl + '/services/data/v59.0/query?q=SELECT+Id,+MasterLabel,+DeveloperName,+Description+FROM+PermissionSetGroup', accessToken, 'PermissionSetGroup'));
            
            String jsonBody = JSON.serializePretty(allResults);
            System.debug('Metadata fetch complete. Number of components: ' + allResults.size());
            
            // Attach JSON file
            Attachment att = new Attachment();
            att.ParentId = orgRecord.Id;
            att.Name = orgRecord.Name + '_Org_Permissions_' + String.valueOf(Date.today());
            att.Body = Blob.valueOf(jsonBody);
            att.ContentType = 'application/json';
            insert att;
            
            System.debug('Attached metadata JSON file. Attachment Id: ' + att.Id);
            
        } catch (Exception e) {
            System.debug('Exception in fetchMetadataAsync: ' + e.getMessage());
        }
    }
    
    /**
	 * @description Helper to perform REST callout, parse JSON, and return metadata components.
	 * @param endpoint REST API query endpoint
	 * @param accessToken OAuth token for auth
	 * @param componentType Type of component (PermissionSet, Profile, PermissionSetGroup)
	 * @return List of maps representing each component
	 */
    private static List<Map<String, Object>> fetchMetadata(String endpoint, String accessToken, String componentType) {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        System.debug('Fetching metadata for: ' + componentType);
        
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug(componentType + ' callout response status: ' + res.getStatusCode());
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) jsonResponse.get('records');
                
                for (Object recordObj : records) {
                    Map<String, Object> recordMap = (Map<String, Object>) recordObj;
                    Map<String, Object> item = new Map<String, Object>();
                    
                    item.put('Id', recordMap.get('Id'));
                    item.put('ComponentType', componentType);
                    
                    if (componentType == 'PermissionSet' || componentType == 'Profile') {
                        item.put('Name', recordMap.get('Name'));
                        item.put('Description', recordMap.containsKey('Description') ? recordMap.get('Description') : '');
                    } else if (componentType == 'PermissionSetGroup') {
                        item.put('Name', recordMap.get('MasterLabel'));
                        item.put('DeveloperName', recordMap.get('DeveloperName'));
                        item.put('Description', recordMap.containsKey('Description') ? recordMap.get('Description') : '');
                    }
                    
                    resultList.add(item);
                }
                
                System.debug('Fetched ' + resultList.size() + ' ' + componentType + ' records.');
            } else {
                System.debug('Non-200 response for ' + componentType + ': ' + res.getBody());
            }
            
        } catch (Exception ex) {
            System.debug('Exception during ' + componentType + ' callout: ' + ex.getMessage());
        }
        
        return resultList;
    }
}