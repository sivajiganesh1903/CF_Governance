@isTest
private class CalculatorTest {
    // Test method for the add method
    @isTest
    static void testAdd() {
        // Create an instance of the Calculator class
        Calculator calc = new Calculator();

        // Test case 1: adding two positive numbers
        Integer result = calc.add(5, 3);
        System.assertEquals(8, result, '5 + 3 should equal 8');

        // Test case 2: adding a positive and a negative number
        result = calc.add(5, -3);
        System.assertEquals(2, result, '5 + (-3) should equal 2');

        // Test case 3: adding two negative numbers
        result = calc.add(-5, -3);
        System.assertEquals(-8, result, '-5 + (-3) should equal -8');
    }
}