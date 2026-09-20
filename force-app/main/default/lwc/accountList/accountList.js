import { LightningElement, wire } from 'lwc';
import getAccounts from '@salesforce/apex/AccountService.getAccounts';
export default class AccountList extends LightningElement {
searchKey = '';

    @wire(getAccounts, { searchKey: '$searchKey' })
    accounts;

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
    }

    viewAccount(event) {
        event.preventDefault();
        const accountId = event.target.href.split('/').pop();
        this.navigateToRecord(accountId);
    }

    navigateToRecord(recordId) {
        // Navigate to the account record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }
}