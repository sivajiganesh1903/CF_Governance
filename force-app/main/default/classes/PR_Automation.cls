public class PR_Automation {
    public static void createPullrequest(string depId){
        System.debug('Deployment Id: ++++++++' + depId);        
        // To Store Tech Lead Names
        List<String> techLeads = new List<string>();
        copado__Deployment__c deployment = [SELECT Id, Name, copado__Status__c, copado__Promotion__c FROM copado__Deployment__c 
                                            WHERE Id = :depId /*AND copado__Status__c = 'Draft'*/];
        System.debug('Deployment Record: +++++++ ' + deployment);
        // Get Git Promotion Step which is related to the Deployment
		copado__Step__c step = [SELECT Id, Name, copado__Type__c, copado__Branch__c, copado__Deployment__c, copado__Status__c 
                                FROM copado__Step__c WHERE copado__Deployment__c = :deployment.Id /*AND copado__CheckOnly__c = false*/ 
                                AND copado__Type__c = 'Git Promotion'];
        System.debug('Step Branch: ' + step.copado__Branch__c);
        string head = step.copado__Branch__c;
        System.debug('Header: ++++++' + head);
        //Get to To Credential Record
        copado__Destination_Org__c destOrg = [SELECT Id, Name, copado__Deployment__c, copado__To_Org__c FROM copado__Destination_Org__c WHERE copado__Deployment__c = 'a0d7e000006WP8FAAW'];
        System.debug('Destination Org: +++++++' + destOrg);
        // Base Branch from Git Snapshot
        copado__Git_Backup__c snapShot = [SELECT Id, Name, copado__Branch__c, copado__Org__c FROM copado__Git_Backup__c WHERE copado__Org__c = :destOrg.copado__To_Org__c];
        System.debug('Snapshot Record: ++++++' + snapShot);   
        string base = snapShot.copado__Branch__c;
        System.debug('Base: ++++++' + base);
        If(deployment.copado__Promotion__c != NULL){
            // Deployment Related Promotion Record
            List<copado__Promotion__c> promotions = [SELECT Id, Name, copado__Status__c, copado__Project__c FROM 
                                                     copado__Promotion__c WHERE Id = :deployment.copado__Promotion__c];
            System.debug('Promotion Records: +++++++ ' + promotions);           
            //Store Promotion Ids
            Set<Id> promotionIds = new Set<Id>();
            for (copado__Promotion__c promo : promotions) {
                promotionIds.add(promo.Id);
            }
            System.debug('Promotion Ids: +++++++ ' + promotionIds);            
            // Promotion Related Promoted User Stories
            List<copado__Promoted_User_Story__c> promotedUserStories = [SELECT Id, Name, copado__User_Story__c, copado__Status__c, 
                                                                        copado__Promotion__c FROM copado__Promoted_User_Story__c 
                                                                        WHERE copado__Promotion__c IN :promotionIds];
            System.debug('Promoted User Stories: +++++++ ' + promotedUserStories);
            
            Set<Id> userStoryIds = new Set<Id>();
            for(copado__Promoted_User_Story__c pus : promotedUserStories) {
                if(pus.copado__User_Story__c != null) {
                    userStoryIds.add(pus.copado__User_Story__c);
                }
            }
            System.debug('Promotion Ids: +++++++ ' + promotionIds); 
            // Collect User Stories
            List<copado__User_Story__c> userStories = [SELECT Id, Name, copado__Team__c FROM copado__User_Story__c 
                                                       WHERE Id IN :userStoryIds];
            System.debug('UserStories' + userStories);
            for(copado__User_Story__c story : userStories){
                if(story.copado__Team__c != NULL){
                    copado__Team__c teamLead = [SELECT Id, Name, Tech_Lead_Name__c FROM copado__Team__c WHERE Id = :story.copado__Team__c];
                    techLeads.add(teamLead.Tech_Lead_Name__c);
                }
            }
            System.debug('Tech Lead Names: +++++++' + techLeads);
        }
        
        string token = '';
        String URL = 'https://github-dmz.edwardjones.com/api/v3/repos/ej-fbs-salesforce/TrainingRepository/pulls';
        //String bodyJSON ='{"head": "feature/789","base": "int-789","title": "Automatic PR Approval-2","body": "Test PR-2"}';
        String bodyJSON = JSON.serialize(new Map<String, Object>{
            'head' => head,
            'base' => base,
            'title' => head + ' ' + base,
            'body' => 'Please Review the Changes'
        });

        System.debug('Constructed JSON Body: ' + bodyJSON);       
        System.debug('body of JSON :-' +bodyJSON);
        System.debug('token :-'+token);
        system.debug('URL :-'+URL);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' +token);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(bodyJSON);
        Http h = new Http();
        HttpResponse res = h.send(req);
        system.debug(res.getBody());
        
        String assignReviewerURL = 'https://github-dmz.edwardjones.com/api/v3/repos/ej-fbs-salesforce/TrainingRepository/pulls/{pull_number}/requested_reviewers';
        
        if(res.getStatusCode() == 201){
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Response Body: +++++' + responseMap);
            
            Integer pullNumber = (Integer) responseMap.get('number');
            System.debug('Pull Request created number: ' + pullNumber);
            
            // Assign Reviewer to the Pull Request
            String assignReviewerEndpoint = assignReviewerURL.replace('{pull_number}', String.valueOf(pullNumber));
            System.debug('Reviewr Endipoint URL: +++++' + assignReviewerEndpoint);
            //String reviewerPayload = '{"reviewers": ["DipaliMarotiLingayat"]}'; //'reviewer-username' is the GitHub username
            //System.debug('Reviewr Username: +++++' + reviewerPayload);
            
            String reviewerPayload = '{"reviewers": ' + JSON.serialize(techLeads) + '}'; //'reviewer-username' is the GitHub username
            
            
            HttpRequest reviewerRequest = new HttpRequest();
            reviewerRequest.setEndpoint(assignReviewerEndpoint);
            reviewerRequest.setMethod('POST');
            reviewerRequest.setHeader('Authorization', 'Bearer ' + token);
            reviewerRequest.setHeader('Content-Type', 'application/json');
            reviewerRequest.setBody(reviewerPayload);
            
            Http htpreview = new Http();
            HttpResponse reviewerResponse = htpreview.send(reviewerRequest);
            system.debug(reviewerResponse.getBody());
            if (reviewerResponse.getStatusCode() == 201 || reviewerResponse.getStatusCode() == 204) {
                System.debug('Reviewer assigned successfully.');
            } else {
                System.debug('Failed to assign reviewer. Status Code: ' + reviewerResponse.getStatusCode());
                System.debug('Response: ' + reviewerResponse.getBody());
            }          
        }else {
            System.debug('Pull Request Create Failed: ++++++ ' + res.getStatusCode());
            System.debug('Response: ' + res.getBody());
        }
    } 
}