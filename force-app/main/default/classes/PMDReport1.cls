public class PMDReport1 {
    @future(callout=true) 
    public static void orgscan() { 
        // Query the copado__Org__c records which has Weekly_PMD_Report__c = true
      /*  List<copado__Org__c> orgs = [SELECT Id, Name, Weekly_PMD_Report__c, branch__c FROM copado__Org__c 
                                     WHERE Weekly_PMD_Report__c = true WITH SECURITY_ENFORCED];
        Userstorysfsca.dispatchOrgScan(orgs);  */
    }  
}