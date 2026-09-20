import { LightningElement, api } from 'lwc';
import fetchAndAttachMetadata from '@salesforce/apex/GenerateUserAccessGroup.fetchAndAttachMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CompareViolationsOnRP extends LightningElement {
    @api recordId;

    @api async invoke() {
    try {
        const result = await fetchAndAttachMetadata({ orgId: this.recordId });
        console.log('Raw Apex result:', result); // JSON string
        console.log('recordId: '+ this.recordId);

        const parsedResult = JSON.parse(result); // Convert to object
        console.log('Parsed Result:', parsedResult);

        this.showToast(parsedResult.status, parsedResult.message, this.getToastVariant(parsedResult.status));

    } catch (error) {
        console.error('Error calling Apex:', error);
        this.showToast('Error', 'An error occurred while fetching the metadata.', 'error');
    }
}


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            }),
        );
    }

    getToastVariant(status) {
        switch (status) {
            case 'success':
                return 'success';
            case 'error':
            case 'no_items':
            case 'empty_results':
                return 'error';
            default:
                return 'info';
        }
    }
}