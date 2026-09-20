import { LightningElement, api } from 'lwc';
import ComparisionResults from '@salesforce/apex/RP_SCAComparision.comparisionResults';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CompareViolationsOnRP extends LightningElement {
    @api recordId;

    @api async invoke() {
        try {
            const result = await ComparisionResults({ recordId: this.recordId });
            console.log('Apex Result:', result);

            const parsedResult = JSON.parse(result); // Parse the JSON response
            console.log('Parsed Result:', parsedResult);

            this.showToast(parsedResult.status, parsedResult.message, this.getToastVariant(parsedResult.status));
        } catch (error) {
            console.error('Error calling Apex class:', error);
            this.showToast('Error', 'An error occurred while comparing violations. Please try again.', 'error');
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