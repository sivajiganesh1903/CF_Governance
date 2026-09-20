public class AuditLogController {
    public List<Audit_Log_Report__c> auditLogRecords { get; set; }

    public AuditLogController() {
        // Query the Audit Log Report records and assign them to auditLogRecords
        auditLogRecords = [SELECT Date__c, User__c, Display__c, Section__c, Delegate_User__c FROM Audit_Log_Report__c];
    }
}