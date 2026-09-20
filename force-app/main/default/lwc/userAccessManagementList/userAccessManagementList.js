import { LightningElement, wire, track } from 'lwc';
import getUserAccessManagementRecords from '@salesforce/apex/UserAccessRecordRetriever.getUserAccessManagementRecords';

const columns = [
    { 
        label: 'Request Number', 
        fieldName: 'recordUrl', 
        type: 'url',
        typeAttributes: { label: { fieldName: 'name' }, target: '_blank' },
        sortable: true
    },
    { label: 'Full Name', fieldName: 'fullName', type: 'text', sortable: true },
    { label: 'Status', fieldName: 'status', type: 'text', sortable: true },
    { label: 'Environments', fieldName: 'environments', type: 'text', sortable: true },
    { label: 'DevOps', fieldName: 'devOpsName', type: 'text', sortable: true },
    { label: 'Division', fieldName: 'division', type: 'text', sortable: true },
    { label: 'Persona', fieldName: 'persona', type: 'text', sortable: true }
];

export default class UserAccessManagementList extends LightningElement {
    @track recordsToDisplay = [];
    @track columns = columns;
    @track sortBy;      // Field to sort by
    @track sortDirection;  // Sorting direction (asc/desc)

    showSpinnerFlag = false;
    selectedRecordsCount = 0; 
    page = 1;
    exceptions = [];
    startingRecord = 1;
    endingRecord = 0;
    pageSize = 10;
    totalRecountCount = 0;
    totalPage = 0;
    selectedRows = [];
    pageSizeOptions = [10, 25, 50, 75, 100];
    @track isModalOpen = false;

    connectedCallback() {
        this.getUserAccessManagementRecords();
    }

    getUserAccessManagementRecords() {
        this.showSpinnerFlag = true;
        getUserAccessManagementRecords()
            .then(data => {
                this.showSpinnerFlag = false;
                this.error = undefined;
                this.exceptions = data.map(record => ({
                    ...record,
                    recordUrl: '/' + record.recordId,
                }));
                this.totalRecountCount = this.exceptions.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                this.updateRecordsToDisplay();
            })
            .catch(error => {
                this.showSpinnerFlag = false;
                this.error = error;
                this.exceptions = undefined;
            });
    }

    updateRecordsToDisplay() {
        // Sort and then slice the data for pagination
        let dataToDisplay = [...this.exceptions];
        if (this.sortBy && this.sortDirection) {
            dataToDisplay = this.sortData(dataToDisplay);
        }
        const start = (this.page - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.recordsToDisplay = dataToDisplay.slice(start, end);
        this.endingRecord = this.page * this.pageSize;
        if (this.endingRecord > this.totalRecountCount) {
            this.endingRecord = this.totalRecountCount;
        }
        this.updatePaginationControls();
    }

    updatePaginationControls() {
        this.isFirstDisable = this.page === 1;
        this.isPreviousDisable = this.page === 1;
        this.isNextDisable = this.page === this.totalPage;
        this.isLastDisable = this.page === this.totalPage;
    }

    handleRecordsPerPage(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.page = 1;
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
        this.updateRecordsToDisplay();
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

    // New Sorting Logic
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
        this.updateRecordsToDisplay();
    }

    sortData(data) {
        const { sortBy, sortDirection } = this;
        const keyValue = (a) => a[sortBy] ? a[sortBy].toLowerCase() : ''; // Case-insensitive comparison
        const isReverse = sortDirection === 'asc' ? 1 : -1;
        return data.slice().sort((a, b) => {
            return isReverse * ((keyValue(a) > keyValue(b)) - (keyValue(b) > keyValue(a)));
        });
    }
}