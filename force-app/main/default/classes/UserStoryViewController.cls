public class UserStoryViewController {
    @AuraEnabled(cacheable=true)
    public static List<TaskWrapper> getTasks() {
        List<Task> taskList = [SELECT Id, Subject, Environment__c, Environment__r.Name, Status, Jira_Key__c, Priority, 
                               WhatId, What.Name FROM Task WHERE Environment__r.Name IN ('TrnUat', 'trnProd') AND 
                               Status IN ('Open', 'In progress') AND CreatedDate = LAST_N_DAYS:2];
        
        List<TaskWrapper> result = new List<TaskWrapper>();
        for (Task t : taskList) {
            result.add(new TaskWrapper(
                t.Id, t.WhatId, t.What.Name, t.Environment__r.Name, t.Status
            ));
        }
        return result;
    }
    
    public class TaskWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String whatId;
        @AuraEnabled public String whatName;
        @AuraEnabled public String environment;
        @AuraEnabled public String status;
        
        public TaskWrapper(String id, String whatId, String whatName, String environment, String status) {
            this.id = id;
            this.whatId = whatId;
            this.whatName = whatName;
            this.environment = environment;
            this.status = status;
        }
    }
}