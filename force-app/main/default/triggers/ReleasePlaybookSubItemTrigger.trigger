trigger ReleasePlaybookSubItemTrigger on Release_Playbook_Sub_Item__c (after update) {
   /* if (Trigger.isAfter && Trigger.isUpdate) {
        List<Release_Playbook_Sub_Item__c> updatedGitSnapshots = new List<Release_Playbook_Sub_Item__c>();
        for(Release_Playbook_Sub_Item__c subItem : Trigger.new) {
            Release_Playbook_Sub_Item__c oldSubItem = Trigger.oldMap.get(subItem.Id);
            //Move below Logic to helper------>
            if(subItem.Snapshot_Commit__c != oldSubItem.Snapshot_Commit__c) {
                ReleasePlaybookHelper.processReleasePlaybookSubItem15(subItem.Id);
            }
            if(subItem.Deployment__c != oldSubItem.Deployment__c) {
                ReleasePlaybookHelper.processReleasePlaybookSubItems(subItem.Id);
                ReleasePlaybookHelper.processReleasePlaybookSubItem11(subItem.Id);
                ReleasePlaybookHelper.processReleasePlaybookSubItem6(subItem.Id);
            }
            if(subItem.Promotion__c != oldSubItem.Promotion__c) {
                ReleasePlaybookHelper.processReleasePlaybookSubItem8(subItem.Id);
                ReleasePlaybookHelper.processReleasePlaybookSubItem2(subItem.Id);
            }
            If(subItem.Static_Code_Analysis_Result__c != NULL && subItem.SCA_Execution_Time__c != NULL){
                ReleasePlaybookHelper.rpbTimeUpadation(subItem.Id);
            }
            //<-----STOP HERE
        }
    }  */ 
}