public class StorageMonitorScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.debug('Scheduling Queueable Job...');
        System.enqueueJob(new StorageMonitorQueue());
    }
}