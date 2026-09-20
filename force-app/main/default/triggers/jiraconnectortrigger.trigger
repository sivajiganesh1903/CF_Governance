trigger jiraconnectortrigger on Copado__User_Story__C (after update) {
  /*  // Create a list to hold records that meet the criteria
    List<Copado__User_Story__C> updatedRecords = new List<Copado__User_Story__C>();

    // Iterate through updated records
    for (Copado__User_Story__C newRecord : Trigger.new) {
        // Get the old record from Trigger.old
        Copado__User_Story__C oldRecord = Trigger.oldMap.get(newRecord.Id);

        // Check if the checkbox field changed from false to true
        if ((oldRecord.copado__Promote_and_Deploy__c == false && newRecord.copado__Promote_and_Deploy__c == true) || (oldRecord.copado__Promote_Change__c == false && newRecord.copado__Promote_Change__c == true)) {
            updatedRecords.add(newRecord);
        } 
    }

    // Perform logic only if there are matching records
    if (!updatedRecords.isEmpty()) {
        // Call a helper method or add your logic here
        jiraconnectoruserstory.validation(updatedRecords);
    } */
}