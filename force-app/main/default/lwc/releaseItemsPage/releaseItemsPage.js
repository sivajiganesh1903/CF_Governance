import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getTemplateRecs from '@salesforce/apex/ReleasePlaybookController.getTemplateRecs';
import createReleasePlaybookItems from '@salesforce/apex/ReleasePlaybookController.createReleasePlaybookItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

const columns = [
   // { label: 'Record Id', fieldName: 'Id', type: 'text' },
  /* {
        label: 'Select',
        type: 'radio',
        //fieldName: 'Id', // This should match the field name in your data
        typeAttributes: {
            name: 'radioGroup', 
            checked: { fieldName: 'isSelected' }
        },
        fixedWidth: 50
    },*/
    { label: 'Name', fieldName: 'name', type: 'text' },
    { label: 'Release Playbook Template', fieldName: 'playbookName', type: 'text' },
    { label: 'Pipeline', fieldName: 'pipelineName', type: 'text' },
    { label: 'Status', fieldName: 'status', type: 'text' }
];

export default class ReleaseItemsPage extends NavigationMixin(LightningElement) {
    @track templatePage = true;
    @track templates = [];
    @track isLoading = false;
    columns = columns;
    recordsToDisplay = [];
    page = 1;
    pageSize = 10;
    totalRecountCount = 0;
    totalPage = 0;
    isFirstDisable = true;
    isPreviousDisable = true;
    isNextDisable = true;
    isLastDisable = true;
    selectedRecordId;

    releasePlaybookId; // Will be set dynamically
    selectedRecords = []; // Standard array

    pageSizeOptions = [10, 25, 50, 75, 100];

    @api value;
    @api checked;
    @api rowKeyValue;

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {
        this.isLoading = true;
        this.loadTemplates();
        this.setReleasePlaybookId();
    }

    setReleasePlaybookId() {
        if (this.currentPageReference && this.currentPageReference.state) {
            this.releasePlaybookId = this.currentPageReference.state.recordId;
            console.log('Record Id:  '+ this.releasePlaybookId);
        }
    }

    loadTemplates() {
        getTemplateRecs()
            .then(result => {
                console.log('Templates fetched: ', result);
                this.templates = result;
                this.totalRecountCount = result.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                this.updateRecordsToDisplay();
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleRecordsPerPage(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.updateRecordsToDisplay();
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedRecordId = selectedRows[0].Id; // Assuming only one record can be selected
        } else {
            this.selectedRecordId = null; // No record selected
        }
        console.log('Selected Record ID:', this.selectedRecordId);
    }

    initializeDatatable() {
        const datatable = this.template.querySelector('lightning-datatable');
        datatable.registerCustomDataType('radioButton', {
            template: radioButtonTemplate,
            standardCellLayout: true
        });
    }


    updateRecordsToDisplay() {
        const start = (this.page - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.recordsToDisplay = this.templates.slice(start, end);
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

    handleSave() {
        console.log('Selected Record ID:', this.selectedRecordId);
        console.log('Release Playbook ID:', this.releasePlaybookId);

        if (!this.releasePlaybookId || !this.selectedRecordId) {
            this.showToast('No Selection','No releases selected. No changes were made.','info');
            return;
        }

        createReleasePlaybookItems({ releasePlaybookId: this.releasePlaybookId, selectedTemplateId: this.selectedRecordId })
            .then(() => {
                this.showToast('Success', 'Record saved successfully!', 'success');
                this.closeModal();
                this.refreshView();
            })
            .catch(error => {
             /*   let errorMessage = 'Items already exist for this release playbook.';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                } */
                this.showToast('Error', 'Items already exist for this release playbook.', 'error');
                this.closeModal();
            });
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }
    refreshView() {
        eval("$A.get('e.force:refreshView').fire();");
    }
}