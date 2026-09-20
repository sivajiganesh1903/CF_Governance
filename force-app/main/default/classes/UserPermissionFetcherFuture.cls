public class UserPermissionFetcherFuture {
     /**
     * Runs UserPermissionFetcherControllerV2.createOrUpdateUsers in future context to allow callouts.
     * @param uamIds List of User_Access_Managment__c record Ids to process
     */
    @future (callout=true)
    public static void runUserPermissionFetcher(List<Id> uamIds) {
        System.debug('--- START UserPermissionFetcherFuture ---');
        try {
            // Invoke the main controller logic for user creation/updating
            List<Map<String, Object>> results = UserPermissionFetcherControllerV2.createOrUpdateUsers(uamIds);
            // Log the results for debugging
            System.debug('UserPermissionFetcherFuture results: ' + results);
        } catch (Exception e) {
            System.debug('Exception in UserPermissionFetcherFuture: ' + e.getMessage());
        }
        System.debug('--- END UserPermissionFetcherFuture ---');
    }
}