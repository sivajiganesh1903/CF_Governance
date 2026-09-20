public class ReleasePlaybookItmeHelper {
    // Order: 2
    public static void processReleasePlaybookSubItem2(List<Release_Playbook_Item__c> rpiList) {
        if (rpiList == null || rpiList.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Invalid Sub Items List');
            return;
        }       
        try {
            Set<Id> rpiIds = new Set<Id>();
            for (Release_Playbook_Item__c rpi : rpiList) {
                rpiIds.add(rpi.Id);
            }
            System.debug('rpiIds++:'+rpiIds);
            // Query Release Playbook Items first
            List<Release_Playbook_Item__c> rpiRecords = [SELECT Id, Sub_Items_Logic__c, Start_Date_Time__c, End_Date_Time__c, 
                                                         (SELECT Id, Release_Playbook_Item__c, Promotion__c FROM 
                                                          Release_Playbook_Sub_Item__r ORDER BY CreatedDate DESC) 
                                                         FROM Release_Playbook_Item__c WHERE Id IN :rpiIds AND 
                                                         Sub_Items_Logic__c = 'Before Deployment - Preprod Promotion Package' 
                                                         AND Status__c = 'Completed'];
            
            System.debug('Release PlayBook Items: ' + rpiRecords);
            
            // Get Promotion IDs to query promotions in bulk
            Set<Id> promotionIds = new Set<Id>();
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Promotion__c != null) {
                        promotionIds.add(subItem.Promotion__c);
                    }
                }
            }
            
            // Query promotions in bulk
            Map<Id, copado__Promotion__c> promotionMap = new Map<Id, copado__Promotion__c>(
                [SELECT Id, Name, CreatedDate, 
                 (SELECT Id, Name, copado__Status__c, CreatedDate,
                  (SELECT Id, Name, copado__Type__c, copado__Status__c, copado__Order__c, LastModifiedDate
                   FROM copado__Steps__r WHERE copado__CheckOnly__c = true AND copado__Status__c = 'Completed Successfully' LIMIT 1) 
                  FROM copado__Deployments__r WHERE copado__Status__c = 'Completed Successfully' ORDER BY CreatedDate DESC LIMIT 1)
                 FROM copado__Promotion__c WHERE Id IN :promotionIds]);
            System.debug('Promotions: ' + promotionMap);
           
            List<Release_Playbook_Item__c> playbookItemsToUpdate = new List<Release_Playbook_Item__c>();
            
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Promotion__c != null && promotionMap.containsKey(subItem.Promotion__c)) {
                        copado__Promotion__c promotion = promotionMap.get(subItem.Promotion__c);
                        if (!promotion.copado__Deployments__r.isEmpty()) {
                            copado__Deployment__c deployment = promotion.copado__Deployments__r[0];
                            if (!deployment.copado__Steps__r.isEmpty()) {
                                copado__Step__c step = deployment.copado__Steps__r[0];                               
                                // Update the Release Playbook Item dates
                                Release_Playbook_Item__c playbookItem = new Release_Playbook_Item__c(
                                    Id = subItem.Release_Playbook_Item__c,
                                    Start_Date_Time__c = promotion.CreatedDate,
                                    End_Date_Time__c = step.LastModifiedDate
                                );
                                playbookItemsToUpdate.add(playbookItem);
                                System.debug('Updated Release Playbook Item: ' + playbookItem);
                            }
                        }
                    }
                }
            }
            
            if (!playbookItemsToUpdate.isEmpty()) {
                update playbookItemsToUpdate;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing Release Playbook Sub Item: ' + e.getMessage());
        }
    }
    
    // Sub Item Order: 6
    public static void processReleasePlaybookSubItem6(List<Release_Playbook_Item__c> rpiList) {
        if (rpiList == null || rpiList.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Invalid Sub Items List');
            return;
        }        
        try {
            Set<Id> rpiIds = new Set<Id>();
            for (Release_Playbook_Item__c rpi : rpiList) {
                rpiIds.add(rpi.Id);
            }
            System.debug('rpiIds++:'+rpiIds);
            // Query Release Playbook Items first
            List<Release_Playbook_Item__c> rpiRecords = [SELECT Id, Sub_Items_Logic__c, Start_Date_Time__c, End_Date_Time__c, 
                                                         (SELECT Id, Release_Playbook_Item__c, Deployment__c FROM 
                                                          Release_Playbook_Sub_Item__r ORDER BY CreatedDate DESC LIMIT 1) FROM 
                                                         Release_Playbook_Item__c WHERE Id IN :rpiIds AND Sub_Items_Logic__c = 'Deployment - Preprod Package Completion' 
                                                         AND Status__c = 'Completed'];           
            System.debug('Release PlayBook : +++++' + rpiRecords);
            
            // Get Promotion IDs to query promotions in bulk
            Set<Id> deploymentIds = new Set<Id>();
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Deployment__c != null) {
                        deploymentIds.add(subItem.Deployment__c);
                    }
                }
            }
            
            // Query Deployments in bulk
            Map<Id, copado__Deployment__c> deploymentMap = new Map<Id, copado__Deployment__c>(
                [SELECT Id, Name, copado__Status__c, CreatedDate, 
                 (SELECT Id, Name, copado__Object__c, copado__Field__c, copado__Old_Value__c, copado__New_Value__c, 
                  copado__Date__c FROM copado__Copado_Deployment_History__r WHERE copado__Object__c = 'Deployment' AND  
                  copado__Field__c = 'Status' AND copado__Old_Value__c = 'In progress' AND copado__New_Value__c = 'Completed Successfully' LIMIT 1) 
                 FROM copado__Deployment__c WHERE Id IN :deploymentIds AND copado__Status__c = 'Completed Successfully']);
            System.debug('Deployments: ' + deploymentMap);
            
            List<Release_Playbook_Item__c> playbookItemsToUpdate = new List<Release_Playbook_Item__c>();
            
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Deployment__c != null && deploymentMap.containsKey(subItem.Deployment__c)) {
                        copado__Deployment__c deployment = deploymentMap.get(subItem.Deployment__c);
                        if (!deployment.copado__Copado_Deployment_History__r.isEmpty()) {
                            copado__Deployment_History__c history = deployment.copado__Copado_Deployment_History__r[0];                                                       
                            // Update the Release Playbook Item dates
                            Release_Playbook_Item__c playbookItem = new Release_Playbook_Item__c(
                                Id = subItem.Release_Playbook_Item__c,
                                Start_Date_Time__c = deployment.CreatedDate,
                                End_Date_Time__c = history.copado__Date__c
                            );
                            playbookItemsToUpdate.add(playbookItem);
                            System.debug('Updated Release Playbook Item: ' + playbookItem);
                        }
                    }
                }
            }
            
            // Perform bulk DML update outside the loop
            if (!playbookItemsToUpdate.isEmpty()) {
                update playbookItemsToUpdate;
                System.debug('Updated ' + playbookItemsToUpdate.size() + ' Release Playbook Items successfully.');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing Release Playbook Sub Item: ' + e.getMessage());
        }
    }
    
    // Order: 8
    public static void processReleasePlaybookSubItem8(List<Release_Playbook_Item__c> rpiList) {
        if (rpiList == null || rpiList.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Invalid Sub Items List');
            return;
        }       
        try {
            Set<Id> rpiIds = new Set<Id>();
            for (Release_Playbook_Item__c rpi : rpiList) {
                rpiIds.add(rpi.Id);
            }
            System.debug('rpiIds: ' + rpiIds);
            
            // Query Release Playbook Items first
            List<Release_Playbook_Item__c> rpiRecords = [SELECT Id, Sub_Items_Logic__c, Start_Date_Time__c, End_Date_Time__c, 
                                                         (SELECT Id, Release_Playbook_Item__c, Promotion__c FROM Release_Playbook_Sub_Item__r 
                                                          ORDER BY CreatedDate DESC LIMIT 1) FROM Release_Playbook_Item__c WHERE Id IN :rpiIds 
                                                         AND Sub_Items_Logic__c = 'Before Deployment - Create Promotion - Sign off Stories' 
                                                         AND Status__c = 'Completed'];
            System.debug('Release PlayBook Items: ' + rpiRecords);
            
            // Get Promotion IDs to query promotions in bulk
            Set<Id> promotionIds = new Set<Id>();
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Promotion__c != null) {
                        promotionIds.add(subItem.Promotion__c);
                    }
                }
            }             
            
            if (promotionIds.isEmpty()) {
                System.debug('No promotions found for the given Release Playbook Items.');
                return;
            }
            
            // Fetch all deployments related to Promotions
            Map<Id, List<copado__Deployment__c>> promotionDeploymentsMap = new Map<Id, List<copado__Deployment__c>>();            
            List<copado__Promotion__c> promotions = [SELECT Id, Name, CreatedDate, 
                                                     (SELECT Id, Name, copado__Promotion__c, copado__Status__c, CreatedDate, 
                                                      LastModifiedDate FROM copado__Deployments__r ORDER BY CreatedDate ASC) 
                                                     FROM copado__Promotion__c WHERE Id IN :promotionIds];
            
            for (copado__Promotion__c promotion : promotions) {
                if (promotion.copado__Deployments__r != null && !promotion.copado__Deployments__r.isEmpty()) {
                    promotionDeploymentsMap.put(promotion.Id, promotion.copado__Deployments__r);
                }
            }
            System.debug('Promotion Deployments Map: ' + promotionDeploymentsMap);
            
            // Store deployment IDs for querying history
            Set<Id> deploymentIds = new Set<Id>();
            for (List<copado__Deployment__c> deployments : promotionDeploymentsMap.values()) {
                for (copado__Deployment__c dep : deployments) {
                    deploymentIds.add(dep.Id);
                }
            }
            
            if (deploymentIds.isEmpty()) {
                System.debug('No deployments found for the promotions.');
                return;
            }
            
            // Query only the latest deployment history record for each deployment
            Map<Id, copado__Deployment_History__c> deploymentHistoryMap = new Map<Id, copado__Deployment_History__c>();
            
            List<copado__Deployment_History__c> deploymentHistories = [
                SELECT Id, Name, copado__Object__c, copado__Field__c, copado__Old_Value__c, copado__New_Value__c, copado__Date__c, 
                copado__Deployment__c FROM copado__Deployment_History__c WHERE copado__Deployment__c IN :deploymentIds AND 
                copado__Object__c = 'Deployment' AND copado__Field__c = 'Status' AND copado__Old_Value__c = 'In progress' 
                AND copado__New_Value__c = 'Completed Successfully' ORDER BY copado__Date__c DESC ];
            
            // Store only the latest history record for each deployment
            for (copado__Deployment_History__c history : deploymentHistories) {
                if (!deploymentHistoryMap.containsKey(history.copado__Deployment__c)) {
                    deploymentHistoryMap.put(history.copado__Deployment__c, history);
                }
            }
            // Prepare Release Playbook Items for update
            List<Release_Playbook_Item__c> playbookItemsToUpdate = new List<Release_Playbook_Item__c>();
            
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Promotion__c != null && promotionDeploymentsMap.containsKey(subItem.Promotion__c)) {
                        List<copado__Deployment__c> deployments = promotionDeploymentsMap.get(subItem.Promotion__c);
                        
                        if (!deployments.isEmpty()) {
                            // First Deployment (Earliest Created)
                            copado__Deployment__c firstDeployment = deployments[0];
                            
                            // Last Deployment (Latest Modified)
                            copado__Deployment__c latestDeployment = deployments[0];
                            for (copado__Deployment__c dep : deployments) {
                                if (dep.LastModifiedDate > latestDeployment.LastModifiedDate) {
                                    latestDeployment = dep;
                                }
                            }
                            
                            // Fetch related deployment history for latest deployment
                            copado__Deployment_History__c history = deploymentHistoryMap.get(latestDeployment.Id);
                            
                            if (history != null) {
                                Release_Playbook_Item__c playbookItem = new Release_Playbook_Item__c(
                                    Id = rpiRecord.Id, Start_Date_Time__c = firstDeployment.CreatedDate,
                                    End_Date_Time__c = history.copado__Date__c);
                                playbookItemsToUpdate.add(playbookItem);
                                System.debug('Updated Release Playbook Item: ' + playbookItem);
                            }
                        }
                    }
                }
            }
            
            if (!playbookItemsToUpdate.isEmpty()) {
                update playbookItemsToUpdate;
                System.debug('Successfully updated ' + playbookItemsToUpdate.size() + ' Release Playbook Items.');
            } else {
                System.debug('No Release Playbook Items to update.');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing Release Playbook Sub Item: ' + e.getMessage());
        }
    }
    
    // Order: 11
    public static void processReleasePlaybookSubItem11(List<Release_Playbook_Item__c> rpiList) {
        if (rpiList == null || rpiList.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Invalid Sub Items List');
            return;
        }       
        try {
            Set<Id> rpiIds = new Set<Id>();
            for (Release_Playbook_Item__c rpi : rpiList) {
                rpiIds.add(rpi.Id);
            }
            System.debug('rpiIds++:'+rpiIds);
            // Query Release Playbook Items first
            List<Release_Playbook_Item__c> rpiRecords = [SELECT Id, Execution_Sequence__c, Sub_Items_Logic__c, Start_Date_Time__c, End_Date_Time__c, 
                                                         (SELECT Id, Release_Playbook_Item__c, Deployment__c, SCA_Execution_Time__c FROM 
                                                          Release_Playbook_Sub_Item__r ORDER BY CreatedDate DESC LIMIT 1) FROM 
                                                         Release_Playbook_Item__c WHERE Id IN :rpiIds AND Sub_Items_Logic__c = 'Before Deployment - Validate Package' 
                                                         AND Status__c = 'Completed'];           
            System.debug('Release PlayBook : +++++' + rpiRecords);
            
            // Get Deployment IDs to query promotions in bulk
            Set<Id> deploymentIds = new Set<Id>();
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Deployment__c != null) {
                        deploymentIds.add(subItem.Deployment__c);
                    }
                }
            }
            
            // Query Deployments in bulk
            Map<Id, copado__Deployment__c> deploymentMap = new Map<Id, copado__Deployment__c>(
                [SELECT Id, Name, copado__Status__c, CreatedDate,
                 (SELECT Id, Name, copado__Type__c, copado__Status__c, copado__Order__c, LastModifiedDate 
                  FROM copado__Steps__r WHERE copado__CheckOnly__c = true AND copado__Status__c = 'Completed Successfully' LIMIT 1)
                 FROM copado__Deployment__c WHERE Id IN :deploymentIds AND copado__Status__c = 'Completed Successfully']);
            
            System.debug('Deployments: ' + deploymentMap);
            
            List<Release_Playbook_Item__c> playbookItemsToUpdate = new List<Release_Playbook_Item__c>();
            
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Deployment__c != null && deploymentMap.containsKey(subItem.Deployment__c)) {
                        copado__Deployment__c deployment = deploymentMap.get(subItem.Deployment__c);                        
                        if (deployment.copado__Steps__r != null && !deployment.copado__Steps__r.isEmpty()) {
                            copado__Step__c step = deployment.copado__Steps__r[0];                                                           
                            // Update the Release Playbook Item dates
                            Release_Playbook_Item__c playbookItem = new Release_Playbook_Item__c(
                                Id = subItem.Release_Playbook_Item__c,
                                Start_Date_Time__c = deployment.CreatedDate,
                                End_Date_Time__c = step.LastModifiedDate
                            );
                            playbookItemsToUpdate.add(playbookItem);
                            System.debug('Updated Release Playbook Item: ' + playbookItem);
                        }
                    }
                }
            }
            
            // Perform bulk DML update outside the loop
            if (!playbookItemsToUpdate.isEmpty()) {
                update playbookItemsToUpdate;
                System.debug(LoggingLevel.INFO, 'Successfully updated ' + playbookItemsToUpdate.size() + ' Release Playbook Items.');
            } 
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing Release Playbook Sub Item: ' + e.getMessage());
        } 
    }
    
    // Order: 15
    public static void processReleasePlaybookSubItem15(List<Release_Playbook_Item__c> rpiList) {
        if (rpiList == null || rpiList.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Invalid Sub Items List');
            return;
        }       
        try {
            Set<Id> rpiIds = new Set<Id>();
            for (Release_Playbook_Item__c rpi : rpiList) {
                rpiIds.add(rpi.Id);
            }
            System.debug('rpiIds++:'+rpiIds);
            // Query Release Playbook Items first
            List<Release_Playbook_Item__c> rpiRecords = [SELECT Id, Status__c, Sub_Items_Logic__c, Start_Date_Time__c, End_Date_Time__c, 
                                                         (SELECT Id, Release_Playbook_Item__c, Snapshot_Commit__c, SCA_Execution_Time__c FROM 
                                                          Release_Playbook_Sub_Item__r ORDER BY CreatedDate DESC LIMIT 1) FROM 
                                                         Release_Playbook_Item__c WHERE Id IN :rpiIds AND Sub_Items_Logic__c = 'Before Deployment - Sanpshot Commit - Release'
                                                         AND Status__c = 'Completed'];           
            System.debug('Release PlayBook : +++++' + rpiRecords);
            
            // Get Promotion IDs to query promotions in bulk
            Set<Id> snapshotIds = new Set<Id>();
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Snapshot_Commit__c != null) {
                        snapshotIds.add(subItem.Snapshot_Commit__c);
                    }
                }
            }
            
            // Query Deployments in bulk
            Map<Id, copado__Git_Org_Commit__c> sanpshotcommitMap = new Map<Id, copado__Git_Org_Commit__c>(
                [SELECT Id, Name, copado__Status__c, copado__Commit_Id__c, copado__Git_Backup__c, CreatedDate, LastModifiedDate 
                 FROM copado__Git_Org_Commit__c WHERE Id IN :snapshotIds]);
            System.debug('Sanpshot Commits: +++++ ' + sanpshotcommitMap);
            
            List<Release_Playbook_Item__c> playbookItemsToUpdate = new List<Release_Playbook_Item__c>();
            
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Snapshot_Commit__c != null && sanpshotcommitMap.containsKey(subItem.Snapshot_Commit__c)) {
                        copado__Git_Org_Commit__c snapshot = sanpshotcommitMap.get(subItem.Snapshot_Commit__c);
                        // Update the Release Playbook Item dates
                        Release_Playbook_Item__c playbookItem = new Release_Playbook_Item__c(
                            Id = subItem.Release_Playbook_Item__c,
                            Start_Date_Time__c = snapshot.CreatedDate,
                            End_Date_Time__c = snapshot.LastModifiedDate
                        );
                        playbookItemsToUpdate.add(playbookItem);
                        System.debug('Updated Release Playbook Item: ' + playbookItem);
                    }
                }
            }// Perform bulk DML update outside the loop
            if (!playbookItemsToUpdate.isEmpty()) {
                update playbookItemsToUpdate;
                System.debug('Updated ' + playbookItemsToUpdate.size() + ' Release Playbook Items successfully.');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing Release Playbook Sub Item: ' + e.getMessage());
        }       
    }
    
    // Order: 26, 29, 30
    public static void processReleasePlaybookSubItems(List<Release_Playbook_Item__c> rpiList) {
        if (rpiList == null || rpiList.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Invalid Sub Items List');
            return;
        }       
        try {
            Set<Id> rpiIds = new Set<Id>();
            for (Release_Playbook_Item__c rpi : rpiList) {
                rpiIds.add(rpi.Id);
            }
            System.debug('rpiIds++:'+rpiIds);
            // Query Release Playbook Items first
            List<Release_Playbook_Item__c> rpiRecords = [SELECT Id, Status__c, Sub_Items_Logic__c, Start_Date_Time__c, End_Date_Time__c, 
                                                         (SELECT Id, Release_Playbook_Item__c, Deployment__c, SCA_Execution_Time__c FROM 
                                                          Release_Playbook_Sub_Item__r ORDER BY CreatedDate DESC LIMIT 1) FROM 
                                                         Release_Playbook_Item__c WHERE Id IN :rpiIds AND Sub_Items_Logic__c IN ('After Deployment - Deploy PROD Package To Training', 'After Deployment - Deploy PROD Package To PioneerPOC', 'After Deployment - Deploy PROD Package To POCDEV1' )
                                                         AND Status__c = 'Completed'];           
            System.debug('Release PlayBook : +++++' + rpiRecords);
            
            // Get Promotion IDs to query promotions in bulk
            Set<Id> deploymentIds = new Set<Id>();
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Deployment__c != null) {
                        deploymentIds.add(subItem.Deployment__c);
                    }
                }
            }          
            // Query Deployments in bulk
            Map<Id, copado__Deployment__c> deploymentMap = new Map<Id, copado__Deployment__c>(
                [SELECT Id, Name, copado__Status__c, CreatedDate,
                 (SELECT Id, Name, copado__Object__c, copado__Field__c, copado__Old_Value__c, copado__New_Value__c, 
                  copado__Date__c FROM copado__Copado_Deployment_History__r WHERE copado__Object__c = 'Deployment' AND  
                  copado__Field__c = 'Status' AND copado__Old_Value__c = 'In progress' AND copado__New_Value__c = 'Completed Successfully' LIMIT 1) 
                 FROM copado__Deployment__c WHERE Id IN :deploymentIds AND copado__Status__c = 'Completed Successfully']);
            System.debug('Deployments: ' + deploymentMap);
            
            List<Release_Playbook_Item__c> playbookItemsToUpdate = new List<Release_Playbook_Item__c>();
            
            for (Release_Playbook_Item__c rpiRecord : rpiRecords) {
                if (rpiRecord.Release_Playbook_Sub_Item__r != null && !rpiRecord.Release_Playbook_Sub_Item__r.isEmpty()) {
                    Release_Playbook_Sub_Item__c subItem = rpiRecord.Release_Playbook_Sub_Item__r[0];
                    if (subItem.Deployment__c != null && deploymentMap.containsKey(subItem.Deployment__c)) {
                        copado__Deployment__c deployment = deploymentMap.get(subItem.Deployment__c);
                        if (!deployment.copado__Copado_Deployment_History__r.isEmpty()) {
                            copado__Deployment_History__c history = deployment.copado__Copado_Deployment_History__r[0];
                            // Update the Release Playbook Item dates
                            Release_Playbook_Item__c playbookItem = new Release_Playbook_Item__c(
                                Id = subItem.Release_Playbook_Item__c,
                                Start_Date_Time__c = deployment.CreatedDate,
                                End_Date_Time__c = history.copado__Date__c
                            );
                            playbookItemsToUpdate.add(playbookItem);
                            System.debug('Updated Release Playbook Item: ' + playbookItem);
                        }
                    }
                }
            }
            // Perform bulk DML update outside the loop
            if (!playbookItemsToUpdate.isEmpty()) {
                update playbookItemsToUpdate;
                System.debug('Updated ' + playbookItemsToUpdate.size() + ' Release Playbook Items successfully.');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing Release Playbook Sub Item: ' + e.getMessage());
        }
    }  
}