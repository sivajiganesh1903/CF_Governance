public class ReleaseHandlerCustom {
    // Method used to populate Release Start Date based on Release Name
    public static void populateReleaseStartDate(List<copado__Release__c> releases) {
        for (copado__Release__c rel : releases) {
            if (rel.Name != null && rel.Name.length() >= 7) {
                // Split the Name field using period (.) as a delimiter
                String releaseName = rel.Name.replace('TRL', '').trim();  
                List<String> parts = releaseName.split('\\.');
                
                if (parts.size() == 3) {
                    try {
                        Integer year = Integer.valueOf('20' + parts[0]); // Add '20' prefix to year part
                        Integer month = Integer.valueOf(parts[1]);
                        Integer day = Integer.valueOf(parts[2]);                        
                        // Try to create a new Date instance and assign it to Release_Start_Date__c
                        rel.Release_Start_Date__c = Date.newInstance(year, month, day);
                    } catch (Exception e) {
                        // Set Release_Start_Date__c to null in case of any exception
                        rel.Release_Start_Date__c = null;
                        System.debug('Exception while setting Release Start Date: ' + e.getMessage());
                    }
                } else {
                    // Handle the case where the parts size is not 3
                    System.debug('Release Name does not have exactly 3 parts after splitting: ' + rel.Name);
                    rel.Release_Start_Date__c = null;
                }
            }
        }
    }
    
    public static void updateReleaseCompletionUpdate(List<copado__Release__c>newReleases, Map<Id, copado__Release__c> oldReleases){
        // Method used to populate Release Completion Date based on Status updation time
        for (copado__Release__c newRelease : newReleases) {
            copado__Release__c oldRelease = oldReleases.get(newRelease.Id);
            if ((newRelease.copado__Status__c == 'Released' || newRelease.copado__Status__c == 'Cancelled') &&
                (oldRelease == null || oldRelease.copado__Status__c != newRelease.copado__Status__c)) {
                    newRelease.Release_Completion_Date__c = Date.today();
                }
        }
    }
}