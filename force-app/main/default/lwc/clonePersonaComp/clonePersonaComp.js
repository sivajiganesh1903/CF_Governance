import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getPersonaDetails from '@salesforce/apex/FirecallFrameworkController.getPersonaDetails';
import clonePersonaRecord from '@salesforce/apex/FirecallFrameworkController.clonePersonaRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ClonePersonaComp extends NavigationMixin(LightningElement) {

    recordId;
    @wire(CurrentPageReference)
    wiredRef(p) { this.recordId = p?.state?.recordId; }
    @track persona = {};
    @track isLoaded = false;
    @track isSaving = false;

    connectedCallback() {
        if (!this.recordId) {
            this.showToast('Error', 'recordId not received. Ensure this is a record Quick Action.', 'error');
            return;
        }

        console.log('RecordId received:', this.recordId);

        getPersonaDetails({ recordId: this.recordId })
            .then(result => {
                this.persona = { ...result };
                delete this.persona.Id;
                this.isLoaded = true;
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error loading persona', error.body?.message || error.message, 'error');
            });
    }


    handleChange(event) {
        this.persona[event.target.name] = event.target.type === 'checkbox'
            ? event.target.checked
            : event.target.value;
    }

    handleSave() {
        this.isSaving = true;
        clonePersonaRecord({ personaData: this.persona })
            .then(newId => {
                this.showToast('Success', 'Persona cloned successfully', 'success');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: newId,
                        objectApiName: 'cf_Persona__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', error.body?.message || error.message, 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}