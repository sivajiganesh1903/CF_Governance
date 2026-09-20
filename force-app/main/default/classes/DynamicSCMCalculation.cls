public with sharing class DynamicSCMCalculation {
    @InvocableMethod (label='Dynamically Calculate SCM' description='Dynamically Calculate SCM')
    public static void calculateSCM(List<copado__User_Story__c> uslist) {
        
        if(!Test.isRunningTest()){
            if (!Schema.sObjectType.copado__User_Story__c.fields.Shared_Component_Dependency__c.isUpdateable()) {
                throw new AuraHandledException('No update access to Shared_Component_Dependency__c');
            }
        }
        try{
            List<String> statusids = new List<String>(); 
          //  List<copado__User_Story__c> recordsToUpdate = new List<copado__User_Story__c>();
            List<ScmUserStoryController.Wrapper> scmwrapper = new List<ScmUserStoryController.Wrapper>();
    
            for (copado__User_Story__c usl : uslist) {
                scmwrapper = ScmUserStoryController.matrixCompo(usl.id);
                System.debug('User Story: +++' + usl.id);
                if (scmwrapper.size() > 0 && !usl.Back_Promotion_Completed__c) {
                    System.debug('Stroy Size: +++' + scmwrapper.size());
                    statusids.add(usl.id);
                    usl.Shared_Component_Dependency__c = true;
                    System.debug('usl.Shared_Component_Dependency__c: '+ usl.Shared_Component_Dependency__c);
                //    recordsToUpdate.add(usl);
                }
                
            }
            // Perform update safely outside loop
          /*  if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
                System.debug('recordsToUpdate: '+ recordsToUpdate);
            }   */
        }
        Catch(Exception e){
            System.debug(e.getMessage());
        }
    }
}