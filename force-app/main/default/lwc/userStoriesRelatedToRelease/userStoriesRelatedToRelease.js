import { LightningElement, api, track } from 'lwc';
import getUserStories from '@salesforce/apex/CopadoReleaseController.getUserStories';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UserStoriesRelatedToRelease extends LightningElement {
    @api recordId;  // The record Id of the Release_Playbook__c
    @track storyPage = true;
    @track storyData = [];
    @track isLoading = false;
    @track recordsToDisplay = [];
    @track page = 1;
    @track pageSize = 10;
    @track totalRecountCount = 0;
    @track totalPage = 0;
    @track isFirstDisable = true;
    @track isPreviousDisable = true;
    @track isNextDisable = true;
    @track isLastDisable = true;

    pageSizeOptions = [10, 25, 50, 75, 100];

    columns = [
        { label: 'Name', fieldName: 'url', type: 'url', typeAttributes: { label: { fieldName: 'name' }, target: '_blank'} },
        { label: 'JIRA Key', fieldName: 'jiraKey' },
        { label: 'Priority Severity', fieldName: 'prioritySeverity' },
        { label: 'Status', fieldName: 'status' },
        // { label: 'Record Type Name', fieldName: 'recordTypeName' },
        { label: 'User Story Title', fieldName: 'userStoryTitle' },
        { label: 'Team', fieldName: 'teamName' },
        { label: 'Developer', fieldName: 'developerId' },
        // { label: 'Release', fieldName: 'releaseName' }
    ];

    // handleDashboardClick(){
    //     console.log('Dashboard button clicked');
    //     window.open('/lightning/r/Dashboard/01Z4x000000EeznEAC/view', '_blank');
    // }

    connectedCallback() {
        this.isLoading = true;
        if (this.recordId) {
            this.loadStories();
        } else {
            //console.error('RecordId is undefined');
        }
    }

    loadStories() {
       // console.log('Fetching user stories for Release Playbook Id:', this.recordId);
        getUserStories({ releasePlaybookId: this.recordId })
            .then(result => {
                //this.storyData = result;
                //console.log('Fetched user stories:', this.storyData);
                this.storyData = result.map(record => {
                    return {
                        ...record,
                        url: `/lightning/r/copado__User_Story__c/${record.Id}/view`,
                    };
                });
                this.totalRecountCount = result.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                this.updateRecordsToDisplay();
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', error.body.message, 'error');
               // console.error('Error fetching user stories:', error);
            });
    }

    handleRecordsPerPage(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.updateRecordsToDisplay();
    }

    updateRecordsToDisplay() {
        const start = (this.page - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.recordsToDisplay = this.storyData.slice(start, end);
        this.updatePaginationControls();
    }

    updatePaginationControls() {
        this.isFirstDisable = this.page === 1;
        this.isPreviousDisable = this.page === 1;
        this.isNextDisable = this.page === this.totalPage;
        this.isLastDisable = this.page === this.totalPage;
    }

    firstHandler() {
        this.page = 1;
        this.updateRecordsToDisplay();
    }

    previousHandler() {
        this.page = this.page - 1;
        this.updateRecordsToDisplay();
    }

    nextHandler() {
        this.page = this.page + 1;
        this.updateRecordsToDisplay();
    }

    lastHandler() {
        this.page = this.totalPage;
        this.updateRecordsToDisplay();
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}