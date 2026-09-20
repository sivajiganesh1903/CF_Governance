/**
*  @description This class handles the creation of CI jobs and organization scans for Copado user stories.
*  @author [Vishnu Ramagoni & Sivaji Ganesh]
*  @date [19-03-2025]
*/
public with sharing class userstorysfsca {
    /**
    * @description This method creates a CI job for a given user story ID.
    * It queries metadata records, extracts relevant names, 
    * and triggers a GitHub action with the metadata information.
    * @param usid The ID of the user story for which the CI job is created.
    */
    @Future(callout=true)
    public static void createcijob(Id usid) { 
        try {
            // Query the copado__User_Story_Metadata__c records
            List<copado__User_Story_Metadata__c> userStoriesMetadata = [SELECT Id, copado__Metadata_API_Name__c, copado__Type__c
                                                                        FROM copado__User_Story_Metadata__c WHERE copado__User_Story__c = :usid AND copado__Type__c IN ('ApexTrigger', 'ApexClass', 'LightningComponentBundle', 'ApexPage','Flow') 
                                                                        WITH SECURITY_ENFORCED];
            
            List<String> metadataNames = new List<String>();
            
            copado__User_Story__c userstorydetails = [SELECT id,copado__View_in_Git__c, Copado__project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__URI__c from copado__User_Story__c where id =:usid WITH SECURITY_ENFORCED];
            
            string gitrepouri = userstorydetails.Copado__project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__URI__c;

            // Use switch to reduce cyclomatic complexity
            for (copado__User_Story_Metadata__c record : userStoriesMetadata) {
                if (record.copado__Metadata_API_Name__c != null) {
                    String extractedNames;
                    
                    switch on record.copado__Type__c {
                        when 'ApexClass' {
                            extractedNames = 'classes/' + record.copado__Metadata_API_Name__c.substringAfter('.') + '.cls';
                        }
                        when 'ApexTrigger' {
                            extractedNames = 'triggers/' + record.copado__Metadata_API_Name__c.substringAfter('.') + '.trigger';
                        }
                        when 'LightningComponentBundle' {
                            extractedNames = 'lwc/' + record.copado__Metadata_API_Name__c.substringAfter('.');
                        }
                        when 'ApexPage' {
                            extractedNames = 'pages/' + record.copado__Metadata_API_Name__c.substringAfter('.') + '.page';
                        }
                        when 'Flow' {
                            extractedNames = 'flows/' + record.copado__Metadata_API_Name__c.substringAfter('.') + '.flow';
                        }
                        when else {
                            extractedNames = null; // Handle unexpected types (optional)
                        }
                    }
                    
                    if (extractedNames != null) {
                        metadataNames.add(extractedNames);
                    }
                }
            }
            
            String metadataNamesStr = String.join(metadataNames, ',');
            
            // Fetch branch details
            String branch2;  
            String actual;  
            String actual2;  
            String branchName;
            if(userstorydetails.copado__View_in_Git__c != null){
                    branch2 = userstorydetails.copado__View_in_Git__c;
                    actual = branch2.substringAfter('>'); 
                    actual2 = actual.substringBefore('<');
                    branchName = actual2;
            }


            
            // Get the base URL by querying the MyDomain URL in the Organization object
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            String accesstoken = GetSessionID_LWC.getSessionIdFromVFPage(Page.GetSessionId);
            
            // Prepare JSON body

            Map<String, String> params = new Map<String, String>{
                'GIT_URL' => gitrepouri,//Dynamic
                'BRANCH_NAME' => branchName,
                'Enpoint' => baseUrl,
                'Access_Token' => accesstoken,
                'Components' => metadataNamesStr,
                'Record_ID' => usid
            };

            System.debug('params: ' + params);
            // Build request body
            String body = '';
            for (String key : params.keySet()) {
                body += key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8') + '&';
            }
            body = body.removeEnd('&');

            // Make the callout            
            String endpoint = 'callout:JenkinsDev/buildWithParameters';
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(body);
            // Send request
            try {
                HttpResponse res = h.send(req);
                System.debug('Status: ' + res.getStatusCode());   // Expect 201 if queued
                System.debug('Response: ' + res.getBody());       // Usually empty
                System.debug('Queue URL: ' + res.getHeader('Location'));
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    * @description This method triggers the creation of a CI job for the given user story ID.
    * @param usid The ID of the user story for which the CI job will be created.
    */
    @AuraEnabled
    public static void storyscanbutton(Id usid) { 
        Userstorysfsca.createcijob(usid);
    }
}
//    
//    /**
//    * @description This method triggers an organization scan for the given credential ID.
//    * @param credid The ID of the organization credential.
//    */
//    @AuraEnabled
//    public static void orgscan(Id credid) { 
//        
//        List<copado__Org__c> credentialorg = [SELECT Id, Name, branch__c FROM copado__Org__c WHERE id = :credid 
//                                              WITH SECURITY_ENFORCED];
//        System.debug('Org Credentials: ' + credentialorg);
//        dispatchOrgScan(credentialorg);
//    }
//    
//    
//    /**
//    * @description Shared private method to send GitHub callout for org scans.
//    * @param orgList The list of copado__Org__c records to scan.
//    */
//    public static void dispatchOrgScan(List<copado__Org__c> orgList) {
//        if ( orgList.isEmpty()) return;
//        try{
//            // Get the base URL by querying the MyDomain URL in the Organization object
//            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
//            System.debug('Base URL: +++ ' + baseUrl);
//            String accessToken = GetSessionID_LWC.getSessionIdFromVFPage(Page.GetSessionId);
//            System.debug('Session Id: +++ ' + accessToken);
//            
//            for (copado__Org__c org : orgList) {
//			System.debug('Org Details: +++ ' + org);
//                System.debug('GitHub ref branch: ' + org.branch__c);
//				//System.debug('GitHub ref branch: ' + org.branch__c);
//                String bodyJson = JSON.serialize(new Map<String, Object>{
//                    'ref' => org.branch__c,
//                        'inputs' => new Map<String, Object>{
//                            'components' => 'classes,triggers,pages,lwc',
//                                'instance_url' => baseUrl,
//                                'access_token' => accessToken,
//                                'Org_id' => org.Id
//                                }
//                });
//                System.debug('body json' + bodyjson);
//                String endpoint = 'callout:githubactions/code_analysis_org.yml/dispatches';
//                HttpRequest req = new HttpRequest();
//                req.setEndpoint(endpoint);
//                System.debug('EndPoint URL: +++' + endpoint);
//                req.setMethod('POST');
//                req.setHeader('Accept', 'application/vnd.github+json');
//                req.setHeader('X-GitHub-Api-Version', '2022-11-28');
//                req.setBody(bodyJson);
//                
//                // This will send the request, and return a response
//                Http http = new Http();
//                HttpResponse res = http.send(req);
//                res.getStatusCode();
//                System.debug('Get Status Code: ++++' + res.getStatusCode());
//            }
//        }catch (Exception e) {
//            throw new AuraHandledException(e.getMessage());
//        }
//    }