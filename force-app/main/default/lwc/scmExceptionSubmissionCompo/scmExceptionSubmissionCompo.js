import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserStoriesDetails from '@salesforce/apex/ScmUserStoryController.getUserStoriesDetails';
import getReviewers from '@salesforce/apex/ScmExceptionController.getReviewers';
import requestScmException from '@salesforce/apex/ScmExceptionController.requestScmException';
import createReviewer from '@salesforce/apex/ScmExceptionController.createReviewer';
import { refreshApex } from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';
import DEVELOPER_FIELD from '@salesforce/schema/copado__User_Story__c.copado__Developer__c';
import RELEASE_FIELD from '@salesforce/schema/copado__User_Story__c.copado__Release__c';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class ScmExceptionSubmissionCompo extends LightningElement {
    @api recordId;
    @track reviewers;
    @track isModalOpen = false;
    @track showReviewersTable = false;
    refreshReviewers;
    @track error;
    @track userStoryId;
    @track developerName;
    @track environmentName;
    @track releaseName;
    @track userStory;
    reviewerId
    reviewerObj = { 'sobjectType': 'Reviewer__c' }
    @track justification = '';
    @track showSpinner = false;
    @track showExceptionDetails = true;
    @track isValidToOpen = true;
    @track hasDeveloper = false;
    @track noDev = false;
    userStoryWireResult;
    previousDeveloperId;
    previousReleaseId;
    developerRefreshKey = 0;
    releaseRefreshKey = 0;
    @track showSpinner1 = false;
    @track noReviewers = false;

    @track allReviewers = [];
    @track reviewers = [];
    @track searchKey = '';

    @track sortBy;
    @track sortDirection = 'asc';

    @track columns = [
        { label: 'Reviewer Name', fieldName: 'reviewerName', type: 'text', sortable: true },
        { label: 'Reviewer Email', fieldName: 'Reviewer_Email__c', type: 'text', sortable: true }
    ];

    @wire(getReviewers)
    wiredReviewers({ error, data }) {
        if (data) {
            this.allReviewers = data.map(row => ({
                ...row,
                reviewerName: row.Reviewer_Name__r?.Name || '-'
            }));

            this.reviewers = [...this.allReviewers];
            this.noReviewers = this.reviewers.length === 0;
            this.refreshReviewers = data;
        } else if (error) {
            this.error = error;
        }
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();

        this.reviewers = this.allReviewers.filter(row => {
            return (
                (row.reviewerName && row.reviewerName.toLowerCase().includes(this.searchKey)) ||
                (row.Reviewer_Email__c && row.Reviewer_Email__c.toLowerCase().includes(this.searchKey))
            );
        });
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;

        this.sortBy = fieldName;
        this.sortDirection = sortDirection;

        let data = [...this.reviewers];

        data.sort((a, b) => {
            let x = a[fieldName] || '';
            let y = b[fieldName] || '';

            x = typeof x === 'string' ? x.toLowerCase() : x;
            y = typeof y === 'string' ? y.toLowerCase() : y;

            return sortDirection === 'asc'
                ? x > y ? 1 : -1
                : x < y ? 1 : -1;
        });

        this.reviewers = data;
    }


    @wire(getRecord, { recordId: '$recordId', fields: [DEVELOPER_FIELD, RELEASE_FIELD] })
    wiredRecord(result) {
        this.recordWireResult = result;
        const { data, error } = result;

        if (error) {
            this.noDev = true;
            this.showExceptionDetails = false;
            this.resetUserStory();
            return;
        }

        if (!data) return;

        const developerId = data.fields.copado__Developer__c.value;
        const releaseId = data.fields.copado__Release__c.value;

        const hasDeveloper = !!developerId;

        const developerChanged =
            this.previousDeveloperId !== undefined &&
            developerId !== this.previousDeveloperId;

        const releaseChanged =
            this.previousReleaseId !== undefined &&
            releaseId !== this.previousReleaseId;

        this.noDev = !hasDeveloper;
        this.showExceptionDetails = hasDeveloper;
        this.isValidToOpen = hasDeveloper;

        if (developerChanged) this.developerRefreshKey++;
        if (releaseChanged) this.releaseRefreshKey++;

        this.previousDeveloperId = developerId;
        this.previousReleaseId = releaseId;

        if (!hasDeveloper) this.resetUserStory();
    }

    renderedCallback() {
        if (this.hasRefreshedOnce || !this.recordId) return;
        this.hasRefreshedOnce = true;

        // Force LDS to fetch latest Developer/Release values (no full page refresh)
        getRecordNotifyChange([{ recordId: this.recordId }]);

        // Optional but helpful: re-evaluate wires immediately
        if (this.recordWireResult) refreshApex(this.recordWireResult);
        if (this.userStoryWireResult) refreshApex(this.userStoryWireResult);
    }


    @wire(getUserStoriesDetails, {
        recordId: '$recordId',
        refreshKey: '$developerRefreshKey',
        releaseRefreshKey: '$releaseRefreshKey'
    })
    wiredUserStory(result) {
        this.userStoryWireResult = result;

        const { data, error } = result;

        if (this.noDev) {
            this.resetUserStory();
            return;
        }

        if (data && data.length > 0) {
            const story = data[0];
            this.userStoryId = story.Name;
            this.developerName = story.copado__Developer__r?.Name ?? '-';
            this.environmentName = story.copado__Environment__r?.Name ?? '-';
            this.releaseName = story.copado__Release__r?.Name ?? '-';
            this.userStory = story;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.resetUserStory();
        }
    }

    resetUserStory() {
        this.userStoryId = undefined;
        this.developerName = undefined;
        this.environmentName = undefined;
        this.releaseName = undefined;
        this.userStory = undefined;
    }

    handleJustificationChange(event) {
        this.justification = event.target.value;
        console.log('this.justification =' + this.justification);
    }

    handleCreateNewReviewer() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.justification = '';
    }

    handleRowSelection = event => {
        var selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 1) {
            var el = this.template.querySelector('lightning-datatable');
            selectedRows = el.selectedRows = el.selectedRows.slice(1);
            this.showToast('Warning', 'Only one Reviewer can be selected', 'warning');
            event.preventDefault();
            return;
        }
    }

    reviewerNameHandler(event) {
        this.SelectedReleaseName = event.detail.value;
        this.reviewerObj.Reviewer_Name__c = event.detail.value[0];
        console.log('this.reviewerObj.Reviewer_Name__c ==' + this.reviewerObj.Reviewer_Name__c);
    }

    createReviewer() {
        createReviewer({ reviewerObj: this.reviewerObj })
            .then(result => {
                if (result === 'success') {
                    this.showToast('Success', 'Reviewer created successfully', 'success');
                    this.closeModal();
                } else {
                    this.showToast('Error', result, 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleError(event) {
        this.showToast('Error', event.detail.message, 'error');
    }

    createScmException() {
        this.showSpinner = true;
        this.showExceptionDetails = false;
        const selectedRow = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRow=' + selectedRow);
        if (this.justification == null || this.justification.trim() === '') {
            this.showSpinner = false;
            this.showExceptionDetails = true;
            this.showToast('Error', 'Justification is Mandatory.', 'error');
        } else if (selectedRow.length !== 1) {
            this.showSpinner = false;
            this.showExceptionDetails = true;
            this.showToast('Error', 'Select atleast one Reviewer.', 'error');
        } else {
            // Both conditions are met, proceed with the request
            const selectedRecordId = selectedRow[0].Id;
            this.reviewerId = selectedRecordId;
            console.log('this.reviewerId =' + this.reviewerId);
            console.log('this.justification =' + this.justification);

            let params = {
                "userStoryId": this.recordId,
                "reviewerId": this.reviewerId,
                "justification": this.justification,
                "scmStrategy": this.selectedScmStrategy
            };

            requestScmException(params)
                .then(result => {
                    if (result === 'success') {
                        this.showToast('Success', 'SCM Exception Created successfully', 'success');
                        this.showSpinner = false;
                        this.closeQuickAction();
                        return refreshApex(this.refreshReviewers);
                    } else {
                        this.showSpinner = false;
                        this.showToast('Error', result, 'error');
                        this.closeQuickAction();
                    }
                })

                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                    // this.closeQuickAction();
                    this.showSpinner = false;
                    this.showExceptionDetails = false;
                });
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.justification = '';
    }
}