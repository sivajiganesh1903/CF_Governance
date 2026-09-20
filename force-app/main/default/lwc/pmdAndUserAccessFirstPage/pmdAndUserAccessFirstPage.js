import { LightningElement, track } from 'lwc';
import fetchPMDExceptions from '@salesforce/apex/PMDExceptionRetriever.fetchPMDExceptions';
import updatePMDExceptions from '@salesforce/apex/PMDExceptionRetriever.updatePMDExceptions';
import getUserAccessManagementRecords from '@salesforce/apex/UserAccessRecordRetriever.getUserAccessManagementRecords';
import updateUserAccessRequests from '@salesforce/apex/UserAccessRecordRetriever.updateUserAccessRequests';
import AuditLogo from '@salesforce/resourceUrl/AuditLogo';
import PmdLogo from '@salesforce/resourceUrl/PmdLogo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent' ;

//PMD Columns
const pmdColumns = [
    { 
        label: 'PMD Exception Name', 
        fieldName: 'recordUrl', 
        type: 'url',
        typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
    },
    { 
        label: 'User Story Name', 
        fieldName: 'userStoryUrl', 
        type: 'url',
        typeAttributes: { label: { fieldName: 'User_Story_Name' }, target: '_blank' }
    },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Comments', fieldName: 'Comments__c' },
    { label: 'Justification', fieldName: 'Justification__c' },
    { label: 'JIRA Key', fieldName: 'JIRA_Key__c' },
    {
        type: 'button',
        typeAttributes: {
            label: 'Take an Action',
            name: 'processRecord',
            title: 'Click to process',
            variant: 'brand-outline',
            disabled: false,
            value: 'process'
        }
    }
];

// User Access Columns
const columns1 = [
    { 
        label: 'Request Number', 
        fieldName: 'recordUrl', 
        type: 'url',
        typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
    },
    { label: 'First Name', fieldName: 'First_Name__c' },
    { label: 'Last Name', fieldName: 'Last_Name__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Product Team', fieldName: 'Product_Team__c' },
    { label: 'Environments', fieldName: 'Environments__c' },
    { label: 'Access Details', fieldName: 'Access_Details__c' },
    { label: 'Division', fieldName: 'Divsion__c' },
    {
        type: 'button',
        typeAttributes: {
            label: 'Take an Action',
            name: 'processRecord',
            title: 'Click to process',
            variant: 'brand-outline',
            disabled: false,
            value: 'process'
        }
    }
];


export default class PmdAndUserAccessFirstPage extends LightningElement {

    @track showFirstPage =true;
    @track showPmdExc= false;
    @track showUserRequests= false; 

    pmdhandler(){
        console.log('Inside PMDHandler');
        this.showPmdExc= true;
        this.showUserRequests= false;
        this.showFirstPage =false;
        this.fetchExceptions();
    }

    userRequestHandler(){
        console.log('Inside userAccess');
        this.showPmdExc= false;
        this.showUserRequests= true;
        this.showFirstPage =false; 
        this.getUserAccessManagementRecords();           
    }
    backHandler(){
        console.log('Inside backHandler');
        this.showPmdExc= false;
        this.showUserRequests= false;
        this.showFirstPage =true;         
    }
    

    // PMD Exception
    @track exceptions; 
    @track error;
    @track totalRecord;
    showSpinnerFlag = false
    selectedRecordsCount = 0 
    page1 = 1; //initialize 1st page
    @track recordsToDisplay =[];
    exceptions = [];
    @track columns
    @track pmdColumns
    startingRecord1 = 1; //start record position per page
    endingRecord1 = 0; //end record position per page
    pageSize1 = 10; //default value we are assigning
    totalRecountCount1 = 0; //total record count received from all retrieved records
    totalPage1 = 0; //total number of page is needed to display all records
    selectedRows = [];
    pageSizeOptions1 = [10, 25, 50, 75, 100];
    @track isModalOpen = false

    fetchExceptions() {
        this.showSpinnerFlag = true;
            fetchPMDExceptions()
                .then(data => {
                    console.log('PMD DATA=='+data)
                    this.showSpinnerFlag = false;
                    this.error = undefined;
                    this.exceptions = data.map(record => ({
                        ...record,
                        User_Story_Name: record.User_Story__r ? record.User_Story__r.Name : '',
                        recordUrl: '/' + record.Id,
                        userStoryUrl: '/' + record.User_Story__c
                    }));
                    this.totalRecord = data.length;
                    this.totalRecountCount1 = this.totalRecord;
                    this.recordsToDisplay = this.exceptions.slice(0, this.pageSize1);
                    this.endingRecord1 = this.pageSize1;
                    this.pageSize1 = this.pageSizeOptions1[0];
                    this.totalPage1 = Math.ceil(this.totalRecountCount1 / this.pageSize1);
                    this.pmdColumns = pmdColumns;
                })
                .catch(error => {
                    this.showSpinnerFlag = false;
                    this.error = error;
                    this.exceptions = undefined;
                });
        }


