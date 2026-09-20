import { LightningElement, api } from 'lwc';
import validation from '@salesforce/apex/jiraconnectoruserstory.validation';

export default class ChangeStoryBanner extends LightningElement {
    @api recordId; // The current User Story record ID
    showBanner = false;
    message = '';
    bannerStyle = '';
    iconName = '';

    connectedCallback() {
        this.validateUserStory();
    }

    validateUserStory() {
        validation({ updatedRecords: [{ Id: this.recordId }] })
            .then((result) => {
                if (result && result.length > 0) {
                    this.showBanner = true;
                    this.message = result[0]; // Display the first result
                    this.bannerStyle = 'background-color: #28a745; color: white;'; // Green banner for success
                    this.iconName = 'utility:success';
                }
            })
            .catch((error) => {
                this.showBanner = true;
                this.message = error.body.message; // Show error message
                this.bannerStyle = 'background-color: #dc3545; color: white;'; // Red banner for error
                this.iconName = 'utility:error';
            });
    }
}