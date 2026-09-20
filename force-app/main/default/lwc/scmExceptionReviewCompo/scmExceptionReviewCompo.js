import { LightningElement, track } from 'lwc';
import fetchScmExceptions from '@salesforce/apex/ScmGlobalSettingPageController.fetchScmExceptions';
import updateScmExceptions from '@salesforce/apex/ScmGlobalSettingPageController.updateScmExceptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';

const columns = [
    {
        label: 'S.No.',
        fieldName: 'rowNumber',
        type: 'number',
        sortable: true,
        cellAttributes: { alignment: 'center' }
    },
    {
        label: 'SCM Exception',
        fieldName: 'recordUrl', // sort by Name
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
    },
    {
        label: 'Requested User Story',
        fieldName: 'requestedUserStoryUrl', // sort field
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'Requested_User_Story_Name' },
            target: '_blank',
            href: { fieldName: 'requestedUserStoryUrl' } // hyperlink preserved
        }
    },
    {
        label: 'Linked User Story',
        fieldName: 'linkedUserStoryUrl', // sort field
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'Linked_User_Story_Name' },
            target: '_blank',
            href: { fieldName: 'linkedUserStoryUrl' } // hyperlink preserved
        }
    },
    {
        label: 'Requested By',
        fieldName: 'Developer_Name',
        sortable: true
    },
    {
        label: 'Environment',
        fieldName: 'Environment__c',
        sortable: true
    },
    {
        label: 'Status',
        fieldName: 'Status__c',
        sortable: true
    },
    {
        label: 'Justification',
        fieldName: 'Justifications__c',
        sortable: true,
        cellAttributes: {
            class: 'text-wrap',
            style: 'white-space: normal; word-wrap: break-word;'
        }
    },
    {
        label: 'Type',
        fieldName: 'Type__c',
        sortable: true
    },
    {
        label: 'Perform Action',
        type: 'button',
        typeAttributes: {
            label: 'Take Action',
            name: 'processRecord',
            title: 'Click to process',
            variant: 'brand-outline',
            disabled: false,
            value: 'process'
        }
    }
];

export default class ScmExceptionReviewCompo extends LightningElement {
    //SCM Exception Home Page Start
    @track exceptions;
    @track error;
    @track totalRecord;
    showSpinnerFlag = false
    selectedRecordsCount = 0
    page1 = 1; //initialize 1st page
    @track recordsToDisplay = [];
    exceptions = [];
    @track columns = columns;;
    startingRecord1 = 1; //start record position per page
    endingRecord1 = 0; //end record position per page
    pageSize1 = 10; //default value we are assigning
    totalRecountCount1 = 0; //total record count received from all retrieved records
    totalPage1 = 0; //total number of page is needed to display all records
    selectedRows = [];
    pageSizeOptions1 = [10, 25, 50, 75, 100];
    @track isModalOpen = false;
    @track isDisabled = false;
    @track sortedBy;
    @track sortedDirection = 'asc';

    get isPreviousDisable1() {
        return this.page1 == 1;
    }
    get isNextDisable1() {
        return this.page1 == this.totalPage1;
    }

    connectedCallback() {
        this.fetchExceptions();
    }

    fetchExceptions() {
        this.showSpinnerFlag = true;

        fetchScmExceptions()
            .then(data => {
                this.showSpinnerFlag = false;
                this.error = undefined;

                this.allExceptions = this.exceptions = data.map((record, index) => {
                    const hasLinkedStory =
                        record.Linked_User_Story__c &&
                        record.Linked_User_Story__r &&
                        record.Linked_User_Story__r.Name;

                    return {
                        ...record,
                        rowNumber: index + 1,

                        Requested_User_Story_Name: record.Requested_User_Story__r
                            ? record.Requested_User_Story__r.Name
                            : '-',
                        requestedUserStoryUrl: record.Requested_User_Story__c
                            ? '/' + record.Requested_User_Story__c
                            : null,

                        Linked_User_Story_Name: hasLinkedStory
                            ? record.Linked_User_Story__r.Name
                            : '-',
                        linkedUserStoryUrl: hasLinkedStory
                            ? '/' + record.Linked_User_Story__c
                            : 'Not Applicable',

                        recordUrl: '/' + record.Id,

                        Developer_Name: record.Requested_By__r
                            ? record.Requested_By__r.Name
                            : '-'
                    };
                });


                this.totalRecord = this.exceptions.length;
                this.totalRecountCount1 = this.totalRecord;
                this.recordsToDisplay = this.exceptions.slice(0, this.pageSize1);
               // this.endingRecord1 = this.pageSize1;
               // this.pageSize1 = this.pageSizeOptions1[0];
                this.totalPage1 = Math.ceil(this.totalRecountCount1 / this.pageSize1);
            })
            .catch(error => {
                this.showSpinnerFlag = false;
                this.error = error;
                this.exceptions = undefined;
            });
    }


