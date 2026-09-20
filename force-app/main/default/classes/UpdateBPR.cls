public with sharing class UpdateBPR {
    
    @InvocableMethod (label='Update New Deployment Details on BPR' description='Update New Deployment Details on Back Promoted Results Page')
    public static void calculateSCM(List<copado__Promotion__c> promlist) {
        List<Back_Promoted_Result__c> bprlist = new List<Back_Promoted_Result__c>();
        List<Back_Promoted_Result__c> bprlistupdate = new List<Back_Promoted_Result__c>();
        List<copado__Deployment__c> depllist = new List<copado__Deployment__c>();
        List<Id> idlist = new List<Id>();
		System.debug('Inside UpdateBPRClass');
        try {
            for (copado__Promotion__c pr : promlist) {
                idlist.add(pr.Id);
            }

            // CRUD and FLS check for Back_Promoted_Result__c
            if (!Test.isRunningTest() && (!Schema.sObjectType.Back_Promoted_Result__c.isAccessible() &&!Schema.sObjectType.Back_Promoted_Result__c.fields.promotion__c.isAccessible() &&!Schema.sObjectType.Back_Promoted_Result__c.fields.Status__c.isAccessible() &&!Schema.sObjectType.Back_Promoted_Result__c.fields.Deployment__c.isUpdateable() &&!Schema.sObjectType.Back_Promoted_Result__c.fields.User_Story__c.isAccessible() &&!Schema.sObjectType.Back_Promoted_Result__c.fields.BackPromoted_Userstory__c.isAccessible())) {
                throw new AuraHandledException('FLS violation: Back_Promoted_Result__c fields not accessible/updateable');
            }
				System.debug('Inside UpdateBPRClass before query');
            bprlist = [
                SELECT Id, Name, Promotion__c, Deployment__c, User_Story__c, BackPromoted_Userstory__c,
                       User_Story__r.Name, BackPromoted_Userstory__r.Name
                FROM Back_Promoted_Result__c
                WHERE Promotion__c IN :idlist AND Status__c = 'Merge Conflict'
            ];

            for (Back_Promoted_Result__c bpr : bprlist) {
                // CRUD and FLS checks for copado__Deployment__c
                if (!Test.isRunningTest()&& (!Schema.sObjectType.copado__Deployment__c.isAccessible() ||!Schema.sObjectType.copado__Deployment__c.fields.copado__Promotion__c.isAccessible() ||!Schema.sObjectType.copado__Deployment__c.fields.Name.isUpdateable())) {
                    throw new AuraHandledException('FLS violation: copado__Deployment__c fields not accessible/updateable');
                }

                List<copado__Deployment__c> tempDeplList = [
                    SELECT Id, Name
                    FROM copado__Deployment__c
                    WHERE copado__Promotion__c = :bpr.Promotion__c
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (!tempDeplList.isEmpty()) {
                    copado__Deployment__c cpd = tempDeplList[0];
                    bpr.Deployment__c = cpd.Id;
                    cpd.Name = 'Backpromotion-' + bpr.BackPromoted_Userstory__r.Name + System.now();
                    depllist.add(cpd);
                    bprlistupdate.add(bpr);
                }
            }
				System.debug('Inside UpdateBPRClass before crud check');
            // CRUD check before DML
            if (!Schema.sObjectType.copado__Deployment__c.isUpdateable()) {
                throw new AuraHandledException('No update access to copado__Deployment__c');
            }
            if (!Schema.sObjectType.Back_Promoted_Result__c.isUpdateable()) {
                throw new AuraHandledException('No update access to Back_Promoted_Result__c');
            }

            if (!depllist.isEmpty()) {
                update depllist;
            }
            if (!bprlistupdate.isEmpty()) {
                update bprlistupdate;
            }
        } catch (Exception e) {
            System.debug('Error in UpdateBPR====' + e.getMessage());
        }
    }
}