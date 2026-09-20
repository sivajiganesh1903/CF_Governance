import { LightningElement, api } from 'lwc';

export default class CreateContactForm extends LightningElement {
    @api recordId;

    handleSuccess(event) {
        this.redirectToRelatedList();
    }

    handleCancel() {
        this.redirectToRelatedList();
    }

    redirectToRelatedList() {
        if (!this.recordId) {
            console.error('recordId is missing. Cannot redirect.');
            return;
        }
        const url = `/lightning/r/Account/${this.recordId}/view`;
        setTimeout(() => {
            try {
                window.location.href = url;
            } catch (e) {
                console.error('Navigation error', e);
            }
        }, 0);
    }
}