    selectedRecordsHandler(event) {
        let updatedItemsSet = new Set();

        // List of selected items we maintain.
        let selectedItemsSet = new Set(this.selectedRows);
        // List of items currently loaded for the current view.

        let loadedItemsSet = new Set();
        this.recordsToDisplay.map((ele) => {
            loadedItemsSet.add(ele.Id);

        });

        if (event.detail.selectedRows) {
            event.detail.selectedRows.map((ele) => {
                updatedItemsSet.add(ele.Id);
            });

            // Add any new items to the selectedRows list
            updatedItemsSet.forEach((id) => {
                if (!selectedItemsSet.has(id)) {
                    selectedItemsSet.add(id);
                }
            });
        }

        loadedItemsSet.forEach((id) => {
            if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                // Remove any items that were unselected.
                selectedItemsSet.delete(id);
            }
        });
        this.selectedRows = [...selectedItemsSet];
        this.selectedRecordsCount = this.selectedRows.length;
    }

    handleRecordsPerPage1(event) {
        this.pageSize1 = parseInt(event.target.value, 10);
        this.totalPage1 = Math.ceil(this.totalRecountCount1 / this.pageSize1);
        this.page1 = 1;
        this.displayRecordPerPage1(this.page1);
    }

    firstHandler1() {
        this.page1 = 1;
        this.displayRecordPerPage1(this.page1);
    }

    //press on previous button this method will be called
    previousHandler1() {
        if (this.page1 > 1) {
            this.page1 = this.page1 - 1;
            this.displayRecordPerPage1(this.page1);
        }
    }

    //press on next button this method will be called
    nextHandler1() {
        if ((this.page1 < this.totalPage1) && this.page1 !== this.totalPage1) {
            this.page1 = this.page1 + 1;
            this.displayRecordPerPage1(this.page1);
        }
    }

    lastHandler1() {
        this.page1 = this.totalPage1;
        this.displayRecordPerPage1(this.page1);
    }

    //this method displays records page by page
    displayRecordPerPage1(page1) {
        this.startingRecord1 = (page1 - 1) * this.pageSize1;
        this.endingRecord1 = Math.min(
            page1 * this.pageSize1,
            this.totalRecountCount1
        );

        this.recordsToDisplay = this.exceptions.slice(
            this.startingRecord1,
            this.endingRecord1
        );

        const datatable = this.template.querySelector('[data-id="datatable"]');
        if (datatable) {
            datatable.selectedRows = this.selectedRows;
        }
    }


    closeModalHandler() {
        this.isModalOpen = false;
        this.selectedAction = '';
        this.comments = '';
        this.isDisabled = false;
    }
    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;

        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;

        // Clone BEFORE sort
        let sortedData = [...this.allExceptions];

        sortedData.sort((a, b) => {
            let x = a[fieldName] ?? '';
            let y = b[fieldName] ?? '';

            if (typeof x === 'string') x = x.toLowerCase();
            if (typeof y === 'string') y = y.toLowerCase();

            return sortDirection === 'asc'
                ? x > y ? 1 : -1
                : x < y ? 1 : -1;
        });

        // Replace working list
        this.exceptions = sortedData;

        // Reset pagination safely
        this.page1 = 1;
        this.displayRecordPerPage1(this.page1);
    }

    sortData(fieldName, direction) {
        const isAsc = direction === 'asc';
        let data = [...this.exceptions];

        data.sort((a, b) => {
            let x = a[fieldName] ?? '';
            let y = b[fieldName] ?? '';

            if (typeof x === 'string') x = x.toLowerCase();
            if (typeof y === 'string') y = y.toLowerCase();

            return isAsc ? (x > y ? 1 : -1) : (x < y ? 1 : -1);
        });

        this.exceptions = data;
        this.displayRecordPerPage1(this.page1);
    }



    @track selectedAction;
    @track comments;

    options = [
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    handleChange(event) {
        this.selectedAction = event.detail.value;
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }


    rowId;

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        this.rowId = row.Id;
        console.log('this.rowId=1' + this.rowId);
        this.isModalOpen = true;

    }

    handleSubmit() {
        if (this.selectedAction != null && this.comments != null && this.comments.trim() !== '') {
            this.isDisabled = true;
            const record = this.exceptions.find(item => item.Id === this.rowId);

            if (record && record.Needs_to_be_Approved_by__c !== USER_ID && record.Type__c === 'Approval Process') {  // record.Type__c !== 'Approval Process'
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Permission Denied',
                        message: 'You are not allowed to take action on this request.',
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
                return;
            }
            updateScmExceptions({ recordId: this.rowId, selectedAction: this.selectedAction, comments: this.comments })
                .then(result => {
                    this.result = result;
                    this.isModalOpen = false;
                    this.showSuccessToast();
                    this.fetchExceptions();
                    this.error = null;
                    window.location.reload();
                    this.comments = '';
                    this.selectedAction = '';
                })
                .catch(error => {
                    this.error = error;
                    this.result = null;
                    this.isDisabled = false;
                });
        }
        else {
            this.showErrorToast();
        }
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Message',
            message: 'Successfully Done.....!!!',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    //SCM Exception Home Page Start

    showErrorToast() {
        const evt = new ShowToastEvent({
            title: 'Message',
            message: 'All required fields must be filled in.',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}