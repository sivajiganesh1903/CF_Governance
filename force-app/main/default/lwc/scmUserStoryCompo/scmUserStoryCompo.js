import { LightningElement, track, api, wire } from 'lwc';
import getUserStoriesDetails from '@salesforce/apex/ScmUserStoryController.getUserStoriesDetails';
import getFirstCommit from '@salesforce/apex/ScmUserStoryController.getFirstCommit';
import matrixCompo from '@salesforce/apex/ScmUserStoryController.matrixCompo';
import triggerBackPromotion from '@salesforce/apex/BackPromoteUserStory.triggerBackPromotion';
import getScmStrategy from '@salesforce/apex/ScmUserStoryController.getScmStrategy';
import submitForApproval from '@salesforce/apex/ScmUserStoryController.submitForApproval';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import DEVELOPER_FIELD from '@salesforce/schema/copado__User_Story__c.copado__Developer__c';

export default class ScmUserStoryCompo extends NavigationMixin(LightningElement) {
    @api recordId;
    @track userStory;
    @track userStories = [];
    @track error;
    @track wrappersList = [];
    @track wrappers = []; // All records available in the data table
    @track firstCommit; // Variable to store the first commit record
    @track userStoryName;
    @track userStoryId;
    @track developerName;
    @track environmentName;
    @track releaseName;
    @track userStory;
    @track showSpinnerFlag = false;
    @track justification = ''; // Justification input
    @track isModalOpen = false
    @track itemCount = 0;
    selectedStoryId;
    @track selectedStrategy;
    @track actionSpinner = false;
    @wire(getRecord, { recordId: '$recordId', fields: [DEVELOPER_FIELD] })
    wiredUserStory({ data, error }) {
        if (data) {
            this.developerName = data.fields.copado__Developer__c.value;
        }
    }

    connectedCallback() {
        this.loadUserStoryDetails();
        this.loadScmStrategy(); // Load the SCM strategy
        this.loadMatrixCompo();
    }

    handleRefresh() {
        //eval("$A.get('e.force:refreshView').fire();");
        this.loadScmStrategy(); // Load the SCM strategy
        this.loadUserStoryDetails();
        this.loadMatrixCompo();
    }

    loadScmStrategy() {
        this.showSpinnerFlag = true
        getScmStrategy()
            .then(result => {
                this.selectedStrategy = result; // Store the fetched strategy
                this.showSpinnerFlag = false
                this.loadMatrixCompo(); // Load the matrix components based on the strategy
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                console.error('Error fetching SCM strategy:', error);
            });
    }

    loadUserStoryDetails() {
        this.showSpinnerFlag = true;
        getUserStoriesDetails({ recordId: this.recordId })
            .then(data => {
                if (data && data.length > 0) {
                    this.showSpinnerFlag = false;
                    const story = data[0];
                    this.userStoryId = story.Id;
                    this.userStoryName = story.Name;
                    this.developerName = story.copado__Developer__r ? story.copado__Developer__r.Name : '-';
                    console.log('Primary story developer:', this.developerName);
                    this.environmentName = story.copado__Environment__r ? story.copado__Environment__r.Name : '-';
                    this.releaseName = story.copado__Release__r ? story.copado__Release__r.Name : '-';
                    this.userStory = story;
                    this.error = undefined;

                    this.fetchFirstCommitRecord();
                } else {
                    this.error = 'No user story details found';
                    this.userStory = undefined;
                    this.showSpinnerFlag = false;
                }
            })
            .catch(error => {
                this.error = error;
                this.userStory = undefined;
                this.showSpinnerFlag = false;
            });
    }


    loadMatrixCompo() {
        this.showSpinnerFlag = true;
        matrixCompo({ recordId: this.recordId })
            .then(data => {
                this.processData(data);
                this.error = undefined;
                this.showSpinnerFlag = false;
            })
            .catch(error => {
                this.showSpinnerFlag = false;
                this.error = error;
                console.error(error);
            });
    }

