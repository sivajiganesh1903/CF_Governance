trigger AuditLogReport on Audit_Log_Report__c (before insert) {
	IF(TRIGGER.isBefore){
        system.debug('trigger before trigger'); 
 
        IF(TRIGGER.isInsert){
            set<String> auditIdentifier = NEW set<String>();
            FOR(Audit_Log_Report__c a:TRIGGER.new){
                auditIdentifier.add(a.Identifier__c);
                System.debug('Audit log Identifier number is ' +auditIdentifier);
 
            }
            set<String> IdentifierData = NEW set<String>();
            FOR(Audit_Log_Report__c a:[SELECT Id,Date__c,Identifier__c FROM Audit_Log_Report__c WHERE Identifier__c IN:auditIdentifier]){
                IdentifierData.add(a.Identifier__c);
 
            }
            FOR(Audit_Log_Report__c a:TRIGGER.new){
                IF(IdentifierData.contains(a.Identifier__c)){
                    a.addError('Duplicate Record found!');
                }
            }
        }
    }
    ELSE IF(TRIGGER.isAfter){
        system.debug('trigger after trigger');        
    }
}