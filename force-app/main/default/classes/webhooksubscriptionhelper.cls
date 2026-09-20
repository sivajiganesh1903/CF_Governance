public without sharing class webhooksubscriptionhelper {
    public static void opened(Map<String,Object> pull_request_res) {
        system.debug('pull_request_res ===='+pull_request_res);
        
        Map<String, Object> res = (Map<String, Object>) pull_request_res.get('pull_request');
        System.debug('pull_request_res=====   '  +res); 
        List<copado__Promoted_User_Story__c> pus = new List<copado__Promoted_User_Story__c>();
        List<copado__Pull_Request__c> pullRequests = new List<copado__Pull_Request__c>();
        
        String extractedText;
        //system.debug('res ===='+res);
        //parse base sections
        Map<String, Object> base = (Map<String, Object>) res.get('base');
        System.debug('pull_request_res=====   '  +base); 
        Map<String, Object> userPR = (Map<String, Object>) res.get('user');
        System.debug('pull_request_res=====   '  +userPR);  
        //parse head section of payload
        Map<String, Object> pR = (Map<String, Object>) res.get('pullRequest');
        system.debug('pR ====='+pR);
        Map<String, Object> head = (Map<String, Object>) res.get('head');
        system.debug('head ===='+head);
        //promotion/P08958-DeployP08958TrnInt1
        string sourcebranch = head.get('ref').toString();
        system.debug('hesourcebranchad ===='+sourcebranch);
        // Split the string by '/'
        List<String> parts = sourcebranch.split('/');
        
        // Check if there are at least two parts after the split
        if(parts.size() > 1) {
            // Split the second part by '-'
            List<String> subParts = parts[1].split('-');
            // Check if there is at least one part after the split
            if(subParts.size() > 0) {
                extractedText = subParts[0];
            }
        }
        system.debug('Extracted Test ++++ ' + extractedText);
        //System.debug('copado__Promoted_User_Story__c isAccessible? ' + Schema.sObjectType.copado__Promoted_User_Story__c.isAccessible());
        //System.debug('copado__Pull_Request__c creatable? ' + Schema.sObjectType.copado__Pull_Request__c.isCreateable());
        if (!Schema.sObjectType.copado__Promoted_User_Story__c.isAccessible()) {
            system.debug('copado__Promoted_User_Story__c is not accessable');
            return;
        }
        
        if (!Schema.sObjectType.copado__Pull_Request__c.isCreateable()) {
            system.debug('copado__Pull_Request__c is not creatable');
            return;
        }

        System.debug('copado__Promoted_User_Story__c.fields.Name.isAccessible() = ' + Schema.sObjectType.copado__Promoted_User_Story__c.fields.Name.isAccessible());
        System.debug('copado__Promoted_User_Story__c.fields.copado__User_Story__c.isAccessible() = ' + Schema.sObjectType.copado__Promoted_User_Story__c.fields.copado__User_Story__c.isAccessible());
        System.debug('copado__Promoted_User_Story__c.fields.copado__Promotion__c.isAccessible() = ' + Schema.sObjectType.copado__Promoted_User_Story__c.fields.copado__Promotion__c.isAccessible());
        System.debug('copado__Promoted_User_Story__c.fields.copado__Status__c.isAccessible() = '+ Schema.sObjectType.copado__Promoted_User_Story__c.fields.copado__Status__c.isAccessible());
        if (Schema.sObjectType.copado__Promoted_User_Story__c.fields.Name.isAccessible() &&
        Schema.sObjectType.copado__Promoted_User_Story__c.fields.copado__User_Story__c.isAccessible() &&
        Schema.sObjectType.copado__Promoted_User_Story__c.fields.copado__Promotion__c.isAccessible() &&
        Schema.sObjectType.copado__Promoted_User_Story__c.fields.copado__Status__c.isAccessible()) {
            if (Test.isRunningTest()) {
                pus = [SELECT Id, Name, copado__User_Story__c, copado__Promotion__c, copado__Status__c 
                        FROM copado__Promoted_User_Story__c 
                        LIMIT 10000];
            } else {
                pus = [SELECT Id, Name, copado__User_Story__c, copado__Promotion__c, copado__Status__c 
                        FROM copado__Promoted_User_Story__c 
                        WHERE copado__Promotion__r.Name = :extractedText 
                        AND copado__Status__c = 'Active'];
            }
        }

        System.debug('Fetched PUS Records: ' + pus);

        // Check if Pull_Request object is creatable and we have PUS records
        if (!pus.isEmpty()) {
            for (copado__Promoted_User_Story__c pu : pus) {
                copado__Pull_Request__c pullRequest = new copado__Pull_Request__c();
                if(Schema.sObjectType.copado__Pull_Request__c.fields.copado__User_Story__c.isCreateable()) {
                    pullRequest.copado__User_Story__c = pu.copado__User_Story__c;
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__State__c.isCreateable()) {
                    pullRequest.copado__State__c = String.valueOf(res.get('state'));
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.Name.isCreateable()) {
                    pullRequest.Name = String.valueOf(res.get('title'));
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Request_Number__c.isCreateable()) {
                    pullRequest.copado__Request_Number__c = (Decimal) res.get('number');
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Url__c.isCreateable()) {
                    pullRequest.copado__Url__c = String.valueOf(res.get('html_url'));
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Changed_Files__c.isCreateable()) {
                    pullRequest.copado__Changed_Files__c = (Decimal) res.get('changed_files'); 
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Commits__c.isCreateable()) {
                    pullRequest.copado__Commits__c = (Decimal) res.get('commits');
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Target_Branch__c.isCreateable()) {
                    pullRequest.copado__Target_Branch__c = String.valueOf(base.get('ref'));
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Username__c.isCreateable()) {
                    pullRequest.copado__Username__c = String.valueOf(userPR.get('login'));
                }
                if (Schema.sObjectType.copado__Pull_Request__c.fields.branch_name__c.isCreateable()) {
                     pullRequest.branch_name__c = sourcebranch;
                }
                pullRequests.add(pullRequest);
            }

            if (!pullRequests.isEmpty() && Schema.sObjectType.copado__Pull_Request__c.isCreateable()) {
                insert pullRequests;
            }
        }
    }
    
    public static void submitted(Map<String, Object> res, String xId, Map<String, Object> prRes) {

        Map<String, Object> userRes = (Map<String, Object>) res.get('user');
        String prUrl = String.valueOf(prRes.get('html_url'));
        List<copado__Pull_Request__c> prRawList = new List<copado__Pull_Request__c>();
        if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Url__c.isAccessible() &&
        Schema.sObjectType.copado__Pull_Request__c.fields.Pull_Request_Approved__c.isAccessible()) {
            // Query Pull Requests
            prRawList = [
                SELECT Id, copado__Url__c, Pull_Request_Approved__c 
                FROM copado__Pull_Request__c
                WHERE copado__Url__c = :prUrl 
                ORDER BY CreatedDate DESC
            ];
        }

        // Strip inaccessible fields from query result
        List<copado__Pull_Request__c> prList = Security.stripInaccessible(AccessType.READABLE, prRawList).getRecords();

        List<copado__Pull_Request_Review__c> prReviewsToInsert = new List<copado__Pull_Request_Review__c>();
        List<copado__Pull_Request__c> prsToUpdate = new List<copado__Pull_Request__c>();

        if(!prList.isEmpty()){
            for (copado__Pull_Request__c pr : prList) {
                copado__Pull_Request_Review__c pRR = new copado__Pull_Request_Review__c();
                if (Schema.sObjectType.copado__Pull_Request_Review__c.fields.copado__Pull_Request__c.isCreateable())
                {
                 pRR.copado__Pull_Request__c = pr.Id;
                }
                if (Schema.sObjectType.copado__Pull_Request_Review__c.fields.Reviewer_Id__c.isCreateable() )
                {
                pRR.Reviewer_Id__c = xId;
                }
                if (Schema.sObjectType.copado__Pull_Request_Review__c.fields.copado__User_Avatar_Url__c.isCreateable() )
                {
                pRR.copado__User_Avatar_Url__c = String.valueOf(userRes.get('avatar_url'));
                }
                if (Schema.sObjectType.copado__Pull_Request_Review__c.fields.copado__Username__c.isCreateable() )
                {
                pRR.copado__Username__c = String.valueOf(userRes.get('login'));
                }
                if (Schema.sObjectType.copado__Pull_Request_Review__c.fields.copado__Review_Action__c.isCreateable() )
                {
                pRR.copado__Review_Action__c = String.valueOf(res.get('state'));
                }
                if (Schema.sObjectType.copado__Pull_Request_Review__c.fields.copado__Url__c.isCreateable() )
                {
                pRR.copado__Url__c = String.valueOf(res.get('state'));
                }
            
            	prReviewsToInsert.add(pRR);

                if (pRR.copado__Review_Action__c == 'approved'){
                    if(Schema.sObjectType.copado__Pull_Request__c.fields.Pull_Request_Approved__c.isUpdateable()) {
                        pr.Pull_Request_Approved__c = true;
                        prsToUpdate.add(pr);
                    }
                }
            }
        }
        if (Schema.sObjectType.copado__Pull_Request__c.isCreateable()){
            insert prReviewsToInsert;
        }

        if (Schema.sObjectType.copado__Pull_Request__c.isUpdateable()) {
            update prsToUpdate;
        }
        
    }
    
    public static void closed(Map<String, Object> res) {

        String prUrl = String.valueOf(res.get('html_url'));
        String mergeCheck = String.valueOf(res.get('merged'));
        Map<String, Object> userPR = (Map<String, Object>) res.get('user');
        List<copado__Pull_Request__c> prRawList = new List<copado__Pull_Request__c>();
        if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Url__c.isAccessible() &&
        Schema.sObjectType.copado__Pull_Request__c.fields.copado__State__c.isAccessible() &&
        Schema.sObjectType.copado__Pull_Request__c.fields.copado__Merged__c.isAccessible() &&
        Schema.sObjectType.copado__Pull_Request__c.fields.copado__Merged_By__c.isAccessible()) {
        // Query Pull Requests matching the URL
        prRawList = [
            SELECT Id, copado__Url__c, copado__State__c, copado__Merged__c, copado__Merged_By__c 
            FROM copado__Pull_Request__c 
            WHERE copado__Url__c = :prUrl 
            ORDER BY CreatedDate DESC
        ];
        }

        List<copado__Pull_Request__c> prListToUpdate = new List<copado__Pull_Request__c>();
        if (prRawList.size() > 0)
            {
                for (copado__Pull_Request__c pr : prRawList) {
                    if (mergeCheck == 'true') {
                        if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__State__c.isUpdateable() )  
                        {
                            pr.copado__State__c = 'Merged';
                        }
                        if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Merged__c.isUpdateable() )  
                        {
                            pr.copado__Merged__c = true;
                        }
                        if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__Merged_By__c.isUpdateable() )  
                        {
                            pr.copado__Merged_By__c = String.valueOf(userPR.get('login'));
                        }
                    } 
                    else 
                        if (Schema.sObjectType.copado__Pull_Request__c.fields.copado__State__c.isUpdateable() )  
                        {
                            pr.copado__State__c = String.valueOf(res.get('state'));
                        }
                    prListToUpdate.add(pr);
                }
            }

        if (!prListToUpdate.isEmpty()) {
            if(Schema.sObjectType.copado__Pull_Request__c.isUpdateable()){
                update prListToUpdate; 
            }
        }
    }
}