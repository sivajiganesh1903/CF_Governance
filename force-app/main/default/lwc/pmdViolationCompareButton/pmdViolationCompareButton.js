import { LightningElement, api } from 'lwc';
import ViolationComparision from '@salesforce/apex/PMDComparisions.ViolationComparision';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PmdViolationCompareButton extends LightningElement {
    @api recordId;

    @api async invoke() {
        let params = {
            recordId: this.recordId
        };
        console.log('Params:', params); // Debugging purpose

        try {
            const result = await ViolationComparision({ recordId: this.recordId });
            console.log('Apex Result:', JSON.stringify(result)); // Log the result for debugging

            // Use .trim() to remove any leading/trailing whitespaces
            if (result && result.trim() === 'success') {
                this.showToast('Compared Successfully', 'Before and after deployment violations are successfully compared', 'success');
                window.location.reload();
            } else {
                this.showToast('Failed to Compare', 'Failed', 'error');
            }
        } catch (error) {
            console.error('Error calling Apex class:', error);
            this.showToast('Error', error.message, 'error'); // Show toast for unexpected errors
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
}