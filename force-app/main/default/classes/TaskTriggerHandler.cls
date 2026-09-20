public with sharing class TaskTriggerHandler {
    
    @AuraEnabled
    public static void handletask (List<task> UpdtTaskMap,Map<Id, task> oldTaskMap) {
        
         // Create a list to hold the Task_Log__c records that need to be updated
        List<Task_Log__c> taskLogsToUpdate = new List<Task_Log__c>();   

        for (task updttask : UpdtTaskMap) {

            Task_Log__c newTaskLog = new Task_Log__c();
            Task oldTask = oldTaskMap.get(updttask.Id);
            id taskid = updttask.whatid;
            // Query Task_Log__c records with Status__c as 'Open'
            List<Task_Log__c> taskLogs = [SELECT Id, Status__c FROM Task_Log__c WHERE User_Story__c = : updttask.whatid AND Status__c ='Open'];
            
            System.debug('On Hold ====='+taskLogs);
            //Create a Task Log
                if (updttask.Status == 'In Progress' && oldTask.status != 'In Progress') {
                    //Check for the Task Log Already Exist on the Task for the Environment  
                    if (taskLogs.isEmpty()){
                    newTaskLog.user_story__C = updttask.whatid;
                    newTaskLog.Task_ID__C = updttask.id;
                    newTaskLog.Status__c = 'Open';
                    insert newTaskLog;
                }
                Else if (!taskLogs.isEmpty()){
                    updttask.addError('A Task Log Already exist for this task. Please close it before opening another task log on this.');
                }
            }

        //Update a Task Log to Hand Off
            else if (updttask.Status == 'On Hold' && oldTask.status != 'On Hold'){
                for (Task_Log__c taskLog : taskLogs) {
                    taskLog.Status__c = 'Hand Off';
                    taskLog.Hand_Off__c = System.now();
                    taskLogsToUpdate.add(taskLog);
                }
            }
                    //Update a Task Log to Complete
        else if (updttask.Status == 'Completed' && oldTask.status != 'Completed'){
            for (Task_Log__c taskLog : taskLogs) {
                taskLog.Status__c = 'Completed';
                taskLog.Completed_Time__c = System.now();
                taskLogsToUpdate.add(taskLog);
            }
        }
        }
        // Perform the DML operation to update the Task_Log__c records
        if (!taskLogsToUpdate.isEmpty()) {
            try {
                update taskLogsToUpdate;
            } catch (DmlException e) {
                System.debug('An error occurred while updating Task_Log__c records: ' + e.getMessage());
            }
        }
    }
}