import { LightningElement, track } from 'lwc';

import getPipelines from '@salesforce/apex/ComplianceHomeController.getPipelines';
import getMainReleasesByPipeline from '@salesforce/apex/ComplianceHomeController.getMainReleasesByPipeline';
import getUserStoriesByMainRelease from '@salesforce/apex/ComplianceHomeController.getUserStoriesByMainRelease';

export default class ComplianceHome extends LightningElement {

    @track pipelineOptions = [];
    @track mainReleaseOptions = [];
    @track tableData = [];

    selectedPipeline;
    selectedMainRelease;

    isLoading = false;

    columns = [
        { label: 'Release', fieldName: 'ReleaseName' },

        {
            label: 'User Story',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'UserStoryName' },
                target: '_blank'
            }
        },

        { label: 'Exception Hotfix', fieldName: 'ExceptionHotfixCategory' },
        { label: 'Exception Justification', fieldName: 'ExceptionJustification' },
        { label: 'Exception Approver', fieldName: 'ExceptionApprover' },
        { label: 'Metadata Component', fieldName: 'MetadataComponent' },
        { label: 'Metadata Type', fieldName: 'MetadataType', type : 'text', wrapText : true },
        { label: 'Credential', fieldName: 'Credential' },
        { label: 'Developer', fieldName: 'Developer' },
        { label: 'Team', fieldName: 'Team' }
    ];

    connectedCallback() {
        this.loadPipelines();
    }

    loadPipelines() {
        this.isLoading = true;

        getPipelines()
            .then(result => {
                this.pipelineOptions = result.map(item => ({
                    label: item.Name,
                    value: item.Id
                }));
            })
            .catch(error => console.error(error))
            .finally(() => this.isLoading = false);
    }

    handlePipelineChange(event) {
        this.selectedPipeline = event.detail.value;

        this.selectedMainRelease = null;
        this.mainReleaseOptions = [];
        this.tableData = [];

        this.loadMainReleases();
    }

    loadMainReleases() {
        if (!this.selectedPipeline) return;

        this.isLoading = true;

        getMainReleasesByPipeline({ pipelineId: this.selectedPipeline })
            .then(result => {
                this.mainReleaseOptions = result.map(item => ({
                    label: item.Name,
                    value: item.Id
                }));
            })
            .catch(error => console.error(error))
            .finally(() => this.isLoading = false);
    }

    handleMainReleaseChange(event) {
        this.selectedMainRelease = event.detail.value;
        this.loadTableData();
    }

    loadTableData() {
        if (!this.selectedMainRelease) return;

        this.isLoading = true;

        getUserStoriesByMainRelease({ mainReleaseId: this.selectedMainRelease })
            .then(result => {

                let tempData = [];

                result.forEach(item => {

                // ✅ Loop over committed components directly
                let metadataRecords = item.copado__User_Story_Metadata__r?.length
                    ? item.copado__User_Story_Metadata__r
                    : [{ copado__Metadata_API_Name__c: '', copado__Type__c: '' }]; // blank row if no components

                metadataRecords.forEach(m => {
                    tempData.push({
                        Id: item.Id + '_' + m.copado__Metadata_API_Name__c, // unique key
                        ReleaseName: item.copado__Release__r?.Name,
                        UserStoryName: item.Name,
                        recordUrl: '/' + item.Id,
                        ExceptionHotfixCategory: item.Exception_Hotfix_Requirement__c,
                        ExceptionJustification: item.Exception_Justification__c,
                        ExceptionApprover: item.Exception_Approver__c,
                        MetadataComponent: m.copado__Metadata_API_Name__c, // ✅ component name
                        MetadataType: m.copado__Type__c,                   // ✅ its type
                        Credential: item.copado__Org_Credential__r?.Name,
                        Developer: item.copado__Developer__r?.Name,
                        Team: item.copado__Team__r?.Name
                    });
                });

            });

                this.tableData = tempData;

            })
            .catch(error => console.error(error))
            .finally(() => this.isLoading = false);
    }

    handleDownload() {
        if (!this.selectedMainRelease) {
            alert('Please select Main Release');
            return;
        }
 
        const url = `/apex/CompliancePDFPage?mainReleaseId=${this.selectedMainRelease}`;
 
        window.open(url, '_blank');
    }
}