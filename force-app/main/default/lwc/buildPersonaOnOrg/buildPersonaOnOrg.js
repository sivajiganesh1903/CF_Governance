import { LightningElement, track, wire } from 'lwc';
import getOrgJsonAttachment from '@salesforce/apex/FirecallFrameworkController.getOrgJsonAttachment';
import getPersonaOrgId from '@salesforce/apex/FirecallFrameworkController.getPersonaOrgId';
import makeJsonAttachment from '@salesforce/apex/FirecallFrameworkController.makeJsonAttachment'; // <-- use the method that accepts fileName
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLatestPermissionsJson from '@salesforce/apex/FirecallFrameworkController.getLatestPermissionsJson';

export default class BuildPersonaOnOrg extends LightningElement {

    // ---------- basic state ----------
    orgId;
    recordId;

    @track permissionsHeading = 'Available Permissions';
    @track jsonData = [];
    @track filteredData = [];
    @track columns = [];
    @track recordsToDisplay = [];
    @track error;
    @track isLoading = false;
    @track selectedPersonaScreen = false;

    // ---------- pagination ----------
    @track page = 1;
    @track pageSize = 10;
    @track totalRecords = 0;
    @track totalPages = 1;
    @track pageSizeOptions = [10, 25, 50, 75, 100];
    @track isNextDisable = false;
    @track isPreviousDisable = true;
    @track isUpdateDisabled = false;

    // ---------- selection ----------
    selectedRowIdSet = new Set();      // for bookkeeping
    selectedRowIds = [];             // array of ids – fed to datatable
    selectedRows = [];             // full row objects – becomes JSON
    @track isStarttDisabled = true;     // button disabled until a pick

    // ---------- ui flags ----------
    showPermissionPage = true;

    // ---------- get recordId from the recordAction context ----------
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef?.state?.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }
    handleNewBuild(){
        this.showPermissionPage = true;
        this.ExistingPersonaScreen = false;
        this.fetchOrgIdAndLoadData();
    }
    handleExistinguild(){
        this.ExistingPersonaScreen = true;
        this.showPermissionPage = false;
    }

    // ---------- life‑cycle ----------
    connectedCallback() {
        if (!this.recordId) return;
     //   this.fetchOrgIdAndLoadData();
    }

    // ---------- server calls ----------
    fetchOrgIdAndLoadData() {
        this.isLoading = true;
        getPersonaOrgId({ personaId: this.recordId })
            .then(orgId => {
                this.orgId = orgId;
                return getOrgJsonAttachment({ orgId });
            })
            .then(jsonString => {
                const parsed = JSON.parse(jsonString);
                if (!Array.isArray(parsed) || parsed.length === 0) {
                    this.error = 'No data found or invalid JSON structure.';
                    return;
                }

                const desiredOrder = ['Name', 'Description', 'ComponentType'];
                this.columns = desiredOrder.map(key => ({
                    label: this.formatLabel(key),
                    fieldName: key,
                    type: 'text'
                }));

                this.jsonData = parsed.map((item, idx) => ({
                    ...item,
                    recordId: item.Id,
                    id: idx + 1            // lightning‑datatable needs a unique key
                }));

                this.filteredData = [...this.jsonData];
                this.totalRecords = this.filteredData.length;
                this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                this.displayRecords(this.page);
            })
            .catch(err => {
                this.error = err?.body?.message || err.message;
                // eslint-disable-next-line no-console
                console.error(err);
            })
            .finally(() => (this.isLoading = false));
    }

    // ---------- helpers ----------
    formatLabel(key) {
        return key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase());
    }

    displayRecords(page) {
        const start = (page - 1) * this.pageSize;
        const end = Math.min(start + this.pageSize, this.totalRecords);
        this.recordsToDisplay = this.filteredData.slice(start, end);

        // keep datatable in sync when navigating pages
        this.selectedRowIds = this.recordsToDisplay
            .filter(r => this.selectedRowIdSet.has(r.id))
            .map(r => r.id);

        this.updatePaginationButtons();
    }

    updatePaginationButtons() {
        this.isPreviousDisable = this.page <= 1;
        this.isNextDisable = this.page >= this.totalPages;
    }

    // ---------- UI handlers ----------
    handleRecordsPerPage(event) {
        this.pageSize = Number(event.target.value);
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.page = 1;
        this.displayRecords(this.page);
    }

    handleSearch(event) {
        const term = event.target.value?.toLowerCase() || '';
        this.filteredData = term
            ? this.jsonData.filter(rec =>
                Object.values(rec).some(v => String(v).toLowerCase().includes(term))
            )
            : [...this.jsonData];

        this.totalRecords = this.filteredData.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.page = 1;
        this.displayRecords(this.page);
    }

    handleRowSelection(event) {
        const justSelected = event.detail.selectedRows;  // <-- correct property

        // 1) update master Set of ids
        justSelected.forEach(r => this.selectedRowIdSet.add(r.id));
        this.recordsToDisplay
            .map(r => r.id)
            .forEach(id => {
                if (!justSelected.some(r => r.id === id)) {
                    this.selectedRowIdSet.delete(id);
                }
            });

        // 2) refresh arrays used elsewhere
        this.selectedRows = this.jsonData.filter(r => this.selectedRowIdSet.has(r.id));
        this.selectedRowIds = this.selectedRows.map(r => r.id);

        // 3) enable / disable button
        this.isStarttDisabled = this.selectedRows.length === 0;
    }

    /* pagination buttons */
    firstHandler() { this.page = 1; this.displayRecords(this.page); }
    previousHandler() { if (this.page > 1) { --this.page; this.displayRecords(this.page); } }
    nextHandler() { if (this.page < this.totalPages) { ++this.page; this.displayRecords(this.page); } }
    lastHandler() { this.page = this.totalPages; this.displayRecords(this.page); }

    handleNextBuild(){
        this.showPermissionPage = false;
        this.selectedPersonaScreen = true;
    }

    // ---------- Build / Save ----------
    handleBuild() {
        if (this.selectedRows.length === 0) return;   // nothing to save

        this.isLoading = true;
        const jsonString = JSON.stringify(this.selectedRows, null, 2);
        const fileName = `SelectedPermissions_${Date.now()}.json`;

        makeJsonAttachment({
            parentId: this.recordId,
            jsonString,
            fileName
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Selected permissions saved as attachment.',
                        variant: 'success'
                    })
                );
                this.showPermissionPage = false;          // hide the table, if desired
            })
            .catch(err => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error saving attachment',
                        message: err?.body?.message || err.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => (this.isLoading = false));
    }
    handleupdatePersona(){
        this.isUpdateDisabled = true;
        this.updatePersonaScreen = true;
    }

    //Update Persona Screen
    @track updatePersonaScreen = false;
    @track existingJsonData = [];
    @track filteredData = [];

    get hasData() { 
        return this.existingJsonData?.length > 0; 
    }

    fetchData() {
        if (!this.recordId) return;
        this.isLoading = true;

        getLatestPermissionsJson({ parentId: this.recordId })
            .then(result => {
                const data = JSON.parse(result);
                // Use `data` in your datatable
            })
            .catch(error => {
                console.error('Error reading JSON file', error);
            });
    }

    // ---------- helpers ----------
    formatLabel(key) {
        return key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase());
    }
    
}