    processData(data) {
        console.log('Data received in processData: ', data);
        this.wrappers = data.map((item, index) => {
            return {
                serialNumber: index + 1,  // Add serial number here
                component: item.component,
                typer: item.typer,
                usList: item.usList.map(usItem => {
                    let label = '';
                    let className = 'blue-link';
                    let href = '#';

                    if (this.selectedStrategy === 'Back Promote') {
                        if (usItem.backPromotionid === 'No Record Found') {
                            label = 'Backpromote';
                            className = 'blue-link';
                        } else if (usItem.backPromotionid === 'Commit in Progress' || usItem.backPromotionid === 'Back Promotion in Progress' || usItem.backPromotionid === 'Back Promotion Created') {
                            label = 'Back Promotion in progress';
                            className = 'yellow-link';
                            href = `/lightning/r/Back_Promoted_Result__c/${usItem.backPromotionStatus}/view`;
                        } else if (usItem.backPromotionid === 'Merge Conflict') {
                            label = 'Merge Conflict';
                            className = 'yellow1-link';
                            href = `/lightning/r/Back_Promoted_Result__c/${usItem.backPromotionStatus}/view`;
                        } else if (usItem.backPromotionid === 'Conflict Resolved') {
                            label = 'Conflict Resolved';
                            className = 'yellow1-link';
                            href = `/lightning/r/Back_Promoted_Result__c/${usItem.backPromotionStatus}/view`;
                        } else if (usItem.backPromotionid === 'Back Promotion Successfull' || usItem.backPromotionid === 'Commit Completed') {
                            label = 'Back Promotion Successfull';
                            className = 'green-link';
                            href = `/lightning/r/Back_Promoted_Result__c/${usItem.backPromotionStatus}/view`;
                        } else if (usItem.backPromotionid === 'Back Promotion Failed' || usItem.backPromotionid === 'Commit Failed') {
                            label = 'Back Promotion Failed';
                            className = 'red-link';
                        }
                    } else if (this.selectedStrategy === 'Approval Process') {
                        if (usItem.approvalStatus === 'No Record Found') {
                            label = 'Submit For Approval';
                            className = 'blue-link';
                        } else if (usItem.approvalStatus === 'Waiting for Approval') {
                            label = 'Waiting for Approval';
                            className = 'yellow-link';
                            href = `/lightning/r/SC_Matrix_Exception_Approval__c/${usItem.approvalId}/view`;
                        } else if (usItem.approvalStatus === 'Approved') {
                            label = 'Approved';
                            className = 'green-link';
                            href = `/lightning/r/SC_Matrix_Exception_Approval__c/${usItem.approvalId}/view`;
                        } else if (usItem.approvalStatus === 'Rejected') {
                            label = 'Approval Rejected';
                            className = 'red-link';
                        } else if (usItem.approvalStatus === 'Cancelled') {
                            label = 'Approval Cancelled';
                            className = 'red-link';
                        }
                        else if (usItem.approvalStatus === 'Expired') {
                            label = 'Approval Expired';
                            className = 'red-link';
                        }

                    }

                    return {
                        Id: usItem.userStory.Id,
                        name: usItem.userStory.Name,
                        Environment: usItem.userStory.copado__Environment__r?.Name ?? '-',
                        Developer: usItem.userStory.copado__Developer__r?.Name ?? '-',
                        Release: usItem.userStory.copado__Release__r?.Name ?? '-',
                        Owner: usItem.userStory.CreatedBy?.Name ?? '-',
                        lastCommitDate: usItem.lastCommitDate ?? '-',
                        backPromotionStatus: usItem.backPromotionStatus,
                        backPromotionid: usItem.backPromotionid,
                        approvalStatus: usItem.approvalStatus,
                        approvalId: usItem.approvalId,
                        label: label,
                        className: className,
                        href: href
                    };
                })
            };
        });
        console.log('this.wrappers ==' + JSON.stringify(this.wrappers));
        this.itemCount = this.wrappers.length;
        this.showSpinnerFlag = false;
    }

    navigateToUSRecord(event) {
        const userStoryId = event.target.dataset.contactId;
        const url = `/lightning/r/copado__User_Story__c/${userStoryId}/view`; // Update the URL path as needed
        window.open(url, '_blank');
    }
    hasDeveloper(value) {
        return value !== null && value !== undefined && value !== '';
    }

    validateDevelopersBeforeAction(selectedItem) {
        const missing = [];

        // clicked story developer
        if (!selectedItem?.Developer || selectedItem.Developer === '-') {
            missing.push(selectedItem?.name || selectedItem?.Id);
        }

        // primary story developer (recordId story)
        if (!this.developerName || this.developerName === '-') {
            missing.push(this.userStoryName || this.recordId);
        }

        if (missing.length) {
            this.showToast(
                'Error',
                `Developer is missing for: ${missing.join(', ')}. Please assign a developer and try again. If already assigned, refresh the page and retry.`,
                'error'
            );
            return false;
        }
        return true;
    }


