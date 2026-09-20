import { LightningElement, track } from 'lwc';

import getMainReleases from '@salesforce/apex/ChangeManifestController.getMainReleases';
import getMetadataComponentsByMainRelease from '@salesforce/apex/ChangeManifestController.getMetadataComponentsByMainRelease';

export default class ChangeManifest extends LightningElement {

    @track mainReleaseOptions = [];
    @track tableData = [];
    @track filteredTableData = [];

    selectedMainRelease = null;
    selectedMainReleaseName = '';
    searchTerm = '';

    isLoading = false;
    hasSearched = false;
    dataLoaded = false; // NEW: Track if data has been loaded

    columns = [
        { 
            label: 'MetaData Type', 
            fieldName: 'MetadataType',
            type: 'text',
            wrapText: true,
            sortable: true
        },
        { 
            label: 'Component', 
            fieldName: 'Component',
            type: 'text',
            wrapText: true,
            sortable: true
        },
        { 
            label: 'Action', 
            fieldName: 'Action',
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'ActionClass' }
            },
            sortable: true
        }
    ];

    connectedCallback() {
        this.loadMainReleases();
    }

    loadMainReleases() {
        this.isLoading = true;

        getMainReleases()
            .then(result => {
                this.mainReleaseOptions = result.map(item => ({
                    label: item.Name,
                    value: item.Id
                }));
            })
            .catch(error => {
                console.error('Error loading main releases:', error);
                this.showToast('Error', 'Failed to load Main Releases', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleMainReleaseChange(event) {
        this.selectedMainRelease = event.detail.value;
        
        // Get the selected main release name
        const selectedOption = this.mainReleaseOptions.find(
            option => option.value === this.selectedMainRelease
        );
        this.selectedMainReleaseName = selectedOption ? selectedOption.label : '';

        // CHANGED: Load data but don't display it yet
        this.loadMetadataComponents();
    }

    loadMetadataComponents() {
        if (!this.selectedMainRelease) {
            this.tableData = [];
            this.filteredTableData = [];
            this.hasSearched = false;
            this.dataLoaded = false;
            return;
        }

        this.isLoading = true;

        getMetadataComponentsByMainRelease({ mainReleaseId: this.selectedMainRelease })
            .then(result => {
                
                let tempData = [];

                result.forEach(userStory => {
                    
                    // Get metadata components
                    let metadataRecords = userStory.copado__User_Story_Metadata__r || [];

                    metadataRecords.forEach(metadata => {
                        
                        // Calculate Action based on dates
                        let action = this.calculateAction(
                            metadata.CreatedDate, 
                            metadata.LastModifiedDate
                        );

                        tempData.push({
                            Id: metadata.Id,
                            MetadataType: metadata.copado__Type__c || '',
                            Component: metadata.copado__Metadata_API_Name__c || '',
                            Action: action,
                            ActionClass: action === 'Created' ? 'action-created' : 'action-modified',
                            // Store for filtering
                            ReleaseName: userStory.copado__Release__r?.Name || '',
                            UserStoryName: userStory.Name || ''
                        });
                    });
                });

                this.tableData = tempData;
                this.dataLoaded = true;
                
                // CHANGED: Only apply filters if search term exists
                if (this.searchTerm) {
                    this.hasSearched = true;
                    this.applyFilters();
                } else {
                    // Don't show data until user searches
                    this.filteredTableData = [];
                    this.hasSearched = false;
                }
            })
            .catch(error => {
                console.error('Error loading metadata components:', error);
                this.showToast('Error', 'Failed to load metadata components', 'error');
                this.tableData = [];
                this.filteredTableData = [];
                this.dataLoaded = false;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    calculateAction(createdDate, lastModifiedDate) {
        if (!createdDate || !lastModifiedDate) {
            return 'Unknown';
        }

        // Convert to Date objects for comparison
        const created = new Date(createdDate);
        const modified = new Date(lastModifiedDate);

        // Compare timestamps (within 1 second tolerance for system processing)
        const timeDifference = Math.abs(modified.getTime() - created.getTime());
        
        if (timeDifference < 1000) {
            return 'Created';
        } else {
            return 'Modified';
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
        
        // CHANGED: Only show results when user types something
        if (this.searchTerm && this.dataLoaded) {
            this.hasSearched = true;
            this.applyFilters();
        } else {
            // Clear results when search is empty
            this.filteredTableData = [];
            this.hasSearched = this.dataLoaded; // Show empty state only if data was loaded
        }
    }

    applyFilters() {
        let filtered = [...this.tableData];

        // Apply search filter
        if (this.searchTerm) {
            const searchLower = this.searchTerm.toLowerCase();
            filtered = filtered.filter(row => {
                return (
                    (row.ReleaseName && row.ReleaseName.toLowerCase().includes(searchLower)) ||
                    (row.UserStoryName && row.UserStoryName.toLowerCase().includes(searchLower))
                );
            });
        }

        this.filteredTableData = filtered;
    }

    handleResetFilters() {
        this.selectedMainRelease = null;
        this.selectedMainReleaseName = '';
        this.searchTerm = '';
        this.tableData = [];
        this.filteredTableData = [];
        this.hasSearched = false;
        this.dataLoaded = false;
    }

    clearMainReleaseFilter() {
        this.selectedMainRelease = null;
        this.selectedMainReleaseName = '';
        this.tableData = [];
        this.filteredTableData = [];
        this.hasSearched = false;
        this.dataLoaded = false;
    }

    clearSearchFilter() {
        this.searchTerm = '';
        // CHANGED: Clear the table when search is cleared
        this.filteredTableData = [];
        this.hasSearched = this.dataLoaded;
    }

    // Computed properties
    get hasData() {
        return this.filteredTableData.length > 0;
    }

    get hasActiveFilters() {
        return this.selectedMainRelease || this.searchTerm;
    }

    get recordCount() {
        return this.filteredTableData.length;
    }

    showToast(title, message, variant) {
        // Toast notification helper
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}