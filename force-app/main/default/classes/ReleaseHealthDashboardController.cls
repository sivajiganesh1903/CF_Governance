public with sharing class ReleaseHealthDashboardController {
    
    @AuraEnabled(cacheable=true)
    public static List<PipelineWrapper> getPipelines() {
        try {
            List<PipelineWrapper> pipelines = new List<PipelineWrapper>();
            for (copado__Deployment_Flow__c pipeline : [
                SELECT Id, Name 
                FROM copado__Deployment_Flow__c 
                ORDER BY Name ASC
            ]) {
                pipelines.add(new PipelineWrapper(pipeline.Id, pipeline.Name));
            }
            return pipelines;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching pipelines: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MainReleaseWrapper> getMainReleases(String pipelineId) {
        try {
            List<MainReleaseWrapper> mainReleases = new List<MainReleaseWrapper>();
            for (Main_Release__c mr : [
                SELECT Id, Name 
                FROM Main_Release__c 
                WHERE Pipeline__c = :pipelineId 
                ORDER BY Name ASC
            ]) {
                mainReleases.add(new MainReleaseWrapper(mr.Id, mr.Name));
            }
            return mainReleases;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching main releases: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static DashboardData getDashboardData(String mainReleaseId) {
        try {
            DashboardData dashboardData = new DashboardData();
            
            List<copado__Release__c> releases = [
                SELECT Id 
                FROM copado__Release__c 
                WHERE Main_Release__c = :mainReleaseId
            ];
            
            Set<Id> releaseIds = new Set<Id>();
            for (copado__Release__c rel : releases) {
                releaseIds.add(rel.Id);
            }
            
            List<copado__User_Story__c> userStories = [
                SELECT Id 
                FROM copado__User_Story__c 
                WHERE copado__Release__c IN :releaseIds
            ];
            
            Set<Id> userStoryIds = new Set<Id>();
            for (copado__User_Story__c us : userStories) {
                userStoryIds.add(us.Id);
            }
            
            dashboardData.numberOfStoriesDeployed = userStoryIds.size();
            
            List<copado__User_Story_Metadata__c> usMetadata = [
                SELECT copado__Metadata_API_Name__c 
                FROM copado__User_Story_Metadata__c 
                WHERE copado__User_Story__c IN :userStoryIds
            ];
            
            Set<String> uniqueComponents = new Set<String>();
            for (copado__User_Story_Metadata__c meta : usMetadata) {
                if (meta.copado__Metadata_API_Name__c != null) {
                    uniqueComponents.add(meta.copado__Metadata_API_Name__c);
                }
            }
            dashboardData.numberOfComponentsDeployed = uniqueComponents.size();
            
            dashboardData.codeQualityMetrics = getCodeQualityMetrics(mainReleaseId);
            
            return dashboardData;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching dashboard data: ' + e.getMessage());
        }
    }
    
    private static CodeQualityData getCodeQualityMetrics(String mainReleaseId) {
        CodeQualityData metrics = new CodeQualityData();
        
        List<Main_Release__c> mainReleases = [
            SELECT Pipeline__c 
            FROM Main_Release__c 
            WHERE Id = :mainReleaseId
            LIMIT 1
        ];
        
        if (mainReleases.isEmpty() || mainReleases[0].Pipeline__c == null) {
            return metrics;
        }
        
        Id pipelineId = mainReleases[0].Pipeline__c;
        
        List<Release_Playbook__c> playbooks = [
            SELECT Id 
            FROM Release_Playbook__c 
            WHERE Pipeline__c = :pipelineId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (playbooks.isEmpty()) {
            return metrics;
        }
        
        Id playbookId = playbooks[0].Id;
        
        List<Scan_Comparison__c> scanComparisons = [
            SELECT 
                Before_P1_Violations__c, After_P1_Violations__c, P1_Difference__c,
                Before_P2_Violations__c, After_P2_Violations__c, P2_Difference__c,
                Before_P3_Violations__c, After_P3_Violations__c, P3_Difference__c,
                Before_P4_Violations__c, After_P4_Violations__c, P4_Difference__c
            FROM Scan_Comparison__c 
            WHERE Release_Playbook__c = :playbookId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (!scanComparisons.isEmpty()) {
            Scan_Comparison__c scan = scanComparisons[0];
            
            metrics.p1 = new ViolationMetric(
                scan.Before_P1_Violations__c != null ? Integer.valueOf(scan.Before_P1_Violations__c) : 0,
                scan.After_P1_Violations__c != null ? Integer.valueOf(scan.After_P1_Violations__c) : 0,
                scan.P1_Difference__c != null ? Integer.valueOf(scan.P1_Difference__c) : 0
            );
            
            metrics.p2 = new ViolationMetric(
                scan.Before_P2_Violations__c != null ? Integer.valueOf(scan.Before_P2_Violations__c) : 0,
                scan.After_P2_Violations__c != null ? Integer.valueOf(scan.After_P2_Violations__c) : 0,
                scan.P2_Difference__c != null ? Integer.valueOf(scan.P2_Difference__c) : 0
            );
            
            metrics.p3 = new ViolationMetric(
                scan.Before_P3_Violations__c != null ? Integer.valueOf(scan.Before_P3_Violations__c) : 0,
                scan.After_P3_Violations__c != null ? Integer.valueOf(scan.After_P3_Violations__c) : 0,
                scan.P3_Difference__c != null ? Integer.valueOf(scan.P3_Difference__c) : 0
            );
            
            metrics.p4 = new ViolationMetric(
                scan.Before_P4_Violations__c != null ? Integer.valueOf(scan.Before_P4_Violations__c) : 0,
                scan.After_P4_Violations__c != null ? Integer.valueOf(scan.After_P4_Violations__c) : 0,
                scan.P4_Difference__c != null ? Integer.valueOf(scan.P4_Difference__c) : 0
            );
        }
        
        return metrics;
    }
    
    public class PipelineWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        
        public PipelineWrapper(String id, String name) {
            this.id = id;
            this.name = name;
        }
    }
    
    public class MainReleaseWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String name;
        
        public MainReleaseWrapper(String id, String name) {
            this.id = id;
            this.name = name;
        }
    }
    
    public class DashboardData {
        @AuraEnabled
        public Integer numberOfStoriesDeployed = 0;
        @AuraEnabled
        public Integer numberOfComponentsDeployed = 0;
        @AuraEnabled
        public CodeQualityData codeQualityMetrics = new CodeQualityData();
    }
    
    public class CodeQualityData {
        @AuraEnabled
        public ViolationMetric p1 = new ViolationMetric(0, 0, 0);
        @AuraEnabled
        public ViolationMetric p2 = new ViolationMetric(0, 0, 0);
        @AuraEnabled
        public ViolationMetric p3 = new ViolationMetric(0, 0, 0);
        @AuraEnabled
        public ViolationMetric p4 = new ViolationMetric(0, 0, 0);
    }
    
    public class ViolationMetric {
        @AuraEnabled
        public Integer before;
        @AuraEnabled
        public Integer after;
        @AuraEnabled
        public Integer difference;
        
        public ViolationMetric(Integer before, Integer after, Integer difference) {
            this.before = before;
            this.after = after;
            this.difference = difference;
        }
    }
}