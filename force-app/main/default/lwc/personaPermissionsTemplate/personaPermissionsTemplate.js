import { LightningElement, api, wire, track } from 'lwc';
import getPersonaPermissions from '@salesforce/apex/FirecallFrameworkController.getPersonaPermissions';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PersonaPermissionsTemplate extends LightningElement {

    @api recordId;                    
    @track columns = [];                   
    @track jsonData;                   
    @track error;                          
    @track isLoading = true;             
    @track hasNoPermissions = false;      

    existingPermissionsHeading = 'Permissions of the persona';

    @wire(CurrentPageReference)
    parsePageRef(pageRef) {
        if (!this.recordId && pageRef) {
            this.recordId =
                pageRef.state?.recordId || pageRef.attributes?.recordId;
        }
    }

    @wire(getPersonaPermissions, { personaId: '$recordId' })
    wiredPermissions({ error, data }) {
        if (data) {
            this.handleData(data);
        } else if (error) {
            this.handleError(error);
        }
    }

    handleData(jsonString) {
        try {
            if (!jsonString || jsonString === '[]') {
                this.hasNoPermissions = true;
                return;
            }

            const parsed = JSON.parse(jsonString);

            if (!Array.isArray(parsed) || parsed.length === 0) {
                this.hasNoPermissions = true;
                return;
            }

            if (!this.columns.length) {
                const desiredOrder = ['Name', 'Description', 'ComponentType'];
                this.columns = desiredOrder.map(key => ({
                    label: key,
                    fieldName: key,
                    type: 'text'
                }));
            }

            this.jsonData = parsed.map((row, i) => ({ id: i + 1, ...row }));
            this.error = undefined;
        } catch (e) {
            this.handleError(e);
        } finally {
            this.isLoading = false;
        }
    }

    handleError(e) {
        const msg =
            typeof e === 'string'
                ? e
                : e?.body?.message || e.message || 'Unknown error';

        this.jsonData = undefined;
        this.error = msg;
        this.isLoading = false;
        this.showToast('Error', msg, 'error');
    }

    get hasRecords() {
        return !this.isLoading && !this.error && this.jsonData && this.jsonData.length > 0;
    }
    get showNoPermissions() {
        return !this.isLoading && !this.error && this.hasNoPermissions;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}