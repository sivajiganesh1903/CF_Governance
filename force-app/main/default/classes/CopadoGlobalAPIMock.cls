@IsTest
public class CopadoGlobalAPIMock {
    public class LicenseOperationResult {
        public Boolean isSuccess;
        public String errorString;
    }

    public class UserLicense {
        public Boolean isCADEnabled;
        public Boolean isCCHEnabled;
        public Boolean isCCMEnabled;
        public Boolean isCopadoEnabled;
        public Id userId;
    }

    public LicenseOperationResult upsertCopadoLicense(UserLicense userLicense) {
        LicenseOperationResult result = new LicenseOperationResult();
        
        // Simulate a successful license operation
        result.isSuccess = true;
        result.errorString = null;
        return result;
    }
}