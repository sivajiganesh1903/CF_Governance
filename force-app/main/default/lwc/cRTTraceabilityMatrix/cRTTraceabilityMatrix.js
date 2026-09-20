import { LightningElement, wire, api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMatrixData from '@salesforce/apex/CRTMatrixController1.getMatrixData';
export default class CRTTraceabilityMatrix extends NavigationMixin(LightningElement) {
    @api matrixData;
    @wire(getMatrixData)
    wiredMatrixData({ data, error }) {
        if (data) {
         
            this.matrixData = data.map(row => ({
                ...row,
                jiraLink: this.getJiraLink(row.Rsl_testStatus, row.US_ID),
               // jiraLink: row.Rsl_testStatus === 'Failed' ? 'https://CRTTraceability.atlassian.net/jira/software/projects/IC/boards/6?selectedIssue=IC-4' : '',

              //  statusClass: this.getStatusClass(row.Rsl_testStatus),
                storyUrl: this.getUsStoryUrl(row.US_ID),
                storyPrUrl: this.getPrStoryUrl(row.US_prID),
                storyCMUrl: this.getCMStoryUrl(row.CM_ID),

            }));
            console.log(this.matrixData);
        } else if (error) {
            console.error(error);
        }
    }
    @track tdElements;

    renderedCallback() {
        // Query for all td elements within the table
        this.trElements = this.template.querySelectorAll(`table tr`);
        this.trElements.forEach((row) => {
            var indexTd = row.children[7];
            var indexUs_id = row.children[0];
            if (indexTd) {
                var statusVl = indexTd.textContent;
                var us_id = indexUs_id.textContent;
                console.log('us_id',us_id)
                var htmlEl = this.template.querySelector(`table td[data-name="${us_id}"]`);
                // Check if htmlEl is not null before accessing its classList
                if (htmlEl) {
                    // Add dynamic class based on statusVl
                    if (statusVl === 'Success') {
                        htmlEl.style.backgroundColor = "green";
                        htmlEl.style.color = "white";
                    } else if(statusVl === 'Failed'){
                        htmlEl.style.backgroundColor = "red";
                        htmlEl.style.color = "white";
                        // this.matrixData.forEach((rowData) => {
                        //     if (rowData.US_ID === us_id) {
                        //         rowData.jiraLink = "https://CRTTraceability.atlassian.net/jira/software/projects/IC/boards/6?selectedIssue=IC-4";
                        //     }
                        // });
                    }
                   else {
                    htmlEl.style.backgroundColor = "orange";
                    htmlEl.style.color = "white";
                   
                    }
                }
            }
        });
    }
    getJiraLink(testStatus, us_id) {
        if (testStatus === 'Failed') {
            // Assuming usId is a number, and you want to increment the last digit
            const lastDigit = us_id; // Get the last digit
            const newLastDigit = (lastDigit + 1); // Increment the last digit
            return `https://CRTTraceability.atlassian.net/jira/software/projects/IC/boards/6?selectedIssue=IC-${newLastDigit}`;
        } else {
            return ''; // Provide a default link or an empty string if not failed
        }
    }
    
    handleUserStoryClick(event) {
        event.preventDefault();
        const userStoryId = event.currentTarget.dataset.recordid;
        this.navigateToRecordPage('copado__User_Story__c', userStoryId);

    }
    handleProjectClick(event) {
        event.preventDefault();
        const projectId = event.currentTarget.dataset.recordid;
        this.navigateToRecordPage('copado__Project__c', projectId);
    }
    handleCMClick(event) {
        event.preventDefault();
        const CMId = event.currentTarget.dataset.recordid;
        this.navigateToRecordPage('copado__User_Story_Commit__c', CMId);
    }
    navigateToRecordPage(objectApiName, recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view',
            },
        });

    }
   
    // getStatusClass(testStatus) {
    //     return testStatus === 'Failed' ? 'status-success' : 'status-failed';
    //     //return this.matrixData.map(row => row.testStatus === 'Success' ? 'Success' : 'Failed');   
    // }
    getUsStoryUrl(storyId) {
        return `/lightning/r/copado__User_Story__c/${storyId}/view`;
    }
    getPrStoryUrl(storyId) {
        return `/lightning/r/copado__Project__c/${storyId}/view`;
    }
    getCMStoryUrl(storyId) {
        return `/lightning/r/copado__User_Story_Commit__c/${storyId}/view`;
    }
}