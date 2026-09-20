import { LightningElement,api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import handletask from '@salesforce/apex/TaskTriggerHandler.handletask';
export default class TaskHandler extends LightningElement {
    
    @api recordId;
    result 

    @api async invoke() {
        let params ={
            "UpdtTaskMap" : this.recordId
        };
        await handletask(params)
        .then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Succcess',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Failed',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        });
    }

}