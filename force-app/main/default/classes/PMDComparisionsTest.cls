@isTest
public class PMDComparisionsTest {
    @testSetup
    static void setupTestData() {
        // Create a copado Org record
        copado__Org__c org = new copado__Org__c(Name = 'Eric Varela TrnProd2');
        insert org;
        
        // Create related copado__Static_Code_Analysis_Result__c records
        copado__Static_Code_Analysis_Result__c beforeResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = org.Id);
        insert beforeResult;
        
        copado__Static_Code_Analysis_Result__c afterResult = new copado__Static_Code_Analysis_Result__c(
            copado__Org_Credential__c = org.Id);
        insert afterResult;
        
        // Create Scan_Comparison__c record
        Scan_Comparison__c scanComparison = new Scan_Comparison__c(Before_SCA_Result__c = beforeResult.Id,
                                                                   After_SCA_Result__c = afterResult.Id);
        insert scanComparison;
        
        // Create copado__Static_Code_Analysis_Violation__c records with various priorities
        List<copado__Static_Code_Analysis_Violation__c> violations = new List<copado__Static_Code_Analysis_Violation__c>();
        
        // Violations for Before Result with different priorities
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = beforeResult.Id, copado__File__c = 'FileA', copado__Line__c = 10,
            copado__Rule__c = 'Rule1', copado__Priority__c = 1, copado__Message__c = 'Before violation - P1')
                      );
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = beforeResult.Id, copado__File__c = 'FileB', copado__Line__c = 15,
            copado__Rule__c = 'Rule2', copado__Priority__c = 2, copado__Message__c = 'Before violation - P2')
                      );
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = beforeResult.Id, copado__File__c = 'FileC', copado__Line__c = 20,
            copado__Rule__c = 'Rule3', copado__Priority__c = 3, copado__Message__c = 'Before violation - P3')
                      );
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = beforeResult.Id, copado__File__c = 'FileD', copado__Line__c = 25,
            copado__Rule__c = 'Rule4', copado__Priority__c = 4, copado__Message__c = 'Before violation - P4')
                      );
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = beforeResult.Id, copado__File__c = 'FileE', copado__Line__c = 30,
            copado__Rule__c = 'Rule5', copado__Priority__c = 5, copado__Message__c = 'Before violation - P5')
                      );
        
        // Violations for After Result with different priorities
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = afterResult.Id, copado__File__c = 'FileA', copado__Line__c = 10,
            copado__Rule__c = 'Rule1', copado__Priority__c = 1, copado__Message__c = 'After violation - P1')
                      );
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = afterResult.Id, copado__File__c = 'FileB', copado__Line__c = 15,
            copado__Rule__c = 'Rule2', copado__Priority__c = 2, copado__Message__c = 'After violation - P2')
                      );
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = afterResult.Id, copado__File__c = 'FileC', copado__Line__c = 20,
            copado__Rule__c = 'Rule3', copado__Priority__c = 3, copado__Message__c = 'After violation - P3')
                      );
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = afterResult.Id, copado__File__c = 'FileD', copado__Line__c = 25,
            copado__Rule__c = 'Rule4', copado__Priority__c = 4, copado__Message__c = 'After violation - P4')
                      );
        violations.add(new copado__Static_Code_Analysis_Violation__c(
            copado__Static_Code_Analysis_Result__c = afterResult.Id, copado__File__c = 'FileE', copado__Line__c = 30,
            copado__Rule__c = 'Rule5', copado__Priority__c = 5, copado__Message__c = 'After violation - P5')
                      );
        
        insert violations;
    }
    
    @isTest
    static void testViolationComparision() {
        // Get the created Scan_Comparison__c record
        Scan_Comparison__c scanComparison = [SELECT Id FROM Scan_Comparison__c LIMIT 1];
        
        // Call the method and assert the result
        Test.startTest();
        String result = PMDComparisions.ViolationComparision(scanComparison.Id);
        Test.stopTest();
        
        // Assert that the result is 'success'
        System.assertEquals('success', result);
        
        // Requery the Scan_Comparison__c record to check the updated values
        scanComparison = [SELECT After_P1_Violations__c, After_P2_Violations__c, After_P3_Violations__c, 
                          After_P4_Violations__c, After_P5_Violations__c, Before_P1_Violations__c, 
                          Before_P2_Violations__c, Before_P3_Violations__c, Before_P4_Violations__c, 
                          Before_P5_Violations__c FROM Scan_Comparison__c WHERE Id = :scanComparison.Id];
        
        // Assert the violation counts (updated based on test setup data)
        System.assertEquals(1, scanComparison.Before_P1_Violations__c, 'Before P1 count mismatch');
        System.assertEquals(1, scanComparison.After_P1_Violations__c, 'After P1 count mismatch');
        System.assertEquals(1, scanComparison.Before_P2_Violations__c, 'Before P2 count mismatch');
        System.assertEquals(1, scanComparison.After_P2_Violations__c, 'After P2 count mismatch');
        System.assertEquals(1, scanComparison.Before_P3_Violations__c, 'Before P3 count mismatch');
        System.assertEquals(1, scanComparison.After_P3_Violations__c, 'After P3 count mismatch');
        System.assertEquals(1, scanComparison.Before_P4_Violations__c, 'Before P4 count mismatch');
        System.assertEquals(1, scanComparison.After_P4_Violations__c, 'After P4 count mismatch');
        System.assertEquals(1, scanComparison.Before_P5_Violations__c, 'Before P5 count mismatch');
        System.assertEquals(1, scanComparison.After_P5_Violations__c, 'After P5 count mismatch');
    }
    
    @isTest
    static void testWithNoRecords() {
        // Create a valid format but non-existing Id
        String fakeId = 'a0000000000fakeAAA';  // Syntactically valid Id
        
        // Call the method with the fake Id
        Test.startTest();
        String result = PMDComparisions.ViolationComparision(fakeId);
        Test.stopTest();
        
        // Assert that the result is 'failure' for invalid Id
        System.assertEquals('failure', result);
    } 
}