    selectedRecordsHandler(event){
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
            this.page1= this.page1 - 1;
            this.displayRecordPerPage1(this.page1);
        }
    }

    //press on next button this method will be called
    nextHandler1() {
        if ((this.page1 < this.totalPage1) && this.page1 !== this.totalPage1) {
            this.page1= this.page1 + 1;
            this.displayRecordPerPage1(this.page1);
        }
    }

    lastHandler1() {
            this.page1 = this.totalPage1 ;
            this.displayRecordPerPage1(this.page1);
    }

    //this method displays records page by page
    displayRecordPerPage1(page1) {
        this.startingRecord1 = ((page1 - 1) * this.pageSize1);
        this.endingRecord1 = (this.pageSize1 * page1);
        this.endingRecord1 = (this.endingRecord1 > this.totalRecountCount1)
            ? this.totalRecountCount1 : this.endingRecord1;
        this.recordsToDisplay = this.exceptions.slice(this.startingRecord1, this.endingRecord1);
        this.pmdColumns = pmdColumns;
        this.startingRecord1 = this.startingRecord1 + 1;
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRows;
    }

    closeModalHandler(){
        this.isModalOpen = false
    }

    @track selectedAction = '';
    @track comments = '';

    options = [
        { label: '--None--', value: '' },
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
        console.log('this.rowId=1'+this.rowId);
        this.isModalOpen = true;
        
    }
    
    handleSubmit() {
        updatePMDExceptions({ recordId: this.rowId, selectedAction: this.selectedAction, comments: this.comments })
            .then(result => {
                this.result = result;
                this.isModalOpen = false;
                this.showSuccessToast();
                this.fetchExceptions();
                this.error = null;
            })
            .catch(error => {
                this.error = error;
                this.result = null;
            });
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
                            title: 'Message',
                            message: 'Successfully Done.....!!!!',
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
        }

        get pmdLogo(){
            return PmdLogo;
        }

    // UserAccess
    @track exceptions; 
    @track error;
    showSpinnerFlag = false
    selectedRecordsCount = 0 
    page2 = 1; //initialize 1st page
    @track recordsToDisplay1 =[];
    exceptions = [];
    @track columns1 = columns1;; 
    startingRecord1 = 1; //start record position per page
    endingRecord1 = 0; //end record position per page
    pageSize1 = 10; //default value we are assigning
    totalRecountCount2 = 0; //total record count received from all retrieved records
    totalPage2 = 0; //total number of page is needed to display all records
    selectedRows = [];
    pageSizeOptions2 = [10, 25, 50, 75, 100];
    @track isModalOpen1 = false
    @track totalRecord1;

    getUserAccessManagementRecords() {
        this.showSpinnerFlag = true;
        getUserAccessManagementRecords()
                .then(data => {
                    this.showSpinnerFlag = false;
                    this.error = undefined;
                    this.exceptions = data.map(record => ({
                        ...record,
                        recordUrl: '/' + record.Id,
                    }));
                    this.totalRecord1 = data.length;
                    this.totalRecountCount2 = this.totalRecord1;
                    this.recordsToDisplay1 = this.exceptions.slice(0, this.pageSize1);
                    this.endingRecord1 = this.pageSize1;
                    this.pageSize1 = this.pageSizeOptions2[0];
                    this.totalPage2 = Math.ceil(this.totalRecountCount2 / this.pageSize1);
                })
                .catch(error => {
                    this.showSpinnerFlag = false;
                    this.error = error;
                    this.exceptions = undefined;
                });
        }


    selectedRecordsHandler(event){
        let updatedItemsSet = new Set();
    
            // List of selected items we maintain.
            let selectedItemsSet = new Set(this.selectedRows);
            // List of items currently loaded for the current view.
    
            let loadedItemsSet = new Set();
            this.recordsToDisplay1.map((ele) => {
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

    
   
    handleRecordsPerPage2(event) {
        this.pageSize1 = parseInt(event.target.value, 10); 
        this.totalPage2 = Math.ceil(this.totalRecountCount2 / this.pageSize1);
        this.page2 = 1; 
        this.displayRecordPerPage1(this.page2);
    }

    firstHandler2() {
            this.page2 = 1;
            this.displayRecordPerPage1(this.page2);
    }

    //press on previous button this method will be called
    previousHandler2() {
        if (this.page2 > 1) {
            this.page2= this.page2 - 1;
            this.displayRecordPerPage1(this.page2);
        }
    }

    //press on next button this method will be called
    nextHandler2() {
        if ((this.page2 < this.totalPage2) && this.page2 !== this.totalPage2) {
            this.page2= this.page2 + 1;
            this.displayRecordPerPage1(this.page2);
        }
    }

    lastHandler2() {
            this.page2 = this.totalPage2 ;
            this.displayRecordPerPage1(this.page2);
    }

    //this method displays records page by page
    displayRecordPerPage1(page2) {
        this.startingRecord1 = ((page2 - 1) * this.pageSize1);
        this.endingRecord1 = (this.pageSize1 * page2);
        this.endingRecord1 = (this.endingRecord1 > this.totalRecountCount2)
            ? this.totalRecountCount2 : this.endingRecord1;
        this.recordsToDisplay1 = this.exceptions.slice(this.startingRecord1, this.endingRecord1);
        
        this.startingRecord1 = this.startingRecord1 + 1;
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRows;
    }

    closeModalHandler1(){
        this.isModalOpen1 = false
    }

    @track selectedAction1 = '';
    @track comments1 = '';

    options2 = [
        { label: '--None--', value: '' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    handleChange2(event) {
        this.selectedAction1 = event.detail.value;
    }

    handleCommentsChange1(event) {
        this.comments1 = event.target.value;
    }

   
    rowId;

    handleRowAction1(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        this.rowId = row.Id;
        console.log('this.rowId=1'+this.rowId);
        this.isModalOpen1 = true;
        
    }
    
    handleSubmit1() {
        updateUserAccessRequests({ recordId: this.rowId, selectedAction: this.selectedAction1, comments: this.comments1 })
            .then(result => {
                this.result = result;
                this.isModalOpen1 = false;
                this.showSuccessToast();
                this.fetchExceptions();
                this.error = null;
            })
            .catch(error => {
                this.error = error;
                this.result = null;
            });
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
                            title: 'Message',
                            message: 'Successfully Done.....!!!!',
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
        }
        
        get audit(){
            return AuditLogo;
        }
}