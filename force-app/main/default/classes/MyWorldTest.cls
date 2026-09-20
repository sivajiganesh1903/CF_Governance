@isTest
public class MyWorldTest {
    @isTest
    static void testSayHello() {
        // Test data
        String testName = 'Niharika';
        
        // Expected outcome
        String expectedMessage = 'Hello, Niharika!';
        
        // Actual method call
        String actualMessage = MyWorld.sayHello(testName);
        
        // Assertion to validate the result
        System.assertEquals(expectedMessage, actualMessage, 'The greeting message is incorrect.');
    }
}