public with sharing class CommitAfterBackPromotion {
    //@InvocableMethod (label='Commit After Back Promotion' description='Validate if the components are committed to feature branch after back promotion completed')
    /*
    ustory - requested user story
    metadataApiNames - Metadata apiname set from SCMUserStroyController
    metadataTypes - Metadata types set from SCMUserStroyController
    */

    public static boolean getCommitStatus(copado__User_Story__c ustory,Set<String> metadataApiNames, Set<String> metadataTypes){
        Boolean commitstatus= false;
        Set<String> ustoryids = new Set<String>();
        DateTime latstBPR ;
        List<Back_Promoted_Result__c> bprclist = new List<Back_Promoted_Result__c>();
        List<copado__User_Story_Metadata__c> metadatalist = new List<copado__User_Story_Metadata__c>();
        try{
            bprclist = [ SELECT Id, Name, BackPromoted_Userstory__c, BackPromotionSuccessTimeStamp__c FROM Back_Promoted_Result__c WHERE User_Story__c = :ustory.Id AND BackPromotionSuccessTimeStamp__c!=null WITH SECURITY_ENFORCED order by BackPromotionSuccessTimeStamp__c DESC ];
            for(Back_Promoted_Result__c bprc : bprclist){
                ustoryids.add(bprc.BackPromoted_Userstory__c);
                system.debug('bprc.BackPromoted_Userstory__c: ' + bprc.BackPromoted_Userstory__c);
            }
            metadatalist = [ SELECT Id, Name, API_Name__c, copado__Type__c, copado__Metadata_API_Name__c FROM copado__User_Story_Metadata__c WHERE API_Name__c IN :metadataApiNames AND copado__Type__c  IN :metadataTypes AND copado__User_Story__c IN :ustoryids WITH SECURITY_ENFORCED ];
            latstBPR = bprclist[0].BackPromotionSuccessTimeStamp__c;
            system.debug('latstBPR: ' + latstBPR);
            //get last commitdate
            commitstatus = [ SELECT Id, Name, copado__Latest_Commit_Date__c FROM copado__User_Story__c WHERE Id=:ustory.Id WITH USER_MODE LIMIT 1].copado__Latest_Commit_Date__c>latstBPR ? true:false;

        }
        Catch(Exception e){
            commitstatus= false;
            System.debug('Error ====='+e.getMessage());
        }

        return commitstatus;

    }
}