public class AuditLogReport {

    public static void createAuditLogReports() {
        
    	List<Audit_Log_Report__c> auditLogReportsToInsert = new List<Audit_Log_Report__c>();
    
        // Query the data from SetupAuditTrail
        List<SetupAuditTrail> auditTrailRecords = [SELECT Id, CreatedDate, CreatedBy.Name, Section, Action, DelegateUser, Display
                                                        FROM SetupAuditTrail
                                                        WHERE CreatedDate = LAST_N_DAYS:7];
    
        // Loop through the queried records and create Audit Log Report records
        for (SetupAuditTrail auditTrailRecord : auditTrailRecords){
            
        	Audit_Log_Report__c auditLogReport = new Audit_Log_Report__c();
            
            auditLogReport.Date__c = auditTrailRecord.CreatedDate;
            auditLogReport.User__c = auditTrailRecord.CreatedBy.Name;
            auditLogReport.Section__c = auditTrailRecord.Section;
            auditLogReport.Delegate_User__c = auditTrailRecord.DelegateUser;
            auditLogReport.Display__c = auditTrailRecord.Display;
                
            auditLogReportsToInsert.add(auditLogReport);
        }
    	
        // Insert the Audit Log Report records
        if (!auditLogReportsToInsert.isEmpty()) {
            Database.insert(auditLogReportsToInsert, false);
       	}
        
	}

}