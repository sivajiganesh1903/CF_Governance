import { LightningElement,api } from 'lwc';
import createReleasePlaybookItems from '@salesforce/apex/ReleasePlaybookController.createReleasePlaybookItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateReleaseItems extends LightningElement {

    @api recordId;
    result;

    @api async invoke() {
        let params ={
            "releasePlaybookId" : this.recordId
        };
        console.log(params);
        console.log('record Id'+this.recordId);
        await createReleasePlaybookItems(params)
        .then(() => {
            console.log('Inside then block');
            this.dispatchEvent(
                new ShowToastEvent({             
                    title: 'Success',
                    message: 'Release Items created successfully!',
                    variant: 'success',
                }),
            );
            // Refresh the current page
            this.refreshView();
            // Close the action screen
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed',
                    message: 'You have already created Release Items records!',   
                 //   message: error.body.message,
                    variant: 'error',
                }),
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }  
    refreshView() {
        eval("$A.get('e.force:refreshView').fire();");
    }  

}