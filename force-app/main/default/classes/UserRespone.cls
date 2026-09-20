public class UserRespone {
  /*  @AuraEnabled
    public static PaginatedUserResponse fetchAllUsers(Id sandboxId, String queryEndpoint, String searchString, String sortBy) {
        SFRelease__Org__c sand = [SELECT Id, Name, SFRelease__Access_Token__c, SFRelease__Refresh_Token__c, SFRelease__Domain_URL__c 
                                  FROM SFRelease__Org__c WHERE Id =: sandboxId];
        String domainUrl = sand.SFRelease__Domain_URL__c;
        String accessToken = sand.SFRelease__Access_Token__c;
        String endpoint;
        if (queryEndpoint != null && !String.isEmpty(queryEndpoint)) {
            system.debug('inside if ------ ');
            endpoint = queryEndpoint;
        } else {
            //String query = 'SELECT+Id,Name,Email,Username,Profile.Name+FROM+User+WHERE+Profile.UserLicense.Name!=null+AND+isActive=TRUE';//+ORDER+BY+Name+ASC
            String query = 'SELECT Id, Name, Email, Username, Profile.Name FROM User WHERE Profile.UserLicense.Name != null AND isActive = TRUE';
            if(!String.isBlank(searchString)){
                //query += '+AND+Name+LIKE+\'%' + SearchString + '%\'';
                query += ' AND Name LIKE \'%' + searchString + '%\'';
            }else if(!String.isBlank(sortBy) && sortBy != 'All'){
                //query += '+AND+Name+LIKE+\'' + sortBy + '%\'';
                query += ' AND Name LIKE \'' + sortBy + '%\'';
                System.debug('QUERY ::/'+query);
            }
            
            system.debug('inside else ------- ');
            
            String encodedQuery = EncodingUtil.urlEncode(query + ' ORDER BY Name ASC', 'UTF-8');
            endpoint = '/services/data/v56.0/query/?q=' + encodedQuery;
            //endpoint = '/services/data/v56.0/query/?q='+query+'+ORDER+BY+Name+ASC';
            //endpoint = '/services/data/v56.0/query/?q=SELECT+Id,Name,Email,Username,Profile.Name+FROM+User+WHERE+Profile.UserLicense.Name!=null+AND+isActive=TRUE+ORDER+BY+Name+ASC';
        }
        
        try {
            System.debug('Next records URL: ' + endpoint);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(domainUrl + endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeout(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('HTTP response status: ' + res.getStatusCode());
            
            if (res.getStatusCode() == 200) {
                String body = res.getBody();
                
                if (!String.isEmpty(body)) {
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(body);
                    system.debug('result --- ' + result);
                    List<Object> records = (List<Object>) result.get('records');
                    Integer totalRecords = (Integer) result.get('totalSize');
                    System.debug('Number of records fetched: ' + records.size());
                    System.debug('Total records available: ' + totalRecords);
                    
                    String nextRecordsUrl = (String) result.get('nextRecordsUrl');
                    
                    PaginatedUserResponse responseWrapper = new PaginatedUserResponse();
                    responseWrapper.users = new List<PaginatedUserResponse.UserWrapper>();
                    for (Object recordObj : records) {
                        Map<String, Object> record = (Map<String, Object>) recordObj;
                        PaginatedUserResponse.UserWrapper user = new PaginatedUserResponse.UserWrapper();
                        user.name = (String) record.get('Name');
                        user.email = (String) record.get('Email');
                        user.username = (String) record.get('Username');
                        user.profile = (String) ((Map<String, Object>) record.get('Profile')).get('Name');
                        responseWrapper.users.add(user);
                    }
                    responseWrapper.nextRecordsUrl = nextRecordsUrl;
                    responseWrapper.totalRecords = totalRecords;
                    System.debug('PaginatedUserResponse: ' + JSON.serialize(responseWrapper));
                    
                    return responseWrapper;

                } else {
                    System.debug('Empty response body received.');
                    return new PaginatedUserResponse();
                }
            } else {
                System.debug('HTTP response error. Status Code: ' + res.getStatusCode() + ', Status: ' + res.getStatus());
                return new PaginatedUserResponse();
            }
        } catch (Exception e) {
            System.debug('Exception occurred during fetching users execution: ' + e.getMessage());
            throw e;
        }
    }  */
}