import { LightningElement, track, wire } from 'lwc';
import headerImage from '@salesforce/resourceUrl/FirecallcenterImage';
import CF_IMAGE from '@salesforce/resourceUrl/CfLogo';
import fetchSalesforceOrg from '@salesforce/apex/FirecallFrameworkController.fetchSalesforceOrg';
//import fetchAndAttachMetadata from '@salesforce/apex/GenerateUserAccessGroup.fetchAndAttachMetadata';
//import searchUsers from '@salesforce/apex/FirecallFrameworkController.searchUsers';
//import getSelectedPermissions from '@salesforce/apex/FirecallFrameworkController.getSelectedPermissions';
import getOrgJsonAttachment from '@salesforce/apex/FirecallFrameworkController.getOrgJsonAttachment';

export default class FirecallPage extends LightningElement {

    @track imageUrl = CF_IMAGE;
    showStartPage = true;
    headerImageUrl = headerImage;
    @track selectedSalesforceOrg = '';
    @track showPermissionPage = false;

    // Ensures all accordions are open by default
    activeSections = ['feature1', 'feature2', 'feature3', 'feature4', 'feature5'];
    // @track activeSections = []; // Keeps accordion collapsed initially

    connectedCallback() {
        //alert(this.imageUrl);
    }
    handleClick() {
        console.log('Inside HandleClick method');
        this.showStartPage = false;
        this.showPermissionPage = true;
        this.loadJsonData();
    }

    handleSectionToggle(event) {
        this.activeSections = event.detail.openSections;
    }
    handleChangeSalesforceOrg(event) {
        this.selectedSalesforceOrg = event.target.value;
        console.log('Selected Salesforce Org:', this.selectedSalesforceOrg);
    }

    @track salesforceOrgOptions = [];

    @wire(fetchSalesforceOrg)
    salesforceOrg({ error, data }) {
        if (data) {
            console.log('data --- ' + JSON.stringify(data));
            this.salesforceOrgOptions = data.map(item => {
                return { label: item.Name, value: item.Id };
            });
        }
        if (error) {
            console.log('error -- ' + JSON.stringify(error));
        }
    }

    @track users; // List of users fetched based on search
    @track searchEmail = ''; // Search input value
    @track selectedUser; // Stores selected user information
    @track selectedUserId; // Stores the ID of the selected user
    @track showDropdown = false; // Toggle user list visibility

    // Handle search input
    handleSearchUsers(event) {
        this.searchEmail = event.target.value;

        // If search term is cleared, reset selected user
        if (!this.searchEmail) {
            this.selectedUser = undefined;
            this.selectedUserId = undefined; // Clear the selected user ID
        }

        // If search term is at least 2 characters, initiate search
        if (this.searchEmail.length >= 2) {
         /*   searchUsers({ searchEmail: this.searchEmail })
                .then(result => {
                    this.users = result;
                    this.showDropdown = true; // Show dropdown with results
                })
                .catch(error => {
                    this.users = undefined;
                    this.showDropdown = false; // Hide dropdown in case of error
                });  */
        } else {
            this.users = undefined;
            this.showDropdown = false; // Hide dropdown if the search term is too short
        }
    }
    // Handle selection of a user
    handleSelectUser(event) {
        const userId = event.currentTarget.dataset.id;
        this.selectedUser = this.users.find(user => user.Id === userId);
        this.selectedUserId = userId; // Store the selected user's ID

        // Set the selected user's name in the input field
        this.searchEmail = this.selectedUser.Name;
        this.showDropdown = false; // Hide dropdown after selection
    }
    //second screen
    @track permissionsHeading = 'Available Permissions';
    @track jsonData = [];
    @track filteredData = [];
    @track columns = [];
    selectedRowIds = [];
    selectedRowIdSet = new Set();

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

    async loadJsonData() {
        this.isLoading = true;
        this.error = null;
        this.jsonData = [];
        this.filteredData = [];

        try {
            const jsonString = await getOrgJsonAttachment({ orgId: this.selectedSalesforceOrg });
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

    //Third Screen
    @track selctedPermissionsHeading = 'Selected Permissions'
    @track showSpinnerFlag = false;
    //@track selectedDataTableFlag = false;
    @track selectedRowsPermissionsToDisplay = [];
    //@track columns = [];
    @track error;
    @track totalselectedRecords = 0;

    fetchSelectedPermissions() {
        console.log('Selected Records:', this.selectedRecordsId);

        if (!this.selectedRecordsId || this.selectedRecordsId.length === 0) {
            this.selectedRowsPermissionsToDisplay = [];
            //  this.selectedDataTableFlag = false;
            this.totalselectedRecords = 0;
            return;
        }

        this.showSpinnerFlag = true;
        // Get selected recordIds (original Ids from JSON)
        const selectedRecords = this.filteredData.filter(row =>
            this.selectedRowIdSet.has(row.id)
        );

        const selectedRecordIds = selectedRecords.map(row => row.recordId);

      /*  getSelectedPermissions({ orgId: this.selectedSalesforceOrg, selectedPsIds: this.selectedRowIds })
            .then((result) => {
                console.log('Selected Stories Response:', JSON.stringify(result));

                this.selectedRowsPermissionsToDisplay = result || [];
                this.totalselectedRecords = this.selectedRowsPermissionsToDisplay.length;

                this.selectedDataTableFlag = this.selectedRowsPermissionsToDisplay.length > 0;
                this.columns = columns; // Make sure `columns` is declared elsewhere or imported
                this.showSpinnerFlag = false;
                this.error = undefined;
            })
            .catch((error) => {
                console.error('Error fetching records:', error);
                this.error = error;
                this.selectedRowsPermissionsToDisplay = [];
                this.selectedDataTableFlag = false;
                this.totalselectedRecords = 0;
                this.showSpinnerFlag = false;
            });  */
    }

    handlePrevScreen3() {
        this.dispatchEvent(new CustomEvent('prevscreen'));
        this.showStartPage = false;
        this.showPermissionPage = true;
    }
    handleNext3() {
        this.showStartPage = false;
        this.showPermissionPage = false;
        this.selectedPermissionsScreen = false;
    }

    goHomeHandler() {
        this.showStartPage = true;
        this.showPermissionPage = false;
        this.selectedPermissionsScreen = false;

        if (this.showStartPage === true) {
            eval("$A.get('e.force:refreshView').fire()");
        }

        this.allRecordsList = [];
        this.selectedRowsPermissionsToDisplay = [];
        this.showDataTable = false;
        this.selectedDataTableFlag = false;
    }

}