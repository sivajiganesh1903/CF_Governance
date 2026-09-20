public with sharing class tasktracker {
    public static void taskCreate(Id jobStepId) {
        /*
        // List to hold new records to be inserted
        List<Deployment_Task_Tracker__c> recordsToInsert = new List<Deployment_Task_Tracker__c>(); */
        Deployment_Task_Tracker__c newRecord = new Deployment_Task_Tracker__c();

        // Query the copado__Step__c object based on the provided jobStepId
        copado__Step__c step = [SELECT Id, Name, copado__Status__c, Validated_By__c,copado__Type__c,
                                Validation_Request__c, Permormed_by__c,copado__Deployment__r.copado__Promotion__r.copado__Destination_Environment__r.name
                                FROM copado__Step__c 
                                WHERE Id = :jobStepId];

        System.debug('Step details: ' + step);
        if (step.copado__Status__c == 'Completed Successfully' && step.copado__Type__c == 'Manual Task'){
            System.debug('completed success record is fetched');
            newRecord.task_name__C = step.name;
            newRecord.Environment__c = step.copado__Deployment__r.copado__Promotion__r.copado__Destination_Environment__c;
            newRecord.Performed_by__c = step.Permormed_by__c;
            newRecord.Validated_By__c = step.Validated_By__c;
        }
        else{
            System.debug('not compeleted successfully');
        }
        System.debug('Insert Record ===  '+newRecord);
        Insert newRecord;
        }
    }