global class InactiveUserCleanupScheduler implements Schedulable {
    private static final String METADATA_TYPE = 'Copado_License_Cleanup_Schedule__mdt';
    private static final String DEFAULT_SCHEDULE_NAME = 'Default_Schedule';
    
    // Main schedulable execute method
    global void execute(SchedulableContext sc) {
        try {
            InactiveUserCleanup.inactiveUserData();
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error executing scheduled job: ' + e.getMessage());
        }
    }
    
    // Custom exception class
    public class SchedulerException extends Exception {}
    
    // Changed to static method
    public static void scheduleJob() {
        try {
            Copado_License_Cleanup_Schedule__mdt scheduleConfig = getScheduleConfiguration();
            
            if (scheduleConfig != null && scheduleConfig.Is_Active__c) {
                // Abort any existing jobs
                abortExistingJobs();
                
                // Schedule new jobs for each selected day
                scheduleForSelectedDays(scheduleConfig);
                
                System.debug(LoggingLevel.INFO, 'Successfully scheduled jobs for configuration: ' + 
                           scheduleConfig.Schedule_Description__c);
            } else {
                System.debug(LoggingLevel.INFO, 'Scheduler is inactive or configuration not found. Job not scheduled.');
            }
        } catch (Exception e) {
            String errorMsg = 'Failed to schedule job: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, errorMsg);
            throw new SchedulerException(errorMsg);
        }
    }
    
    // Changed to static method
    private static void scheduleForSelectedDays(Copado_License_Cleanup_Schedule__mdt config) {
        validateDays(config.Run_Days__c);
        
        List<String> selectedDays = config.Run_Days__c.split(';');
        String timeString = config.Run_Time_HH_mm__c;
        
        List<String> timeParts = timeString.split(':');
        if (timeParts.size() != 2) {
            throw new SchedulerException('Invalid time format. Expected HH:mm, got: ' + timeString);
        }
        
        Integer hour = Integer.valueOf(timeParts[0]);
        Integer minute = Integer.valueOf(timeParts[1]);
        
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            throw new SchedulerException('Invalid time values. Hour must be 0-23, minute must be 0-59');
        }
        
        for (String day : selectedDays) {
            String cronExp = generateCronExpression(day.trim().toUpperCase(), hour, minute);
            String jobName = 'Copado License Cleanup - ' + day + ' at ' + timeString;
            System.schedule(jobName, cronExp, new InactiveUserCleanupScheduler());
            System.debug(LoggingLevel.INFO, 'Scheduled job: ' + jobName + ' with cron: ' + cronExp);
        }
    }
    
    // Changed to static method
    private static void validateDays(String daysString) {
        Set<String> validDays = new Set<String>{'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'};
        Set<String> inputDays = new Set<String>();
        
        if(String.isBlank(daysString)) {
            throw new SchedulerException('Run Days cannot be empty. Please specify at least one day.');
        }
        
        for(String day : daysString.split(';')) {
            String trimmedDay = day.trim().toUpperCase();
            if(!validDays.contains(trimmedDay)) {
                throw new SchedulerException('Invalid day format: ' + trimmedDay + 
                    '. Valid values are: MON, TUE, WED, THU, FRI, SAT, SUN');
            }
            if(inputDays.contains(trimmedDay)) {
                throw new SchedulerException('Duplicate day found: ' + trimmedDay);
            }
            inputDays.add(trimmedDay);
        }
    }
    
    // Changed to static method
    private static String generateCronExpression(String dayOfWeek, Integer hour, Integer minute) {
        Map<String, String> dayMap = new Map<String, String>{
            'SUN' => '1',
            'MON' => '2',
            'TUE' => '3',
            'WED' => '4',
            'THU' => '5',
            'FRI' => '6',
            'SAT' => '7'
        };
        
        if (!dayMap.containsKey(dayOfWeek)) {
            throw new SchedulerException('Invalid day of week: ' + dayOfWeek);
        }
        
        return String.format('0 {0} {1} ? * {2}', 
            new List<String>{
                String.valueOf(minute),
                String.valueOf(hour),
                dayMap.get(dayOfWeek)
            });
    }
    
    // Changed to static method
    private static Copado_License_Cleanup_Schedule__mdt getScheduleConfiguration() {
        try {
            List<Copado_License_Cleanup_Schedule__mdt> schedules = [
                SELECT Id, DeveloperName, Run_Time_HH_mm__c	, Run_Days__c,
                       Is_Active__c, Schedule_Description__c 
                FROM Copado_License_Cleanup_Schedule__mdt 
                WHERE DeveloperName = :DEFAULT_SCHEDULE_NAME
                LIMIT 1
            ];
            
            if (!schedules.isEmpty()) {
                return schedules[0];
            }
            
            throw new SchedulerException('No schedule configuration found with DeveloperName: ' + DEFAULT_SCHEDULE_NAME);
        } catch (Exception e) {
            throw new SchedulerException('Failed to retrieve schedule configuration: ' + e.getMessage());
        }
    }
    
    // Changed to static method
    private static void abortExistingJobs() {
        try {
            List<CronTrigger> existingJobs = [
                SELECT Id, CronJobDetail.Name 
                FROM CronTrigger 
                WHERE CronJobDetail.Name LIKE 'Copado License Cleanup%'
            ];
            
            if (!existingJobs.isEmpty()) {
                for (CronTrigger job : existingJobs) {
                    System.abortJob(job.Id);
                }
                System.debug(LoggingLevel.INFO, 'Aborted ' + existingJobs.size() + ' existing scheduled jobs');
            }
        } catch (Exception e) {
            throw new SchedulerException('Failed to abort existing jobs: ' + e.getMessage());
        }
    }
    
    // Public static method to reschedule
    public static void rescheduleJob() {
        scheduleJob();
    }
    
    // Static method to check schedule status
    public static void checkScheduleStatus() {
        try {
            Copado_License_Cleanup_Schedule__mdt config = [
                SELECT Run_Time_HH_mm__c, Run_Days__c, Is_Active__c, Schedule_Description__c 
                FROM Copado_License_Cleanup_Schedule__mdt 
                WHERE DeveloperName = :DEFAULT_SCHEDULE_NAME 
                LIMIT 1
            ];
            
            System.debug(LoggingLevel.INFO, 'Current Schedule Configuration:');
            System.debug(LoggingLevel.INFO, 'Run Time: ' + config.Run_Time_HH_mm__c	);
            System.debug(LoggingLevel.INFO, 'Run Days: ' + config.Run_Days__c);
            System.debug(LoggingLevel.INFO, 'Is Active: ' + config.Is_Active__c);
            System.debug(LoggingLevel.INFO, 'Description: ' + config.Schedule_Description__c);
            
            List<CronTrigger> scheduledJobs = [
                SELECT Id, CronJobDetail.Name, CronExpression, NextFireTime
                FROM CronTrigger 
                WHERE CronJobDetail.Name LIKE 'Copado License Cleanup%'
                ORDER BY NextFireTime ASC
            ];
            
            System.debug(LoggingLevel.INFO, '\nCurrently Scheduled Jobs:');
            for(CronTrigger job : scheduledJobs) {
                System.debug(LoggingLevel.INFO, 'Job Name: ' + job.CronJobDetail.Name);
                System.debug(LoggingLevel.INFO, 'Next Run Time: ' + job.NextFireTime);
                System.debug(LoggingLevel.INFO, 'Cron Expression: ' + job.CronExpression);
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error checking schedule status: ' + e.getMessage());
        }
    }
}