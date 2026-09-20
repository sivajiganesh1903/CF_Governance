public without sharing class jiraconnectorhelper {
    public static void storycreated(Map<String,Object> payload) {


        Map<String, Object> issue = (Map<String, Object>)payload.get('issue');
        Change_Story__C changestory = new Change_Story__c();
            changestory.name = issue.get('key').toString();
            changestory.Id__c = issue.get('id').toString();
            
        Map<String, Object> fields = (Map<String, Object>)issue.get('fields');
        Map<String, Object> status = (Map<String, Object>)fields.get('status');
            changestory.status__c = status.get('name').toString();
        insert changestory;

    }


    public static void issuelinkcreated(Map<String, Object> payload) {
        try {

            string changestory;
            string userstory;
            // Retrieve the 'issueLink' data from the payload
            Map<String, Object> issuelink = (Map<String, Object>) payload.get('issueLink');  
            if (issuelink == null) {
                System.debug('No issueLink found in the payload.');
                return;
            }
    
            // Retrieve and safely convert 'destinationIssueId' and 'sourceIssueId' to Strings
            String destinationIssueId = issuelink.containsKey('destinationIssueId') 
                ? String.valueOf(issuelink.get('destinationIssueId')) 
                : null;
            System.debug('Destination Issue ID: ' + destinationIssueId);
    
            String sourceId = issuelink.containsKey('sourceIssueId') 
                ? String.valueOf(issuelink.get('sourceIssueId')) 
                : null;
            System.debug('Source Issue ID: ' + sourceId);

            String issuelinkid = issuelink.containsKey('id') 
            ? String.valueOf(issuelink.get('id')) 
            : null;
            System.debug('Issue Link ID: ' + issuelinkid);
    
            if (destinationIssueId == null || sourceId == null) {
                System.debug('Either destinationIssueId or sourceIssueId is null.');
                return;
            }
            
            // Query the Change Story record matching the destinationIssueId
            List<change_story__c> changestories = [SELECT Id, Id__c FROM change_story__c WHERE Id__c = :destinationIssueId LIMIT 1];
        
            if (changestories.isEmpty()) {
                List<copado__User_Story__C> userStories = [SELECT Id, Name FROM copado__User_Story__C WHERE copadoconnect__External_ID__c = :destinationIssueId LIMIT 1];
                if(!userStories.isEmpty()){
                    System.debug('User stories found with destination id');
                }
                userstory = userStories[0].id;
            }
            else{
                changestory = changestories[0].Id;
                System.debug('change stories found with destination id');
            }
    
            // Retrieve related User Stories
            List<copado__User_Story__C> userStories = [SELECT Id, Name FROM copado__User_Story__C WHERE copadoconnect__External_ID__c = :sourceId LIMIT 1];
            if(userStories.isEmpty()){
                List<change_story__c> cs = [SELECT Id, Id__c FROM change_story__c WHERE Id__c = :sourceId LIMIT 1];
                if(!cs.isEmpty()){
                    System.debug('change stories found with source id');
                }
                changestory = cs[0].Id;
            }
            else{
                userstory = userStories[0].id;
                System.debug('User stories found with source id');
            }

            system.debug('changestory: '+ changestory + ' userstory: ' + userstory);


            Change_Story_List__c csl = new Change_Story_List__c();

            if ((userStories.isEmpty() && changestories.isEmpty()) || (!changestories.isEmpty() && !userStories.isEmpty()) ){
                csl.Change_Story__c = changestory;
                csl.User_Story__c = userstory;
                csl.Issue_Link_ID__c =issuelinkid;
                insert csl;
                System.debug('change story list created successfully: ' + csl);
            } else {
                System.debug('No eligible User Story found to update.');
            }
    
        } catch (Exception e) {
            System.debug('Exception in issuelinkcreated: ' + e.getMessage());
        }
    }

    public static void issuelinkdeleted(Map<String,Object> payload){

        Map<String,Object>  issuelink = (Map<String,Object>)payload.get('issueLink');
        String issuelinkid = issuelink.containsKey('id') 
        ? String.valueOf(issuelink.get('id')) 
        : null;
        System.debug('Issue Link ID: ' + issuelinkid);


        // Retrieve the 'issueLink' data from the payload
        List<Change_Story_List__c> csl = [SELECT Id FROM Change_Story_List__c WHERE Issue_Link_ID__c = :issuelinkid LIMIT 1];
        
        if(!csl.isEmpty()){
            system.debug('CSL to be deleted == '+csl);
            delete csl;
        }
        else{
            return;
        }
        
    }

    public static void issueupdated(Map<String,Object> payload) {


        Map<String, Object> issue = (Map<String, Object>)payload.get('issue');
        string issueid;
        issueid = issue.get('id').toString();
            
        Map<String, Object> fields = (Map<String, Object>)issue.get('fields');
        Map<String, Object> status = (Map<String, Object>)fields.get('status');
        string statusupdate = status.get('name').toString();
        change_story__c cs = [select id,name,Id__c,Status__c from change_story__c where id__c =: issueid];
        list <change_story_list__C> csl = [select id,name,change_story__c from change_story_list__C where change_story__c =: cs.id ];
        // Update the Status field for all queried records
        if (!csl.isEmpty()) {
            for (Change_Story_List__c record : csl) {
                record.Status__c = statusupdate; 
            }

            // Perform the DML update operation
            try {
                update csl;
                System.debug('Status updated successfully for Change Story List records.');
            } catch (DmlException e) {
                System.debug('Error updating Status: ' + e.getMessage());
            }
        } else {
            System.debug('No Change Story List records found for the specified Change Story.');
        }
        if(cs <> NULL){
            try{
            cs.Status__c = statusupdate;
            update cs;
            }
            catch (DmlException e) {
                System.debug('Error updating Status: ' + e.getMessage());
            }
        }else {
            System.debug('No Change Story records found for the specified Change Story.');
        }
    }
}