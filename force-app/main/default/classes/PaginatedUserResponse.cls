public class PaginatedUserResponse {
    //@AuraEnabled public List<UserWrapper> users { get; set; }
    @AuraEnabled public String Id { get; set; }
    @AuraEnabled public String Name;
    @AuraEnabled public String FirstName { get; set; }
    @AuraEnabled public String LastName { get; set; }
    @AuraEnabled public String Email { get; set; }
    @AuraEnabled public String FederationIdentifier { get; set; }
    @AuraEnabled public Boolean IsActive { get; set; }
    @AuraEnabled public String ProfileId { get; set; }
    @AuraEnabled public String ProfileName { get; set; }
    @AuraEnabled public Integer totalRecords { get; set; }
}