public class SCAScanHandler {
    public static void handleAfterInsert(List<copado__Static_Code_Analysis_Result__c> newSCAResults) {
        // Get TrnProd Org Id from Custom Label
        Id trnProdOrgId;
        try {
            trnProdOrgId = Label.Prod_Credential;
            System.debug('Org Id from Custom Label: ++++' + trnProdOrgId);
        } catch (Exception e) {
            System.debug('Error retrieving Org Id from Custom Label: ' + e.getMessage());
            return;
        }
        
        // Collect SCA Result record Ids
        Set<Id> SCAIds = new Set<Id>();
        for (copado__Static_Code_Analysis_Result__c scaResult : newSCAResults) {
            SCAIds.add(scaResult.Id);            
        }
        System.debug('SCA Result record Ids: ++++' + SCAIds);
        
        // Query the latest SCA record for trnProd Org
        copado__Static_Code_Analysis_Result__c latestSCAResult;
        try {
            latestSCAResult = [SELECT Id, Name, CreatedDate, copado__Org_Credential__c FROM copado__Static_Code_Analysis_Result__c 
                               WHERE copado__Org_Credential__c = :trnProdOrgId AND Id IN :SCAIds ORDER BY CreatedDate DESC LIMIT 1];
            System.debug('Latest SCA Result: ++++' + latestSCAResult);
        } catch (Exception e) {
            System.debug('Error querying the latest SCA Result: ' + e.getMessage());
            return;
        }
        
        if (latestSCAResult != null) {
            List<copado__Static_Code_Analysis_Result__c> scaRecords;
            try {
                scaRecords = [SELECT Id, Name, copado__Critical__c, copado__Highest_Priority_Violation__c, 
                              copado__Score_v11__c, copado__Number_of_Violations__c, 
                              copado__Org_Credential__c, copado__Org_Credential__r.Name, CreatedDate 
                              FROM copado__Static_Code_Analysis_Result__c WHERE 
                              copado__Org_Credential__c = :trnProdOrgId ORDER BY CreatedDate DESC LIMIT 2];
                System.debug('Latest SCA Records: +++' + scaRecords);
            } catch (Exception e) {
                System.debug('Error querying SCA records: ' + e.getMessage());
                return;
            }
            
            if (scaRecords != null && scaRecords.size() > 1) {
                try {
                    Release_Playbook_Sub_Item__c subItemToUpdate = [SELECT Id, Name, Previous_SCA__c, Static_Code_Analysis_Result__c,
                                                                    SCA_Execution_Time__c FROM Release_Playbook_Sub_Item__c 
                                                                    WHERE Previous_SCA__c = :scaRecords[1].Name LIMIT 1];
                    System.debug('Release Playbook Sub Item to Update: ++++' + subItemToUpdate);
                    
                    // Update the Static_Code_Analysis_Result__c field with the latest SCA Result Id
                    subItemToUpdate.Static_Code_Analysis_Result__c = latestSCAResult.Id;
                    subItemToUpdate.SCA_Execution_Time__c = DateTime.now();
                    update subItemToUpdate;
                    System.debug('Updated Release Playbook Sub Item with latest SCA Result Id.');
                } catch (Exception e) {
                    System.debug('Error updating Release Playbook Sub Item: ' + e.getMessage());
                }
            } else {
                System.debug('Not enough SCA records to find the previous record for comparison.');
            }
        } else {
            System.debug('No latest SCA Result found.');
        }
    }
}