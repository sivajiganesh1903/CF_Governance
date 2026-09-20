import { LightningElement, api, wire, track } from 'lwc';
import getPermissionsForUam from '@salesforce/apex/FirecallFrameworkController.getPermissionsForUam';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class PermissionsOnUAMRecord extends LightningElement {
    requestedPermissionsHeading = 'Requested Permissions';
    @api recordId;

    @track columns = [];
    @track jsonData = [];  

    isLoading = true;
    error;
    hasNoPermissions = false;

    @wire(CurrentPageReference)
    setPageRef(pageRef) {
        if (!this.recordId && pageRef) {
            this.recordId = pageRef.attributes?.recordId || pageRef.state?.recordId;
        }
    }

    renderedCallback() {
        if (!this.isLoading || !this.recordId) {
            return; 
        }
        this.fetchPermissions();
    }

    async fetchPermissions() {
        try {
            const jsonString = await getPermissionsForUam({ recordId: this.recordId });
            console.log('recordId: '+ this.recordId);
            if (!jsonString || jsonString === '[]') {
                this.hasNoPermissions = true;
                return;
            }

            const parsed = JSON.parse(jsonString);

            if (!Array.isArray(parsed) || parsed.length === 0) {
                this.hasNoPermissions = true;
                return;
            }

            const desiredOrder = ['Name', 'Description', 'ComponentType'];
            this.columns = desiredOrder.map(key => ({
                label: key,
                fieldName: key,
                type: 'text'
            }));
            this.jsonData = parsed.map((row, idx) => ({ id: idx + 1, ...row }));
        } catch (e) {
            this.error = e?.body?.message || e.message;
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get hasRows() {
        return !this.isLoading && !this.error && this.jsonData.length > 0;
    }
    get showNoPermissions() {
        return !this.isLoading && !this.error && this.hasNoPermissions;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}