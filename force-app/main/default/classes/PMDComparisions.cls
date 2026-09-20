public class PMDComparisions {
    @AuraEnabled
    public static String ViolationComparision(String recordId) {
        try {            
            String str;
            // Query the Scan Comparison record
            Scan_Comparison__c deploymentViolation = [SELECT Id, Name, Before_SCA_Result__c, After_SCA_Result__c, After_P1_Violations__c, 
                                                      Before_P1_Violations__c, After_P2_Violations__c, After_P3_Violations__c, 
                                                      After_P4_Violations__c, Before_P2_Violations__c, Before_P3_Violations__c, 
                                                      Before_P4_Violations__c, Before_P5_Violations__c FROM Scan_Comparison__c 
                                                      WHERE Id =: recordId];
            System.debug('SCA PMD Comparisons: ++++ ' + deploymentViolation);
            
            // If the deploymentViolation is found, proceed with the logic
            if (deploymentViolation != null) {
                System.debug('SCA PMD Comparisons is Exists?: ++++ ' + deploymentViolation);
                
                // Fetch the related SCA records based on the deploymentViolation fields
                List<copado__Static_Code_Analysis_Result__c> SCARecords = [SELECT Id, Name, copado__Critical__c, copado__Highest_Priority_Violation__c,
                                                                           copado__Score_v11__c, copado__Number_of_Violations__c, copado__Major__c, 
                                                                           copado__Minor__c FROM copado__Static_Code_Analysis_Result__c 
                                                                           WHERE Id IN :new Set<Id>{deploymentViolation.Before_SCA_Result__c, 
                                                                               deploymentViolation.After_SCA_Result__c}];
                System.debug('Static Code Analysis Result Records: +++++' + SCARecords);
                
                // Variables to store the violation counts
                Integer totalP1CountBefore = 0, totalP2CountBefore = 0, totalP3CountBefore = 0, totalP4CountBefore = 0,
                    totalP5CountBefore = 0;
                Integer totalP1CountAfter = 0, totalP2CountAfter = 0, totalP3CountAfter = 0, totalP4CountAfter = 0, 
                    totalP5CountAfter = 0;
                
                // Ensure there are enough records before accessing them
                if (SCARecords.size() >= 2) {
                    copado__Static_Code_Analysis_Result__c afterResult = SCARecords[0];
                    copado__Static_Code_Analysis_Result__c beforeResult = SCARecords[1];
                    
                    // Debug the results
                    System.debug('After SCA Result: ' + afterResult);
                    System.debug('Before SCA Result: ' + beforeResult);
                    
                    // Fetch violations for afterResult
                    List<copado__Static_Code_Analysis_Violation__c> afterViolations = [SELECT Id, Name, copado__Type__c, copado__Priority__c, 
                                                                                       copado__Static_Code_Analysis_Result__c 
                                                                                       FROM copado__Static_Code_Analysis_Violation__c 
                                                                                       WHERE copado__Static_Code_Analysis_Result__c = :afterResult.Id];
                    System.debug('After Result Violations: ' + afterViolations);
                    
                    // Fetch violations for beforeResult
                    List<copado__Static_Code_Analysis_Violation__c> beforeViolations = [SELECT Id, Name, copado__Type__c, copado__Priority__c, 
                                                                                        copado__Static_Code_Analysis_Result__c 
                                                                                        FROM copado__Static_Code_Analysis_Violation__c 
                                                                                        WHERE copado__Static_Code_Analysis_Result__c = :beforeResult.Id];
                    System.debug('Before Result Violations: ' + beforeViolations);
                    
                    // Count violations for beforeResult
                    for (copado__Static_Code_Analysis_Violation__c violation : beforeViolations) {
                        switch on String.valueOf(violation.copado__Priority__c) { 
                            when '1' { totalP1CountBefore++; }
                            when '2' { totalP2CountBefore++; }
                            when '3' { totalP3CountBefore++; }
                            when '4' { totalP4CountBefore++; }
                            when '5' { totalP5CountBefore++; }
                        }
                    }
                    
                    // Count violations for afterResult
                    for (copado__Static_Code_Analysis_Violation__c violation : afterViolations) {
                        switch on String.valueOf(violation.copado__Priority__c) { 
                            when '1' { totalP1CountAfter++; }
                            when '2' { totalP2CountAfter++; }
                            when '3' { totalP3CountAfter++; }
                            when '4' { totalP4CountAfter++; }
                            when '5' { totalP5CountAfter++; }
                        }
                    }
                    
                    // Debug the Before and After total counts
                    System.debug('Total P1 Count Before: ' + totalP1CountBefore);
                    System.debug('Total P2 Count Before: ' + totalP2CountBefore);
                    System.debug('Total P3 Count Before: ' + totalP3CountBefore);
                    System.debug('Total P4 Count Before: ' + totalP4CountBefore);
                    System.debug('Total P5 Count Before: ' + totalP5CountBefore);
                    System.debug('Total P1 Count After: ' + totalP1CountAfter);
                    System.debug('Total P2 Count After: ' + totalP2CountAfter);
                    System.debug('Total P3 Count After: ' + totalP3CountAfter);
                    System.debug('Total P4 Count After: ' + totalP4CountAfter);
                    System.debug('Total P5 Count After: ' + totalP5CountAfter);
                    
                    // Update the deploymentViolation record with the counts
                    deploymentViolation.After_P1_Violations__c = totalP1CountAfter;
                    deploymentViolation.After_P2_Violations__c = totalP2CountAfter;
                    deploymentViolation.After_P3_Violations__c = totalP3CountAfter;
                    deploymentViolation.After_P4_Violations__c = totalP4CountAfter;
                    deploymentViolation.After_P5_Violations__c = totalP5CountAfter;
                    deploymentViolation.Before_P1_Violations__c = totalP1CountBefore;
                    deploymentViolation.Before_P2_Violations__c = totalP2CountBefore;
                    deploymentViolation.Before_P3_Violations__c = totalP3CountBefore;
                    deploymentViolation.Before_P4_Violations__c = totalP4CountBefore;
                    deploymentViolation.Before_P5_Violations__c = totalP5CountBefore; 
                    
                    str = 'success';
                    // Perform the update
                    update deploymentViolation;
                    return str;
                } else {
                    System.debug('Not enough SCA records found for comparison.');
                } 
                // Return success if the comparison and update are successful
                return 'success';
            }
        } catch (QueryException e) {
            // Handle the scenario where no records are found gracefully
            return 'failure';
        }
        return 'failure';
    } 
}