import { LightningElement, api, track, wire } from 'lwc';
import getOrgJsonAttachment from '@salesforce/apex/FirecallFrameworkController.getOrgJsonAttachment';
import { CurrentPageReference } from 'lightning/navigation';

export default class BuildPersonaComp extends LightningElement {

    @api recordId;
    @track permissionsHeading = 'Available Permissions';
    @track jsonData = [];
    @track filteredData = [];
    @track columns = [];
    selectedRowIds = [];
    selectedRowIdSet = new Set();
    showPermissionPage = true;
    @track recordsToDisplay = [];
    @track isLoading = false;
    @track error;

    @track page = 1;
    @track pageSize = 10;
    @track totalRecords = 0;
    @track totalPages = 1;
    @track pageSizeOptions = [10, 25, 50, 75, 100];

    @track isNextDisable = false;
    @track isPreviousDisable = true;

    /*@wire(CurrentPageReference)
    getPageReference(pageRef) {
        console.log('Org Id: ' + this.recordId);
        if (pageRef && pageRef.state && pageRef.state.c__recordId) {
            this.recordId = pageRef.state.c__recordId;
            this.loadJsonData();
        }
    }  */

    connectedCallback() {
        console.log('Org Id: ' + this.recordId);
        const urlParams = new URLSearchParams(window.location.search);
        const ids = urlParams.get('ids');
        if (ids) {
            this.recordIds = ids.split(',');
        }
    }

    async loadJsonData() {
        this.isLoading = true;
        this.error = null;
        this.jsonData = [];
        this.filteredData = [];
        // console.log('Org Id: '+ this.recordId)

        try {
            const jsonString = await getOrgJsonAttachment({ orgId: this.recordId });
            console.log('Org Id: ' + this.recordId)
            const parsed = JSON.parse(jsonString);

            if (Array.isArray(parsed) && parsed.length > 0) {
                /*    // Build columns excluding 'Id'
                    this.columns = Object.keys(parsed[0])
                        .filter(key => key !== 'Id') // exclude 'Id' from being displayed
                        .map(key => ({
                            label: key,
                            fieldName: key,
                            type: 'text'
                        }));  */

                const desiredOrder = ['Name', 'Description', 'ComponentType'];

                this.columns = desiredOrder.map(key => ({
                    label: this.formatLabel(key),
                    fieldName: key,
                    type: 'text'
                }));



                // Add internal ID for selection tracking
                this.jsonData = parsed.map((item, index) => ({
                    ...item,
                    recordId: item.Id, // preserve original Id for Apex
                    id: index + 1      // internal key for datatable
                }));

                this.filteredData = [...this.jsonData];
                this.totalRecords = this.filteredData.length;
                this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                this.displayRecords(this.page);
            } else {
                this.error = 'No data found or invalid JSON structure.';
            }
        } catch (e) {
            this.error = 'Error parsing or fetching JSON: ' + (e.message || e.body?.message);
        } finally {
            this.isLoading = false;
        }
    }

    // Class-level method to format column labels
    formatLabel(key) {
        return key
            .replace(/([A-Z])/g, ' $1')        // insert space before capitals
            .replace(/^./, str => str.toUpperCase()); // capitalize first letter
    }

    displayRecords(page) {
        const start = (page - 1) * this.pageSize;
        const end = Math.min(start + this.pageSize, this.totalRecords);
        this.recordsToDisplay = this.filteredData.slice(start, end);

        // Sync selection based on internal id
        this.selectedRowIds = this.recordsToDisplay
            .filter(row => this.selectedRowIdSet.has(row.id))
            .map(row => row.id);

        this.updatePaginationButtons();
    }


    handleRecordsPerPage(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.page = 1;
        this.displayRecords(this.page);
    }

    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();
        if (!searchTerm) {
            this.filteredData = [...this.jsonData];
        } else {
            this.filteredData = this.jsonData.filter(record =>
                Object.values(record).some(value =>
                    String(value).toLowerCase().includes(searchTerm)
                )
            );
        }
        this.totalRecords = this.filteredData.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.page = 1;
        this.displayRecords(this.page);
    }

    handleRowSelection(event) {
        const selected = event.detail.selectedRows;

        selected.forEach(row => this.selectedRowIdSet.add(row.id));

        const currentDisplayedIds = this.recordsToDisplay.map(r => r.id);
        currentDisplayedIds.forEach(id => {
            if (!selected.some(row => row.id === id)) {
                this.selectedRowIdSet.delete(id);
            }
        });

        this.selectedRowIds = Array.from(this.selectedRowIdSet);
    }

    firstHandler() {
        this.page = 1;
        this.displayRecords(this.page);
    }
    previousHandler() {
        if (this.page > 1) {
            this.page--;
            this.displayRecords(this.page);
        }
    }
    nextHandler() {
        if (this.page < this.totalPages) {
            this.page++;
            this.displayRecords(this.page);
        }
    }
    lastHandler() {
        this.page = this.totalPages;
        this.displayRecords(this.page);
    }

    updatePaginationButtons() {
        this.isPreviousDisable = this.page <= 1;
        this.isNextDisable = this.page >= this.totalPages;
    }

    handlePrevScreen2() {
        this.dispatchEvent(new CustomEvent('prevscreen'));
        this.showStartPage = true;
        this.showPermissionPage = false;
    }
    handleNext2() {
        this.showStartPage = false;
        this.showPermissionPage = false;
        this.selectedPermissionsScreen = true;
        this.selectedDataTableFlag = true;
        this.fetchSelectedPermissions();
    }

}