public class PMDReportScheduler implements Schedulable {
    public  void execute(SchedulableContext ctx) {
        PMDReport1.orgscan();
    }
}