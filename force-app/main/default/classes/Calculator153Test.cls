// Test class: Calculator153Test

@isTest
private class Calculator153Test {
    @isTest
    static void testAdd() {
        // Arrange
        Integer num1 = 5;
        Integer num2 = 3;       
        // Act
        Integer result = Calculator153.add(num1, num2);
        // Assert
        System.assertEquals(8, result, 'Incorrect addition result');
    }    
    @isTest
    static void testSubtract() {
        // Arrange
        Integer num1 = 10;
        Integer num2 = 4;       
        // Act
        Integer result = Calculator153.subtract(num1, num2);        
        // Assert
        System.assertEquals(6, result, 'Incorrect subtraction result');
    }    
}