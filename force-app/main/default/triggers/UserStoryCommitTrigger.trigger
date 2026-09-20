trigger UserStoryCommitTrigger on copado__User_Story_Commit__c (after insert) {
    UserStoryCommitHandler.getSnapshotFilesAndAttachments(Trigger.new);
}