    async handleBackpromote(event) {
        // Prevent default navigation if link is #
        if (event.currentTarget.href?.endsWith('#')) {
            event.preventDefault();
        }

        this.actionSpinner = true;

        const storyId = event.currentTarget.dataset.storyId;
        this.selectedStoryId = storyId;

        const selectedItem = this.wrappers
            .flatMap(wrapper => wrapper.usList)
            .find(us => us.Id === storyId);

        if (!selectedItem) {
            console.error('No user story found for the given ID.');
            this.actionSpinner = false;
            return;
        }
        if (!this.validateDevelopersBeforeAction(selectedItem)) {
            this.actionSpinner = false;
            return;
        }
        
        /* ---------------------------------------------------
           Optional success toast
        --------------------------------------------------- */
        // if (this.selectedStrategy === 'Back Promote') {
        //     this.showToast(
        //         'Success',
        //         'Back Promotion Process Initiated!',
        //         'success'
        //     );
        // }

        const label = selectedItem.label;
        const backPromotionId = selectedItem.backPromotionid;

        /* ---------------------------------------------------
           Non-actionable states
        --------------------------------------------------- */
        if (
            label === 'Back Promotion in progress' ||
            label === 'Back Promotion Successfull' ||
            label === 'Merge Conflict' ||
            label === 'Waiting for Approval' ||
            label === 'Approved'
        ) {
            this.actionSpinner = false;
            this.loadScmStrategy();
            this.loadUserStoryDetails();
            this.loadMatrixCompo();
            return;
        }

        /* ---------------------------------------------------
           Retry Back Promotion
        --------------------------------------------------- */
        if (label === 'Backpromote' || backPromotionId === 'Back Promotion Failed') {
            this.retryBackPromotion(storyId);
            return;
        }

        /* ---------------------------------------------------
           Commit states
        --------------------------------------------------- */
        if (
            backPromotionId === 'Commit in Progress' ||
            backPromotionId === 'Commit Completed'
        ) {
            this.actionSpinner = false;
            return;
        }

        /* ---------------------------------------------------
           Approval flow
        --------------------------------------------------- */
        if (
            label === 'Submit For Approval' ||
            label === 'Approval Rejected' ||
            label === 'Approval Cancelled' ||
            label === 'Approval Expired'
        ) {
            this.isModalOpen = true;
            this.actionSpinner = false;
            return;
        }

        // Safety fallback
        this.actionSpinner = false;
    }

    retryBackPromotion(storyId) {
        const commitId = this.firstCommit ? this.firstCommit.Id : null;
        const Environment = this.firstCommit ? this.firstCommit.copado__Snapshot_Commit__r.copado__Org__r.copado__Environment__c : null;
        console.log('Environment =' + Environment);
        triggerBackPromotion({ ustoryid: this.recordId, bpustoryid: storyId, destid: Environment })
            .then(result => {
                this.actionSpinner = false;
                if ((result.length === 15 || result.length === 18) && result) {
                    this.showToast('Success', 'Back Promotion Process Initiated!', 'success');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result,
                            objectApiName: 'Back_Promoted_Result__c',
                            actionName: 'view'
                        }
                    });
                } else if (result.toLowerCase().includes('Error - ')) {
                    this.showToast('Error', result, 'error');
                } else {
                    this.showToast('Unexpected response', result, 'error');
                }
                this.loadScmStrategy();
                this.loadUserStoryDetails();
                this.loadMatrixCompo();
            })
            .catch(error => {
                this.actionSpinner = false;
                const msg = error?.body?.message || error?.message || 'Back Promotion failed';
                this.showToast('Error', msg, 'error');
                console.error('Error in backpromote:', error);
            });
    }

    navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    fetchFirstCommitRecord() {
        getFirstCommit({ recordId: this.recordId })
            .then(result => {
                if (result) {
                    this.firstCommit = result;
                    console.log('First commit record:' + JSON.stringify(this.firstCommit));
                } else {
                    console.log('No commit records found.');
                }
            })
            .catch(error => {
                console.error('Error fetching first commit record:', error);
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    closeAction() {
        const closeModalEvent = new CustomEvent("modalclose");
        this.dispatchEvent(closeModalEvent);
    }

    closeModal() {
        this.isModalOpen = false;
        this.justification = '';
    }

    handleJustificationChange(event) {
        this.justification = event.target.value;
        console.log('this.justification =' + this.justification);
    }

    handleSendApproval() {
        this.actionSpinner = true;
        if (this.justification == null || this.justification.trim() === '') {
            this.actionSpinner = false;
            this.showToast('Error', 'Justification is Mandatory.', 'error');
        } else {
            // Call the Apex method to create the approval record
            submitForApproval({ requestedUserStoryId: this.recordId, linkedUserStoryId: this.selectedStoryId, justification: this.justification })
                .then(result => {
                    this.result = result;
                    console.log('this.result ==' + this.result);
                    this.showToast('Success', 'Approval request submitted successfully', 'success');
                    this.closeModal();

                    // Generate the URL for the new record page
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result,
                            objectApiName: 'SC_Matrix_Exception_Approval__c',
                            actionName: 'view'
                        }
                    }).then(url => {
                        // Open the URL in a new tab
                        window.open(url, '_blank');
                        this.actionSpinner = false;
                        this.loadScmStrategy(); // Load the SCM strategy
                        this.loadUserStoryDetails();
                        this.loadMatrixCompo();
                    });
                    this.justification = '';
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                    console.error('Error submitting approval request:', error);
                    this.actionSpinner = false;
                });
        }
    }
}