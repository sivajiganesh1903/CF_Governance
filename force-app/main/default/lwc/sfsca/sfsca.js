import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import storyscanbutton from '@salesforce/apex/userstorysfsca.storyscanbutton';

// Field reference for copado__Metadata_Types_in_Selection__c
const FIELDS = ['copado__User_Story__c.copado__Metadata_Types_in_Selection__c'];

export default class CreateCIJobComp extends LightningElement {
    @api recordId; // Record ID of the User Story
    metadataTypes;

    // Wire service to fetch the copado__Metadata_Types_in_Selection__c field
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.metadataTypes = data.fields.copado__Metadata_Types_in_Selection__c.value;
        } else if (error) {
            this.metadataTypes = null;
            this.showErrorToast('Error', 'Unable to fetch record data');
        }
    }

    // Async method invoked by the button
    @api async invoke() {
        // Validate if the metadata types include the required components
        const requiredComponents = ['ApexClass', 'ApexTrigger', 'LightningComponentBundle', 'ApexPage', 'Flow'];
        if (this.metadataTypes && this.hasEligibleComponents(requiredComponents)) {
            let params = { usid: this.recordId };
            await storyscanbutton(params)
                .then(() => {
                    this.showSuccessToast('Success', 'CI Job created successfully');
                    window.location.reload(); // Refresh the page on success
                })
                .catch((error) => {
                    this.showErrorToast('Failed', error.body.message);
                });
        } else {
            this.showErrorToast('No Eligible Components', 'The record does not contain any eligible components.');
        }
    }

    // Helper method to check if metadata types include any required component
    hasEligibleComponents(requiredComponents) {
        // Split the semicolon-separated values into an array
        const metadataArray = this.metadataTypes.split(';');
        return requiredComponents.some((component) => metadataArray.includes(component));
    }

    // Helper method to show a success toast
    showSuccessToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'success',
            })
        );
    }

    // Helper method to show an error toast
    showErrorToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'error',
            })
        );
    }
}