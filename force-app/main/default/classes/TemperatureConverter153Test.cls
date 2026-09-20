@isTest
private class TemperatureConverter153Test {
    @isTest static void testWarmTemp() {
        Decimal celsius = TemperatureConverter153.FahrenheitToCelsius(70);
        System.assertEquals(21.11,celsius);
    }
    @isTest static void testFreezingPoint() {
        Decimal celsius = TemperatureConverter153.FahrenheitToCelsius(32);
        System.assertEquals(0,celsius);
    }
    @isTest static void testBoilingPoint() {
        Decimal celsius = TemperatureConverter153.FahrenheitToCelsius(212);        
        System.assertEquals(100,celsius,'Boiling point temperature is not expected.');
    } 
    @isTest static void testNegativeTemp() {
        Decimal celsius = TemperatureConverter153.FahrenheitToCelsius(-10);
        System.assertEquals(-23.33,celsius);
    }
}