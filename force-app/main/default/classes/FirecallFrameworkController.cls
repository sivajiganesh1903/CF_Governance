public class FirecallFrameworkController {
    /*Used to get list of orgs in personaManagementComp lwc*/
    @AuraEnabled(cacheable=true)
    public static List<SFRelease__Org__c> fetchSalesforceOrg(){
        return [SELECT Id, SFRelease__Access_Token__c, Name, SFRelease__Refresh_Token__c, SFRelease__Domain_URL__c, SFRelease__Org_Type__c FROM SFRelease__Org__c ];
    }
    
    /*Used get list of persona records in personaManagementComp lwc**/
    @AuraEnabled(cacheable=true)
    public static List<cf_Persona__c> getPersonaRecords(Id orgId) {
        List<cf_Persona__c> persona = [ SELECT Id, Name, Name__c, Org__c, IsSensitive__c FROM cf_Persona__c WHERE Org__c = : orgId];
        return persona;
    }  

    /*Used get related org Id of persona records in personaViewer lwc**/
    @AuraEnabled(cacheable=true)
    public static Id getPersonaOrgId(Id personaId) {
        cf_Persona__c persona = [SELECT Id, Name, Name__c,IsSensitive__c, Org__c FROM cf_Persona__c WHERE Id = :personaId LIMIT 1 ];      
        return persona.Org__c;
    }    
    
    /*Used to get all the permissions metadata related to the org in personaViewer lwc*/
    @AuraEnabled(cacheable=true)
    public static String getOrgJsonAttachment(Id orgId) {
         try {
            // Query as a list so zero‑row results don’t raise QueryException
            List<Attachment> atts = [ SELECT Id, Name, Body FROM Attachment WHERE ParentId = :orgId ORDER BY CreatedDate DESC LIMIT 1 ];
            
            // No attachment on this record
            if (atts.isEmpty()) {
                return null;            
            }
            
            // Convert the Blob to String (guard against unexpected null Body)
            Blob bodyBlob = atts[0].Body;
            return (bodyBlob != null) ? bodyBlob.toString() : null;
            
        } catch (Exception e) {
            System.debug('getOrgJsonAttachment ERROR: ' + e.getMessage());
            return null;  
        }
    }
    
    /*Used to attach the selected permissions metadata as a json file to the persona in personaViewer lwc*/
    @AuraEnabled
    public static Id makeJsonAttachment(Id parentId, String jsonString) {
        // 1. Find any existing SelectedPermissions file linked to this record
        List<ContentDocumentLink> oldLinks = [ SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :parentId 
                                              AND ContentDocument.Title = 'SelectedPermissions' ];
        
        // 2. Remove the old link(s) and, if possible, delete the file(s)
        if (!oldLinks.isEmpty()) {
            Set<Id> oldDocIds = new Set<Id>();
            for (ContentDocumentLink l : oldLinks) {
                oldDocIds.add(l.ContentDocumentId);
            }
            
            // Delete the link(s) to the current record
            delete oldLinks;
            
            try {
                delete [SELECT Id FROM ContentDocument WHERE Id IN :oldDocIds];
            } catch (DmlException e) {
            }
        }
        
        // 3. Insert the new file as a ContentVersion
        ContentVersion cv = new ContentVersion( Title = 'SelectedPermissions', PathOnClient = 'SelectedPermissions.json', VersionData  = Blob.valueOf(jsonString) );
        insert cv;
        
        // 4. Retrieve the parent ContentDocumentId
        Id newDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1 ].ContentDocumentId;
        
        // 5. Link the file to the record
        insert new ContentDocumentLink( ContentDocumentId = newDocId, LinkedEntityId = parentId, ShareType = 'V', Visibility = 'AllUsers' );
        
        return newDocId;
    }
    
    /*Used to get latest json file to the persona in personaViewer lwc*/
    @AuraEnabled(cacheable=true)
    public static String getLatestPermissionsJson(Id parentId) {
        // Step 1: Get the first linked ContentDocument
        List<ContentDocumentLink> links = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :parentId LIMIT 1 ];
    
        if (!links.isEmpty()) {
            Id docId = links[0].ContentDocumentId;
    
            // Step 2: Get the latest version of that document (JSON only)
            List<ContentVersion> versions = [ SELECT VersionData, Title, FileType FROM ContentVersion WHERE ContentDocumentId = :docId 
                                             AND FileType = 'JSON' ORDER BY CreatedDate DESC LIMIT 1 ];
    
            if (!versions.isEmpty()) {
                // Read the file body
                Blob bodyBlob = versions[0].VersionData;
                return bodyBlob.toString();
            }
        }
    
        // Fallback to classic Attachment if no file is found
        List<Attachment> atts = [ SELECT Body, Name FROM Attachment WHERE ParentId = :parentId AND Name LIKE '%.json' ORDER BY CreatedDate DESC LIMIT 1 ];
        if (!atts.isEmpty()) {
            return atts[0].Body.toString();
        }
    
        return null; // No file found
    }
    
    /*Used to attach the related permissions metadata as a json file to the persona in personaPermissionTemplate lwc*/
    @AuraEnabled(cacheable=true)
    public static String getPersonaPermissions(Id personaId) {
        List<ContentDocumentLink> links = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :personaId ];
    
        if (!links.isEmpty()) {
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink l : links) docIds.add(l.ContentDocumentId);
    
            List<ContentVersion> vers = [ SELECT VersionData, FileType FROM ContentVersion WHERE ContentDocumentId IN :docIds AND FileType = 'JSON' ORDER BY CreatedDate DESC LIMIT 1 ];
            if (!vers.isEmpty()) {
                return vers[0].VersionData.toString(); 
            }
        }
  
        List<Attachment> atts = [ SELECT Body FROM Attachment WHERE  ParentId = :personaId AND Name LIKE '%.json' ORDER  BY CreatedDate DESC LIMIT 1 ];
        if (!atts.isEmpty()) {
            return atts[0].Body.toString();
        }
    
        return '[]'; 
    }
    
    @AuraEnabled(cacheable=false)
    public static User_Access_Managment__c createUAMandRequests( User_Access_Managment__c uamRec, List<User_Request__c> userRequests ){
        if (uamRec == null) {
            throw new AuraHandledException('UAM input cannot be null.');
        }

        try {

            insert uamRec;            
            Id uamId = uamRec.Id;

            if (userRequests != null && !userRequests.isEmpty()) {
                for (User_Request__c ur : userRequests) {
                    ur.User_Access_Managment__c = uamId;   
                }
                insert userRequests;
            }

            if (uamRec.Persona_New__c != null) {          
                clonePersonaJsonAsync(uamRec.Persona_New__c, uamId);
            }

            return [ SELECT  Id, Name, Business_Justification__c, Divsion__c, Persona_New__c, Access_Details__c, Access_Period_Start__c, 
                    Access_Period_End__c, ( SELECT Id, Name, First_Name__c, Last_Name__c, Email__c FROM   User_Requests__r ORDER  BY CreatedDate DESC )
                	FROM User_Access_Managment__c WHERE Id = :uamId ];

            } catch (Exception e) {
                throw new AuraHandledException('Failed to save records: ' + e.getMessage());
            }
        }
    
        @future(callout=false)
        private static void clonePersonaJsonAsync(Id personaId, Id uamId) {
            if (personaId == null || uamId == null) return;
        
            ContentDocumentLink personaLink = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :personaId LIMIT 1 ];
            if (personaLink == null) return;
        
            ContentVersion srcVer = [ SELECT VersionData, Title FROM ContentVersion WHERE ContentDocumentId = :personaLink.ContentDocumentId
                ORDER BY VersionNumber DESC LIMIT 1 ];
        
            ContentVersion clone = new ContentVersion( Title = 'Requested Permissions',PathOnClient = 'Requested_Permissions.json', VersionData = srcVer.VersionData, FirstPublishLocationId = uamId, Origin = 'H' );
            insert clone;                       
        }

    
        private static void clonePersonaJson(Id personaId, Id uamId) {
        if (personaId == null) return;
    
        List<ContentDocumentLink> links = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :personaId LIMIT  1 ];
    
        if (links.isEmpty()) return;
    
        Id contentDocId = links[0].ContentDocumentId;
    
        List<ContentVersion> versions = [ SELECT Title, FileExtension, PathOnClient, VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocId 
                                         ORDER BY VersionNumber DESC LIMIT 1 ];
    
        if (versions.isEmpty()) return;
    
        ContentVersion src = versions[0];
    
        ContentVersion newVersion = new ContentVersion( Title = 'Requested Permissions',
            PathOnClient = String.isBlank(src.PathOnClient) ? src.Title + '.json' : src.PathOnClient,
            VersionData  = src.VersionData, Origin = 'H' );
        insert newVersion;
    
        insert new ContentDocumentLink( ContentDocumentId = newVersion.ContentDocumentId, LinkedEntityId = uamId, ShareType = 'V', Visibility = 'AllUsers' );
          
        // Re-query so ContentDocumentId is definitely populated
        newVersion = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newVersion.Id ];
        
        // now we’re sure we have a valid ContentDocumentId
        insert new ContentDocumentLink( ContentDocumentId = newVersion.ContentDocumentId, LinkedEntityId = uamId, ShareType = 'V', Visibility        = 'AllUsers' );
    }

    

    /*Used to attach the related permissions metadata as a json file to the persona in permissionsOnUAMRecord lwc*/
        @AuraEnabled(cacheable=true)
        public static String getPermissionsForUam(Id recordId) {
            String json = fetchJsonFromFiles(recordId);
            if (json != null) return json;        
            return '[]';
        }

        private static String fetchJsonFromFiles(Id parentId) {
            List<ContentDocumentLink> links = [ SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :parentId ];
        
            if (!links.isEmpty()) {
                Set<Id> docIds = new Set<Id>();
                for (ContentDocumentLink link : links) {
                    docIds.add(link.ContentDocumentId);
                }
        
                List<ContentVersion> versions = [ SELECT VersionData, FileType FROM ContentVersion WHERE ContentDocumentId IN :docIds
                    AND FileType = 'JSON' ORDER BY CreatedDate DESC LIMIT 1 ];
        
                if (!versions.isEmpty()) {
                    return versions[0].VersionData.toString();
                }
            }
        
            List<Attachment> atts = [ SELECT Body FROM Attachment WHERE ParentId = :parentId AND Name LIKE '%.json' ORDER BY CreatedDate DESC LIMIT 1 ];
            if (!atts.isEmpty()) {
                return atts[0].Body.toString();
            }
        
            return null;
        }
	@AuraEnabled(cacheable=true)
    public static List<String> getDivisionPicklistValues() {
        return getPicklistValues(User_Access_Managment__c.Divsion__c);
    }
	private static List<String> getPicklistValues(Schema.SObjectField field) {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getLabel());
        }
        
        return picklistValues;
    }
    @AuraEnabled
    public static cf_Persona__c getPersonaDetails(String recordId) {
        System.debug('Record Id: '+ recordId);
        return [SELECT Id, Name, IsSensitive__c, Org__c FROM cf_Persona__c WHERE Id = :recordId LIMIT 1];
    }

    @AuraEnabled
    public static Id clonePersonaRecord(cf_Persona__c personaData) {
        cf_Persona__c newPersona = personaData.clone(false, true, false, false);
        insert newPersona;

        // Fetch and clone JSON attachment
        ContentDocumentLink docLink = [ SELECT ContentDocumentId FROM ContentDocumentLink 
            WHERE LinkedEntityId = :personaData.Id LIMIT 1 ];

        ContentVersion oldVersion = [ SELECT VersionData, Title, PathOnClient FROM ContentVersion 
            WHERE ContentDocumentId = :docLink.ContentDocumentId ORDER BY VersionNumber DESC LIMIT 1 ];

        ContentVersion newVersion = new ContentVersion( Title = oldVersion.Title, PathOnClient = oldVersion.PathOnClient, VersionData = oldVersion.VersionData );
        insert newVersion;

        insert new ContentDocumentLink( ContentDocumentId = newVersion.ContentDocumentId,
            LinkedEntityId = newPersona.Id, ShareType = 'V', Visibility = 'AllUsers' );

        return newPersona.Id;
    }
}