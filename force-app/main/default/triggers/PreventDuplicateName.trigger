trigger PreventDuplicateName on copado__Deployment_Task__c (before insert, before update) {
    for(copado__Deployment_Task__c record :trigger.new){
        DuplicateNameValidator.validateDuplicateName(record);
    }
}