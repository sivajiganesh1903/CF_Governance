trigger ReleasePlaybookItemTrigger on Release_Playbook_Item__c (after update) {
    // Static variable to avoid recursion
    if (ReleasePlaybookItemRecursionHandler.flag) {
        return; // Prevent recursion if the flag is true
    }

    try {
        // Set the flag to true indicating the trigger logic is running
        ReleasePlaybookItemRecursionHandler.flag = true;
        if (Trigger.isAfter && Trigger.isUpdate) {
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem2(Trigger.new);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem6(Trigger.new);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem8(Trigger.new);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem11(Trigger.new);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItem15(Trigger.new);
            ReleasePlaybookItmeHelper.processReleasePlaybookSubItems(Trigger.new);
        }
    } catch (Exception e) {
        // Handle any exceptions here
        System.debug('Error in ReleasePlaybookItemTrigger: ' + e.getMessage());
    } finally {
        // Reset the flag at the end of trigger execution
        ReleasePlaybookItemRecursionHandler.flag = false;
    }
}