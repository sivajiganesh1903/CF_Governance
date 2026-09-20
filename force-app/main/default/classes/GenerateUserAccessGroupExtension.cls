public class GenerateUserAccessGroupExtension {
    public final SFRelease__Org__c orgRecord;
    public GenerateUserAccessGroupExtension(ApexPages.StandardController controller) {
        this.orgRecord = (SFRelease__Org__c) controller.getRecord();
        GenerateUserAccessGroup.fetchAndAttachMetadata(orgRecord.Id);
    }
}