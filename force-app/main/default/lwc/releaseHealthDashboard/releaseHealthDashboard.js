import { LightningElement } from 'lwc';
import getPipelines from '@salesforce/apex/ReleaseHealthDashboardController.getPipelines';
import getMainReleases from '@salesforce/apex/ReleaseHealthDashboardController.getMainReleases';
import getDashboardData from '@salesforce/apex/ReleaseHealthDashboardController.getDashboardData';

export default class ReleaseHealthDashboard extends LightningElement {
    
    selectedPipelineId = null;
    selectedMainReleaseId = null;
    
    pipelineOptions = [];
    mainReleaseOptions = [];
    
    dashboardData = null;
    
    isLoading = false;
    errorMessage = '';
    
    get isDisabledMainRelease() {
        return !this.selectedPipelineId || this.isLoading;
    }
    
    get isDisabledSubmit() {
        return !this.selectedMainReleaseId || this.isLoading;
    }
    
    connectedCallback() {
        this.loadPipelines();
    }
    
    loadPipelines() {
        this.isLoading = true;
        this.errorMessage = '';
        
        getPipelines()
            .then(result => {
                this.pipelineOptions = result.map(pipeline => ({
                    label: pipeline.name,
                    value: pipeline.id
                }));
                console.log('Pipelines loaded:', this.pipelineOptions);
            })
            .catch(error => {
                console.error('Error loading pipelines:', error);
                this.errorMessage = 'Error loading pipelines: ' + error.body.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    handlePipelineChange(event) {
        this.selectedPipelineId = event.detail.value;
        this.selectedMainReleaseId = null;
        this.mainReleaseOptions = [];
        this.dashboardData = null;
        this.errorMessage = '';
        
        this.loadMainReleases();
        
        console.log('Pipeline selected:', this.selectedPipelineId);
    }
    
    loadMainReleases() {
        if (!this.selectedPipelineId) {
            return;
        }
        
        this.isLoading = true;
        this.errorMessage = '';
        
        getMainReleases({ pipelineId: this.selectedPipelineId })
            .then(result => {
                this.mainReleaseOptions = result.map(mr => ({
                    label: mr.name,
                    value: mr.id
                }));
                console.log('Main releases loaded:', this.mainReleaseOptions);
            })
            .catch(error => {
                console.error('Error loading main releases:', error);
                this.errorMessage = 'Error loading main releases: ' + error.body.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    handleMainReleaseChange(event) {
        this.selectedMainReleaseId = event.detail.value;
        this.dashboardData = null;
        this.errorMessage = '';
        
        console.log('Main release selected:', this.selectedMainReleaseId);
    }
    
    handleSubmit() {
        if (!this.selectedMainReleaseId) {
            this.errorMessage = 'Please select a Main Release';
            return;
        }
        
        this.isLoading = true;
        this.errorMessage = '';
        
        getDashboardData({ mainReleaseId: this.selectedMainReleaseId })
            .then(result => {
                this.dashboardData = result;
                console.log('Dashboard data loaded:', this.dashboardData);
                console.log('Stories deployed:', this.dashboardData.numberOfStoriesDeployed);
                console.log('Components deployed:', this.dashboardData.numberOfComponentsDeployed);
                console.log('P1 violations:', this.dashboardData.codeQualityMetrics.p1);
            })
            .catch(error => {
                console.error('Error loading dashboard data:', error);
                this.errorMessage = 'Error loading dashboard data: ' + error.body.message;
                this.dashboardData = null;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    get getP1MetricClass() {
        if (!this.dashboardData) return 'metric-neutral';
        const diff = this.dashboardData.codeQualityMetrics.p1.difference;
        return diff > 0 ? 'metric-bad' : (diff < 0 ? 'metric-good' : 'metric-neutral');
    }

    get getP2MetricClass() {
        if (!this.dashboardData) return 'metric-neutral';
        const diff = this.dashboardData.codeQualityMetrics.p2.difference;
        return diff > 0 ? 'metric-bad' : (diff < 0 ? 'metric-good' : 'metric-neutral');
    }

    get getP3MetricClass() {
        if (!this.dashboardData) return 'metric-neutral';
        const diff = this.dashboardData.codeQualityMetrics.p3.difference;
        return diff > 0 ? 'metric-bad' : (diff < 0 ? 'metric-good' : 'metric-neutral');
    }

    get getP4MetricClass() {
        if (!this.dashboardData) return 'metric-neutral';
        const diff = this.dashboardData.codeQualityMetrics.p4.difference;
        return diff > 0 ? 'metric-bad' : (diff < 0 ? 'metric-good' : 'metric-neutral');
    }
}