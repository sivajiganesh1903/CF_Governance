import { LightningElement, api, track } from 'lwc';
import getCopadoReleases from '@salesforce/apex/CopadoReleaseController.getCopadoReleases';
import saveRelease from '@salesforce/apex/CopadoReleaseController.saveRelease';
import getAllUsers from '@salesforce/apex/CopadoReleaseController.getAllUsers';
import saveReleaseAssignments from '@salesforce/apex/CopadoReleaseController.saveReleaseAssignments';
import fetchUsers from '@salesforce/apex/CopadoReleaseController.fetchUsers';
import fetchReleases from '@salesforce/apex/CopadoReleaseController.fetchReleases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

// ReleasePage
const columns = [
    { label: 'Release Name', fieldName: 'releaseName' },
    { label: 'Status', fieldName: 'status' },
    { label: 'Project Name', fieldName: 'projectName' },
];

// UserPage
const userColumns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Email', fieldName: 'Email' }
];

export default class AssignReleaseAndUsers extends LightningElement {
    @api recordId; // This will hold the ID of the current page record

    // ReleasePage
    @track releases = [];
    @track error;
    @track isLoading = true;
    @track selectedReleaseRecs = [];
    releasePage = true;
    @track columns = columns;
    //UserPage
    userPage = false;
    @track userColumns = userColumns;
    @track isSpinner = true;
    @track users = [];
    @track selectedUserRecs = [];
    @track page = 1;
    @track page1 = 1;
    @track totalPage = 0;
    @track totalPage1 = 0;
    @track recordsToDisplay = [];
    @track recordsToDisplay1 = [];
    @track totalRecountCount = 0;
    @track totalRecountCount1 = 0;
    @track isPreviousDisable = true;
    @track isNextDisable = false;
    @track isPreviousDisable1 = true;
    @track isNextDisable1 = false;
    @track pageSizeOptions = [5, 10, 25, 50, 75, 100];
    @track pageSizeOptions1 = [5, 10, 25, 50, 75, 100];
    @track selectedPageSize = 5;
    @track selectedPageSize1 = 5;
    @track searchKey = '';
    @track searchKeyRelease = '';
    @track isAlertVisible = false;

    connectedCallback() {
        this.fetchReleaseRecords();
    }

    // ReleasePage

    handleKeyChangeRelease(event) {
        this.searchKeyRelease = event.target.value;
        this.page = 1;
        this.updateRecordsToDisplay();
    } 

