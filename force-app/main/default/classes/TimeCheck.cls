public class TimeCheck {
    public static void checkTime() {
        // Get the current datetime
        Datetime now = Datetime.now();
        
        // Get today's date
        Date today = Date.today();
        
        // Create datetime objects for 14:30 and 22:00
        Datetime datetime1430 = Datetime.newInstance(today, Time.newInstance(14, 30, 0, 0));
        Datetime datetime2200 = Datetime.newInstance(today, Time.newInstance(22, 0, 0, 0));
        
        // Perform the check
        Boolean result = (now > datetime2200 || now < datetime1430);
        System.debug(result);
    }
}