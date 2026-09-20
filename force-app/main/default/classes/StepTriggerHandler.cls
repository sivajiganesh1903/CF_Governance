public class StepTriggerHandler {
    
    public static void handleTrigger(List<copado__Step__c> steps) {
        Set<Id> deploymentIds = new Set<Id>();
        for (copado__Step__c step : steps) {
            if (step.copado__Type__c == 'Git Promotion' && step.copado__Deployment__c != null) {
                deploymentIds.add(step.copado__Deployment__c);
            }
        }
        System.debug('Step Deployment Id: +++++' + deploymentIds);
        if (deploymentIds.isEmpty()) {
            return;
        }
        
        Map<Id, copado__Deployment__c> deploymentMap = new Map<Id, copado__Deployment__c>(
            [SELECT Id, Name, copado__Status__c, copado__Promotion__c FROM copado__Deployment__c WHERE Id IN :deploymentIds 
             AND copado__Status__c = 'Draft' AND copado__Promotion__r.copado__Destination_Environment__r.Enable_PR_Approval__c = true]);
        System.debug('Pull Request Conditions' + deploymentMap);
        for (copado__Step__c step : steps) {
            if (deploymentMap.containsKey(step.copado__Deployment__c)) {
                processGitPromotionStep(step.copado__Deployment__c);
            }
        }
    }
    @future(callout = true)
    private static void processGitPromotionStep(String depId) {
        String repo_path = 'api/v3/repos/ej-fbs-salesforce/TrainingRepository/pulls';
        // Captures Tech Lead Names
        List<String> techLeads = new List<String>();
        copado__Deployment__c deployment = [SELECT Id, Name, copado__Status__c, copado__Promotion__c, copado__Promotion__r.Name,
                                            copado__Promotion__r.copado__Source_Environment__c,
                                            copado__Promotion__r.copado__Destination_Environment__c,
                                            copado__Promotion__r.copado__Project__r.copado__Deployment_Flow__c
                                            FROM copado__Deployment__c WHERE Id = :depId];
        System.debug('Deployment Record: +++++' + deployment);
        System.debug('Promotion: ' + deployment.copado__Promotion__r);
        System.debug('Project Flow: ' + deployment.copado__Promotion__r.copado__Project__r.copado__Deployment_Flow__c);
        copado__Deployment_Flow_Step__c pipelineConnection = [SELECT Id, copado__Source_Environment__c, copado__Destination_Environment__c,
                                                              copado__Branch__c FROM copado__Deployment_Flow_Step__c WHERE 
                                                              copado__Deployment_Flow__c = :deployment.copado__Promotion__r.copado__Project__r.copado__Deployment_Flow__c
                                                              AND copado__Source_Environment__c = :deployment.copado__Promotion__r.copado__Destination_Environment__c
                                                              LIMIT 1];
        System.debug('Pipeline Connection: +++++ ' + pipelineConnection);
        String base = pipelineConnection.copado__Branch__c;
        System.debug('Base branch: +++++' + base); 
        
        copado__Step__c step = [SELECT Id, Name, copado__Type__c, copado__Branch__c, copado__Deployment__c, 
                                copado__Status__c FROM copado__Step__c WHERE copado__Deployment__c = :deployment.Id 
                                AND copado__Type__c = 'Git Promotion' AND copado__CheckOnly__c = false LIMIT 1];
        System.debug('Deployment Step: +++++' + step);
        String head = step.copado__Branch__c;
        System.debug('Step Head: +++++' + head); 
        
        if (deployment.copado__Promotion__c != null) {
            List<copado__Promotion__c> promotions = [SELECT Id, Name, copado__Status__c, copado__Project__c 
                                                     FROM copado__Promotion__c WHERE Id = :deployment.copado__Promotion__c];
            System.debug('Promotion: +++++' + promotions);
            Set<Id> promotionIds = new Set<Id>();
            for (copado__Promotion__c promo : promotions) {
                promotionIds.add(promo.Id);
            }
            System.debug('Promotion Ids: +++++' + promotionIds);
            List<copado__Promoted_User_Story__c> promotedUserStories = [SELECT Id, Name, copado__User_Story__c, copado__Status__c, 
                                                                        copado__Promotion__c FROM copado__Promoted_User_Story__c 
                                                                        WHERE copado__Promotion__c IN :promotionIds];
            System.debug('Promoted User Stories: +++++' + promotedUserStories);
            Set<Id> userStoryIds = new Set<Id>();
            for (copado__Promoted_User_Story__c pus : promotedUserStories) {
                if (pus.copado__User_Story__c != null) {
                    userStoryIds.add(pus.copado__User_Story__c);
                }
            }
            System.debug('Promoted User Stories: +++++' + userStoryIds);
            List<copado__User_Story__c> userStories = [SELECT Id, Name, copado__Team__c FROM copado__User_Story__c 
                                                       WHERE Id IN :userStoryIds];
            System.debug('User Stories: +++++' + userStories);
            for (copado__User_Story__c story : userStories) {
                if (story.copado__Team__c != null) {
                    copado__Team__c teamLead = [SELECT Id, Name, Tech_Lead_Name__c FROM copado__Team__c 
                                                WHERE Id = :story.copado__Team__c];
                    //techLeads.add(teamLead.Tech_Lead_Name__c);
                    techLeads.addAll(teamLead.Tech_Lead_Name__c.split(','));
                }
            }
        }
        System.debug('Tech Leads: +++++' + techLeads);
        
        String URL = 'callout:EDJ_GitHub_Enterprise/' + repo_path;
        String bodyJSON = JSON.serialize(new Map<String, Object>{'head' => head, 'base' => base, 
            'title' => head + ' ' + base, 'body' => 'Please Review the Changes'});
        System.debug('Constructed JSON Body: ' + bodyJSON);       
        System.debug('body of JSON :-' +bodyJSON);
        System.debug('URL :-'+URL);
        
        // Create Pull request Callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(bodyJSON);
        Http h = new Http();
        HttpResponse res = h.send(req);
        system.debug(res.getBody());
        system.debug(res.getStatusCode());
        
        if (res.getStatusCode() == 201) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Integer pullNumber = (Integer) responseMap.get('number');
            String assignReviewerURL = 'callout:EDJ_GitHub_Enterprise/' + repo_path + '/{pull_number}/requested_reviewers';
            String assignReviewerEndpoint = assignReviewerURL.replace('{pull_number}', String.valueOf(pullNumber));
            String reviewerPayload = '{"reviewers": ' + JSON.serialize(techLeads) + '}';
            System.debug('payLoad: ++++' + reviewerPayload);
            //Create Reviewer assign callout
            HttpRequest reviewerRequest = new HttpRequest();
            reviewerRequest.setEndpoint(assignReviewerEndpoint);
            reviewerRequest.setMethod('POST');
            reviewerRequest.setHeader('Content-Type', 'application/json');
            reviewerRequest.setBody(reviewerPayload);
            HttpResponse reviewerResponse = h.send(reviewerRequest);
            system.debug(reviewerResponse.getBody());
            system.debug(reviewerResponse.getStatusCode());
            if (reviewerResponse.getStatusCode() == 201 || reviewerResponse.getStatusCode() == 204) {
                System.debug('Reviewer assigned successfully.');
            } else {
                System.debug('Failed to assign reviewer. Status Code: ' + reviewerResponse.getStatusCode());
                System.debug('Response: ' + reviewerResponse.getBody());
            } 
        }
    }
}