    fetchReleaseRecords() {
        getCopadoReleases()
            .then((result) => {
                this.releases = result;
                this.totalRecountCount = result.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.selectedPageSize);
                this.recordsToDisplay = this.releases.slice(0, this.selectedPageSize);
                this.endingRecord1 = this.selectedPageSize;
                this.selectedPageSize = this.pageSizeOptions[0];
                this.columns = columns;
                this.updateRecordsToDisplay();
                this.isLoading = false;
                //I added
                this.isSpinner = false;
                this.error = undefined;

            })
            .catch((error) => {
                this.error = error;
                //this.isLoading = false; // I added
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleKeyChangeRelease(event) {
        const searchKeyRelease = event.target.value.toLowerCase();
        this.searchKeyRelease = searchKeyRelease;
        console.log('Searched Release==> ' + this.searchKeyRelease);
    
        if (searchKeyRelease) {
            fetchReleases({ searchKeyR: this.searchKeyRelease })
                .then(result => {
                    this.releases = result;
                    this.totalRecountCount = result.length;
                    this.totalPage = Math.ceil(this.totalRecountCount / this.selectedPageSize);
                    
                    // Update recordsToDisplay with the new search results
                    //this.recordsToDisplay = this.releases.slice(0, this.selectedPageSize);
                    this.updateRecordsToDisplay();
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        } else {
            this.fetchReleaseRecords();
        }
    }
      

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedReleaseRecs = selectedRows.map(row => row.releaseId);
        console.log('selectedRows=> ' + JSON.stringify(selectedRows));
        console.log('selectedReleaseRecs=> ', this.selectedReleaseRecs);
    }

    handleRecordsPerPage(event) {
        this.selectedPageSize = event.target.value;
        this.page = 1;
        this.updateRecordsToDisplay();
    }

    updateRecordsToDisplay() {
        const startIdx = (this.page - 1) * this.selectedPageSize;
        const endIdx = startIdx + this.selectedPageSize;
        this.recordsToDisplay = this.releases.slice(startIdx, endIdx);
        this.isPreviousDisable = this.page === 1;
        this.isNextDisable = this.page === this.totalPage;
        this.columns = columns;
    }

    firstHandler() {
        this.page = 1;
        this.updateRecordsToDisplay();
    }

    previousHandler() {
        this.page -= 1;
        this.updateRecordsToDisplay();
    }

    nextHandler() {
        this.page += 1;
        this.updateRecordsToDisplay();
    }

    lastHandler() {
        this.page = this.totalPage;
        this.updateRecordsToDisplay();
    }

    handleSave() {
        console.log('Inside saveHandler, playbookId=> ' + this.recordId);
        console.log('selectedReleaseRecs.length==> ' + this.selectedReleaseRecs.length);
        if (this.selectedReleaseRecs.length === 0) {
            this.dispatchEvent(
                this.showToast('No Selection', 'No releases selected. No changes were made.', 'info',)
            );
        } else {
            console.log('Inside else part of save handler');

        }
        this.isAlertVisible = true;
    }

    handleNext() {
        this.releasePage = false;
        this.isAlertVisible = false;
        this.userPage = true;
        this.loadUsers();
    }

    // UserPage
    handleKeyChange(event) {
        this.searchKey = event.target.value;
        this.page = 1;
        this.updateRecordsToDisplay1();
    }

    async loadUsers() {
        try {
            const data = await getAllUsers();
            console.log('Inside loadUsers, playbookId=> ' + this.recordId);
            this.users = data;
            this.totalRecountCount1 = this.users.length;
            this.totalPage1 = Math.ceil(this.totalRecountCount1 / this.selectedPageSize1);
            this.recordsToDisplay1 = this.users.slice(0, this.selectedPageSize1);
            this.endingRecord1 = this.selectedPageSize1;
            this.selectedPageSize1 = this.pageSizeOptions1[0];
            this.userColumns = userColumns;
            this.updateRecordsToDisplay1();
            this.isSpinner = false;
            this.error = undefined;
        } catch (error) {
            this.error = error;
            this.users = [];
        } finally {
            this.isSpinner = false;
        }
    }



    handleKeyChange(event) {
        const searchKey = event.target.value.toLowerCase();
        this.searchKey = searchKey;

        if (searchKey) {
            fetchUsers({ searchKey })
                .then(result => {
                    this.users = result;
                    this.totalRecountCount1 = result.length;
                    this.totalPage1 = Math.ceil(this.totalRecountCount1 / this.selectedPageSize1);
                    this.updateRecordsToDisplay1();
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
        } else {
            this.loadUsers();
        }
    }

    handleUserRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedUserRecs = selectedRows.map(row => row.Id);
        console.log('selectedRows=> ' + JSON.stringify(selectedRows));
        console.log('selectedUserRecs=> ', this.selectedUserRecs);
    }

    handleUserSave() {
        console.log('Inside saveHandler, playbookId=> ' + this.recordId);
        console.log('selectedUserRecs.length==> ' + this.selectedUserRecs.length);
        if (this.selectedUserRecs.length === 0) {
            this.dispatchEvent(
                this.showToast('No Selection', 'No User selected. No changes were made.', 'info',)
            );
            this.closeModal();
            this.refreshView();
        } else {
            console.log('Inside else part of save handler');
            saveReleaseAssignments({ playbookId: this.recordId, userIds: this.selectedUserRecs })
                .then(() => {
                    console.log('Playbook Id=> ' + this.recordId);
                    this.showToast('Success', 'Records saved successfully!', 'success');
                    this.closeModal();
                    this.refreshView();
                })
                .catch(error => {
                    this.showToast('Error', 'Failed', 'error');
                    console.error('Error updating records:', error);
                });
        }
    }

    handleRecordsPerPage1(event) {
        this.selectedPageSize1 = event.target.value;
        this.page1 = 1;
        this.updateRecordsToDisplay1();
    }

    updateRecordsToDisplay1() {
        const startIdx1 = (this.page1 - 1) * this.selectedPageSize1;
        const endIdx1 = startIdx1 + this.selectedPageSize1;
        this.recordsToDisplay1 = this.users.slice(startIdx1, endIdx1);
        this.isPreviousDisable1 = this.page1 === 1;
        this.isNextDisable1 = this.page1 === this.totalPage1;
    }

    firstHandler1() {
        this.page1 = 1;
        this.updateRecordsToDisplay1();
    }

    previousHandler1() {
        this.page1 -= 1;
        this.updateRecordsToDisplay1();
    }

    nextHandler1() {
        this.page1 += 1;
        this.updateRecordsToDisplay1();
    }

    lastHandler1() {
        this.page1 = this.totalPage1;
        this.updateRecordsToDisplay1();
    }

    handleBack() {
        this.releasePage = true;
        this.userPage = false;
        this.isAlertVisible = false;
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
    refreshView() {
        eval("$A.get('e.force:refreshView').fire();");
    }
    //Alert Button

    /*
        handleShowAlert() {
            this.isAlertVisible = true;
        }
            */

    handleCloseAlert() {
        this.isAlertVisible = false;
    }

    handleYes() {
        this.isAlertVisible = false;
        saveRelease({ playbookId: this.recordId, releaseIds: this.selectedReleaseRecs })
            .then(() => {
                console.log('Playbook Id=> ' + this.recordId);
                this.showToast('Success', 'Release record(s) saved successfully!', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Failed', 'error');
                console.error('Error updating records:', error);
            });
        this.handleNext()
    }

    handleNo() {
        saveRelease({ playbookId: this.recordId, releaseIds: this.selectedReleaseRecs })
            .then(() => {
                console.log('Playbook Id=> ' + this.recordId);
                this.showToast('Success', 'Release record(s) saved successfully!', 'success');
                this.closeModal();
                this.refreshView();
            })
            .catch(error => {
                this.showToast('Error', 'Failed', 'error');
                console.error('Error updating records:', error);
            });
        this.closeModal();
        this.refreshView();
        this.isAlertVisible = false;
    }
}