// personaViewer.js
import { LightningElement, track, wire } from 'lwc';
import getLatestPermissionsJson from '@salesforce/apex/FirecallFrameworkController.getLatestPermissionsJson';
import getPersonaOrgId from '@salesforce/apex/FirecallFrameworkController.getPersonaOrgId';
import getOrgJsonAttachment from '@salesforce/apex/FirecallFrameworkController.getOrgJsonAttachment';
import makeJsonAttachment from '@salesforce/apex/FirecallFrameworkController.makeJsonAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class PersonaViewer extends LightningElement {

    recordId;
    @wire(CurrentPageReference)
    wiredRef(p) { this.recordId = p?.state?.recordId; }

    @track personaButtonClicked = true;
    @track showPermissionPage = false;
    @track showSelectedPermissions = false;
    existingPermissionNames = new Set();

    isLoading = true;
    fileFound = false;
    error;

    existingPermissionsHeading = 'Existing Permissions';
    @track columns = [];
    @track jsonData = [];
    @track filteredData = [];
    @track recordsToDisplay = [];

    page = 1;
    pageSize = 10;
    totalRecords = 0;
    totalPages = 1;
    isPreviousDisable = true;
    isNextDisable = false;   

    isUpdateDisabled = false;
    isLoading1 = false;
    error1;
    permissionsHeading = 'Available Permissions';
    @track jsonData1 = [];
    @track filteredData1 = [];
    @track recordsToDisplay1 = [];

    page1 = 1;
    pageSize1 = 10;
    totalRecords1 = 0;
    totalPages1 = 1;
    isPreviousDisable1 = true;
    isNextDisable1 = false;
    pageSizeOptions1 = [5, 10, 20];

    selectedRowIdSet1 = new Set();
    @track selectedRowIds1 = [];
    @track selectedRows1 = [];

    isNextDisabled = true;

    // SCREEN‑1  :  load existing persona JSON
    connectedCallback() {
        this.loadExistingPersona();
    }

    loadExistingPersona() {
        if (!this.recordId) return;
        this.isLoading = true;
        this.error = undefined;


        getLatestPermissionsJson({ parentId: this.recordId })
            .then(jsonString => {
               
                if (!jsonString) { this.fileFound = false; return; }
                const parsed = JSON.parse(jsonString);
                if (!Array.isArray(parsed) || parsed.length === 0) { this.fileFound = false; return; }
               
                const desiredOrder = ['Name', 'Description', 'ComponentType'];
                this.columns = desiredOrder.map(key => ({
                    label: this.formatLabel(key),
                    fieldName: key,
                    type: 'text'
                }));
                
                this.jsonData = parsed.map((row, idx) => ({
                    id: idx + 1,   
                    ...row          
                }));

                this.filteredData = [...this.jsonData];
                this.totalRecords = this.filteredData.length;
                this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                this.displayRecords(this.page);
                this.fileFound = true;
                this.existingPermissionNames = new Set(parsed.map(r => r.Name));
            })
            .catch(err => { this.error = err?.body?.message || err.message; this.fileFound = false; })
            .finally(() => (this.isLoading = false));
    }


    buildColumns(sampleRow) {
        this.columns = Object.keys(sampleRow).filter(k => k !== 'id').map(k => ({
            label: this.formatLabel(k),
            fieldName: k,
            type: 'text'
        }));
    }

    formatLabel(k) { return k.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase()); }

    /* table‑1 pagination & search */
    displayRecords(p) {
        const start = (p - 1) * this.pageSize;
        const end = Math.min(start + this.pageSize, this.totalRecords);
        this.recordsToDisplay = this.filteredData.slice(start, end);
        this.isPreviousDisable = p <= 1;
        this.isNextDisable = p >= this.totalPages;
    }

       handleSearch(event) {
        const t = (event.target.value || '').toLowerCase();
        this.filteredData = t ? this.jsonData.filter(r => Object.values(r).some(v => String(v).toLowerCase().includes(t))) : [...this.jsonData];
        this.totalRecords = this.filteredData.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.page = 1; this.displayRecords(this.page);   
    } 

    firstHandler() { this.page = 1; this.displayRecords(this.page); }
    previousHandler() { if (this.page > 1) { this.page--; this.displayRecords(this.page); } }
    nextHandler() { if (this.page < this.totalPages) { this.page++; this.displayRecords(this.page); } }
    lastHandler() { this.page = this.totalPages; this.displayRecords(this.page); } 

    handleUpdatePersona() {
        this.personaButtonClicked = false;
        this.showPermissionPage = true;
        this.fetchOrgTemplate();
    }
 
    fetchOrgTemplate() {
        this.isLoading1 = true;
        this.error1 = undefined;

        getPersonaOrgId({ personaId: this.recordId })
            .then(orgId => getOrgJsonAttachment({ orgId }))
            .then(jsonString => {

                const parsed = JSON.parse(jsonString || '[]');
                if (!Array.isArray(parsed) || parsed.length === 0) {
                    this.error1 = 'No permission metadata is attached to the related Org. Please retrieve the metadata from Org record.';
                    return;
                }

                const desiredOrder = ['Name', 'Description', 'ComponentType'];
                this.columns = desiredOrder.map(key => ({
                    label: this.formatLabel(key),
                    fieldName: key,
                    type: 'text'
                }));

                this.jsonData1 = parsed.map((row, idx) => ({
                    id: idx + 1,      
                    ...row
                }));

 
                this.selectedRowIdSet1 = new Set(
                    this.jsonData1
                        .filter(r => this.existingPermissionNames.has(r.Name))
                        .map(r => r.id)
                );
                this.selectedRows1 = this.jsonData1.filter(r => this.selectedRowIdSet1.has(r.id));
                this.selectedRowIds1 = [...this.selectedRowIdSet1];
                this.isNextDisabled = this.selectedRows1.length === 0;

                this.filteredData1 = [...this.jsonData1];
                this.buildComponentTypeOptions(this.jsonData1);
                this.totalRecords1 = this.filteredData1.length;
                this.totalPages1 = Math.ceil(this.totalRecords1 / this.pageSize1);
                this.page1 = 1;
                this.displayRecords1(this.page1);

            })
            .catch(err => {
                this.error1 = err?.body?.message || err.message;
            })
            .finally(() => {
                this.isLoading1 = false;
            });
    }


    get totalSelected() {
        return this.selectedRowIdSet1.size;
    }

    handleBuildPersona() {
        this.personaButtonClicked = false;
        this.showPermissionPage = true;
        this.showSelectedPermissions = false;
        this.fetchOrgTemplate();
    }


    // SCREEN‑2 : fetch template JSON for building persona 
    selectedComponentType = '';
    componentTypeOptions = [];
    searchTerm = '';

    buildComponentTypeOptions(data) {
        const uniq = [...new Set(data.map(r => r.ComponentType))].sort();
        this.componentTypeOptions = [
            { label: 'All types', value: '' },
            ...uniq.map(t => ({ label: t, value: t }))
        ];
    }

    applyFilters() {
  
        const byText = this.searchTerm
            ? this.jsonData1.filter(r =>
                Object.values(r)
                    .some(v => String(v).toLowerCase().includes(this.searchTerm))
            )
            : [...this.jsonData1];

        this.filteredData1 = this.selectedComponentType
            ? byText.filter(r =>
                (r.ComponentType || '').toLowerCase() ===
                this.selectedComponentType.toLowerCase()
            )
            : byText;

        this.totalRecords1 = this.filteredData1.length;
        this.totalPages1 = Math.ceil(this.totalRecords1 / this.pageSize1);
        this.page1 = 1;
        this.displayRecords1(this.page1);
    }

    handleSearch(event) {
        this.searchTerm = (event.target.value || '').toLowerCase();
        this.applyFilters();
    }

    handleComponentTypeFilter(event) {
        this.selectedComponentType = event.detail.value;  
        this.applyFilters();
    }

    handleBuild() {
        if (this.selectedRows1.length === 0) return;   

        this.isLoading = true;
        const jsonString = JSON.stringify(this.selectedRows1, null, 2);
        const fileName = `SelectedPermissions_${Date.now()}.json`;

        makeJsonAttachment({ parentId: this.recordId, jsonString, fileName })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success', message: 'Persona has been created successfully.', variant: 'success'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
                this.personaButtonClicked = false;
                this.showPermissionPage = false;
                this.showSelectedPermissions = false;
            })
            .catch(err => {
                this.dispatchEvent(
                    new ShowToastEvent({ title: 'Error saving attachment', message: err?.body?.message || err.message, variant: 'error' })
                );
            })
            .finally(() => (this.isLoading = false));
    }

    displayRecords1(p) {
        const start = (p - 1) * this.pageSize1;
        const end = Math.min(start + this.pageSize1, this.totalRecords1);

        this.recordsToDisplay1 = this.filteredData1.slice(start, end);
        this.selectedRowIds1 = [...this.selectedRowIdSet1];

        this.isPreviousDisable1 = p <= 1;
        this.isNextDisable1 = p >= this.totalPages1;
    }

    handleSearch1(e) {
        const t = (e.target.value || '').toLowerCase();
        this.filteredData1 = t ? this.jsonData1.filter(r => Object.values(r).some(v => String(v).toLowerCase().includes(t))) : [...this.jsonData1];
        this.totalRecords1 = this.filteredData1.length;
        this.totalPages1 = Math.ceil(this.totalRecords1 / this.pageSize1);
        this.page1 = 1; this.displayRecords1(this.page1);
    }

    handleRecordsPerPage1(e) {
        this.pageSize1 = Number(e.target.value);
        this.totalPages1 = Math.ceil(this.totalRecords1 / this.pageSize1);
        this.page1 = 1; this.displayRecords1(this.page1);
    }

    handleRowSelection1(e) {
        const sel = e.detail.selectedRows || [];
        sel.forEach(r => this.selectedRowIdSet1.add(r.id));
        this.recordsToDisplay1.map(r => r.id).forEach(id => { if (!sel.some(r => r.id === id)) { this.selectedRowIdSet1.delete(id); } });
        this.selectedRows1 = this.jsonData1.filter(r => this.selectedRowIdSet1.has(r.id));
        this.selectedRowIds1 = this.selectedRows1.map(r => r.id);
        this.isNextDisabled = this.selectedRows1.length === 0;
    }

    firstHandler1() { this.page1 = 1; this.displayRecords1(this.page1); }
    previousHandler1() { if (this.page1 > 1) { this.page1--; this.displayRecords1(this.page1); } }
    nextHandler1() { if (this.page1 < this.totalPages1) { this.page1++; this.displayRecords1(this.page1); } }
    lastHandler1() { this.page1 = this.totalPages1; this.displayRecords1(this.page1); }

    /* Footer next button in screen‑2 */
    handleNextBuild() {
        console.log('Selected rows for build:', JSON.stringify(this.selectedRows1));
    }

    //Screen Third
    handleNextBuild() {
        // require at least one selection
        if (this.selectedRows1.length === 0) { return; }
        this.personaButtonClicked = false;
        this.showPermissionPage = false;
        this.showSelectedPermissions = true;

    }
    handlePrevious3() {
        this.personaButtonClicked = false;
        this.showPermissionPage = true;
        this.showSelectedPermissions = false;

    }
    handleCancel(){
        this.personaButtonClicked = false;
        this.showPermissionPage = false;
        this.showSelectedPermissions = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}