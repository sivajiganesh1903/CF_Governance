public without sharing class UserAccessManagementController {
    //User Access Management
    @AuraEnabled
    public static String createUserAccessRecord(User_Access_Managment__c objUser, string userType) {
        try {
            objUser.Request_Type__c= userType;
            System.debug('User type==> '+ objUser.Request_Type__c);
            System.debug('User Access: ' + objUser);
            insert objUser;
            objUser = [SELECT Name FROM User_Access_Managment__c WHERE Id = :objUser.Id LIMIT 1];
            return objUser.Name;
        } catch (Exception e) {
            // Log the error and return the error message
            System.debug('Error creating User Access Management record: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPersonaPicklistValues() {
        return getPicklistValues(User_Access_Managment__c.Persona__c);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getStartOfDayPicklistValues() {
        return getPicklistValues(User_Access_Managment__c.Start_Of_Day__c);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getProductTeamPicklistValues() {
        return getPicklistValues(User_Access_Managment__c.Product_Team__c);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getDivisionPicklistValues() {
        return getPicklistValues(User_Access_Managment__c.Divsion__c);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getTimeZonePicklistValues() {
        return getPicklistValues(User_Access_Managment__c.Time_Zone__c);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getEnvPicklistValues() {
        return getPicklistValues(User_Access_Managment__c.Environments__c);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<User> searchUsers(String searchTerm) {
        // Query users based on the search term
        String searchString = searchTerm + '%';
        return [SELECT Id, Name FROM User WHERE Name LIKE :searchString LIMIT 10];
    }
    
/*    //Issue Tracker
    @AuraEnabled
    public static String createIssueTrackerRecord(Issue_Tracker__c issueObj) {
        // Validate Access Details__c
        try {
            System.debug('User Access: ' + issueObj);
            insert issueObj;
            issueObj = [SELECT Issue_Description__c, Issue_Environment__c, Priority__c, Category__c, Team__r.Name 
                        FROM Issue_Tracker__c WHERE Id = :issueObj.Id LIMIT 1];
            return 'success';
            //   return issueObj.Name;
        } catch (Exception e) {
            // Log the error and return the error message
            System.debug('Error creating Issue Trcaker record: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<IdNameWrapper> getTeams() {
        List<IdNameWrapper> teamOptions = new List<IdNameWrapper>();
        for (copado__Team__c team : [SELECT Id, Name FROM copado__Team__c]) {
            teamOptions.add(new IdNameWrapper(team.Id, team.Name));
        }
        return teamOptions;
    }
    
    public class IdNameWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        public IdNameWrapper(Id id, String name) {
            this.id = id;
            this.name = name;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getCategoryPicklistValues() {
        return getPicklistValues(Issue_Tracker__c.Category__c);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPriorityPicklistValues() {
        return getPicklistValues(Issue_Tracker__c.Priority__c);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getEnvironmentPicklistValues() {
        return getPicklistValues(Issue_Tracker__c.Issue_Environment__c);
    } 
*/  
    
    private static List<String> getPicklistValues(Schema.SObjectField field) {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getLabel());
        }
        
        return picklistValues;
    }

	public static void publishAccessUpdateEvent(Id recordId) {
        List<UserAccessUpdateEvent__e> eventList = new List<UserAccessUpdateEvent__e>();
		eventList.add(new UserAccessUpdateEvent__e(Record_Id__c = recordId, Update_Status__c = 'Approved') );
		eventList.add(new UserAccessUpdateEvent__e(Record_Id__c = recordId, Update_Status__c = 'Approved') );

        List<Database.SaveResult> resultList = EventBus.publish(eventList);
        for(Database.SaveResult result: resultList){
            if (result.isSuccess()) {
                System.debug('Platform Event publish successfully: ');
            }  
            else {
                List<Database.error> errList = result.getErrors();
                for(Database.error err: errList){
                	System.debug('Failed to publish platform event: ' +err.getMessage());
                }
            }  
        }
    } 
}