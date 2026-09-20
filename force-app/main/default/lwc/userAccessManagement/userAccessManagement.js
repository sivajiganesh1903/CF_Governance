import { LightningElement, track, api, wire } from 'lwc';
import EDJ_IMAGE from '@salesforce/resourceUrl/EdjLogo';
import SF_IMAGE from '@salesforce/resourceUrl/SfLogo';
import UPDATE_USER from '@salesforce/resourceUrl/updateUser';
import NEW_USER from '@salesforce/resourceUrl/newUser';
import createUserAccessRecord from '@salesforce/apex/UserAccessManagementController.createUserAccessRecord';
import getProductTeamPicklistValues from '@salesforce/apex/UserAccessManagementController.getProductTeamPicklistValues';
import getDivisionPicklistValues from '@salesforce/apex/UserAccessManagementController.getDivisionPicklistValues';
import getTimeZonePicklistValues from '@salesforce/apex/UserAccessManagementController.getTimeZonePicklistValues';
import getEnvPicklistValues from '@salesforce/apex/UserAccessManagementController.getEnvPicklistValues';
import searchUsers from '@salesforce/apex/UserAccessManagementController.searchUsers';
import getPersonaPicklistValues from '@salesforce/apex/UserAccessManagementController.getPersonaPicklistValues';
import { loadStyle } from 'lightning/platformResourceLoader';
import styles from '@salesforce/resourceUrl/RemoveDateFormatStyle';

export default class UserAccessManagement extends LightningElement {
    @track startDayOption = [];
    @track startDayValue = '';
    @track productTeamValue = 'FSC';
    @track productTeamOptions = [];
    @track divisionValue = '';
    @track divisionOptions = [];
    @track timeZoneValue = '';
    @track timeZoneOptions = [];
    @track environmentsValue;
    @track environmentsOptions = [];
    @track errorMessage = '';
    isErrorMessage = false;
    @track isEndOfDayDisabled = true;
    @track result;
    userType = ''; // To hold the User Type value
    

    @track users; // List of users fetched based on search
    @track searchTerm = ''; // Search input value
    @track selectedUser; // Stores selected user information
    @track selectedUserId; // Stores the ID of the selected user
    @track showDropdown = false; // Toggle user list visibility

    userAccess;
    edjLogoUrl;
    sfLogoUrl;
    newUser;
    updateUser;
    showAccessForm = true;
    showUsersImg = true;
    @track showNewUserForm = false;
    @track showExistingUserForm = false;
   // isSubmitButtonDisabled = false;
    isError = false;
    isCanceled = false;
    @track accessPeriodStart;
    @track accessPeriodEnd;


    renderedCallback(){
        Promise.all([
            loadStyle(this, styles) //specified filename
        ]).then(() => {
            window.console.log('Files loaded.');
        }).catch(error => {
            window.console.log("Error " + error.body.message);
        });
    }

    // Handle search input
    handleSearch(event) {
        this.searchTerm = event.target.value;
        
        // If search term is cleared, reset selected user
        if (!this.searchTerm) {
            this.selectedUser = undefined;
            this.selectedUserId = undefined; // Clear the selected user ID
        }

        // If search term is at least 2 characters, initiate search
        if (this.searchTerm.length >= 2) {
            searchUsers({ searchTerm: this.searchTerm })
                .then(result => {
                    this.users = result;
                    this.showDropdown = true; // Show dropdown with results
                })
                .catch(error => {
                    this.users = undefined;
                    this.showDropdown = false; // Hide dropdown in case of error
                });
        } else {
            this.users = undefined;
            this.showDropdown = false; // Hide dropdown if the search term is too short
        }
    }

    // Handle selection of a user
    handleSelect(event) {
        const userId = event.currentTarget.dataset.id;
        this.selectedUser = this.users.find(user => user.Id === userId);
        this.selectedUserId = userId; // Store the selected user's ID

        // Set the selected user's name in the input field
        this.searchTerm = this.selectedUser.Name;
        this.showDropdown = false; // Hide dropdown after selection
    }
    handleNewUserClick(){
        console.log("Inside New User Click handler");
        this.showUsersImg = false;
        this.showAccessForm = true;
        this.showNewUserForm = true;
        this.showExistingUserForm = false;
        this.userType = 'New User Request';
    }

    handleExUserClick(){
        console.log("Inside Existing User Click handler");
        this.showAccessForm = true;
        this.showUsersImg = false;
        this.showNewUserForm = false;
        this.showExistingUserForm = true;
        this.userType = 'Existing User Request';
    }

    userObj = { 'sobjectType': 'User_Access_Managment__c' };

    @api
    LWCFunction() {
        console.log('Entering LWCFunction in LWC.');
    }

    connectedCallback() {
        // Load the company logo from a static resource.
        this.edjLogoUrl = EDJ_IMAGE;
        this.sfLogoUrl = SF_IMAGE;
        this.updateUser = UPDATE_USER;
        this.newUser = NEW_USER;
    }

    goHomeHandler(){
        this.showAccessForm = true;
        this.showUsersImg = true;
        this.showNewUserForm = false;
        this.showExistingUserForm = false;
        if(this.showUsersImg == true){
            window.location.reload();
            eval("$A.get('e.force:refreshView').fire();");
        }
        
    }

    // Product Team
    @wire(getProductTeamPicklistValues)
    wiredProductTeamPicklistValues({ error, data }) {
        if (data) {
            this.productTeamOptions = data.map(value => {
                return { label: value, value: value };
            });
        } else if (error) {
            console.error('Error retrieving picklist values:', error);
        }
    }
   // productTeamValue = 'FSC';
    productTeamHandleChange(event) {
        this.productTeamValue = event.detail.value;
    }

    // Division
    @wire(getDivisionPicklistValues)
    wiredDivisionPicklistValues({ error, data }) {
        if (data) {
            this.divisionOptions = data.map(value => {
                return { label: value, value: value };
            });
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    divisionHandleChange(event) {
        this.divisionValue = event.detail.value;
    }

    // Time Zone
    @wire(getTimeZonePicklistValues)
    wiredTimeZonePicklistValues({ error, data }) {
        if (data) {
            this.timeZoneOptions = data.map(value => {
                return { label: value, value: value };
            });
        } else if (error) {
            console.error('Error fetching time zone picklist values:', error);
        }
    }

    timeZoneHandleChange(event) {
        this.timeZoneValue = event.detail.value;
    }
/*
    // Start of Day
    @wire(getStartOfDayPicklistValues)
    wiredStartOfDayPicklistValues({ error, data }) {
        if (data) {
            this.startDayOption = data.map(value => ({ label: value, value: value }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    startDayHandleChange(event) {
        this.startDayValue = event.detail.value;
        this.isEndOfDayDisabled = !this.startDayValue;
    }
    //End Of Day
    endDayHandleChange(event) {
        this.endDayValue = event.detail.value;
        this.validateEndOfDay();
    }
    validateEndOfDay() {
        this.isErrorMessage = true;
        // Parse the time values as integers for comparison
        let startOfDay = parseInt(this.startDayValue, 10);
        let endOfDay = parseInt(this.endDayValue, 10);
    
        // Perform the validation
        if (endOfDay <= startOfDay) {
            this.errorMessage1 = 'End of Day must be greater than Start of Day.';
        //    this.isSubmitButtonDisabled = true;
        } else {
            this.errorMessage1 = '';
        //    this.isSubmitButtonDisabled = false;
        }
    }  */

    // Environment
    @wire(getEnvPicklistValues)
    wiredEnvPicklistValues({ error, data }) {
        if (data) {
            this.environmentsOptions = data.map(value => ({ label: value, value: value }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    envHandleChange(event) {
        this.environmentsValue = event.detail.value;
        console.log('Selected Env==> '+this.environmentsValue);
    }

    //For Access Details
    accessDetails
    aceessDetailshandleChange(event) {
        this.accessDetails = event.detail.value;
        console.log('this.accessDetails'+this.accessDetails);
    }

    // Persona
    @wire(getPersonaPicklistValues)
    wiredPersonaPicklistValues({ error, data }) {
        if (data) {
            this.personaOptions = data.map(value => ({ label: value, value: value }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    personaHandleChange(event) {
        this.personaValue = event.detail.value;
        console.log('Selected Persona==> '+this.personaValue);
    }
    
    //Access Period Start   
    handleDateChange(event) {
        this.accessPeriodStart = event.target.value;  // Ensure correct date format
        console.log('Access Period Start: ' + this.accessPeriodStart);
    }

    //Access Period End
    handleDateEndChange(event) {
        this.accessPeriodEnd = event.target.value;  // Ensure correct date format
        console.log('Access Period End: ' + this.accessPeriodEnd);
    }

    //Addition of Permissions
    addPerValue
    addPerhandleChange(event){
        this.addPerValue = event.detail.value;
        console.log('this.addPerValue'+this.addPerValue);
    }

    //Removal of Permissions
    removePerValue
    removePerhandleChange(event){
        this.removePerValue = event.detail.value;
        console.log('this.removePerValue'+this.removePerValue);
    }
    

    // New User details 
	submitHandler() { 
        console.log('Inside submit handler');
        console.log('User Type:', this.userType);
        
        // Retrieve the input values
        let firstName = this.template.querySelector('lightning-input[data-formfield="firstname"]').value;
        let lastName = this.template.querySelector('lightning-input[data-formfield="lastname"]').value;
        let email = this.template.querySelector('lightning-input[data-formfield="email"]').value;
        let federationId = this.template.querySelector('lightning-input[data-formfield="federationId"]').value;
        let productTeamValue = this.productTeamValue;
        let divisionValue = this.divisionValue;
        let timeZoneValue = this.timeZoneValue;
       // let startDayValue = this.startDayValue;
       // let endDayValue = this.endDayValue;
        let accessDetails = this.accessDetails;
        let environmentsValue = this.environmentsValue;
        let personaValue = this.personaValue;
        let accessStart = this.accessPeriodStart;
        let accessEnd = this.accessPeriodEnd;
        let userType = this.userType;
        let selectedUserId = this.selectedUserId;
        let business = this.template.querySelector('lightning-input[data-formfield="business"]').value;
    
        // Check if any of the required fields are empty
        if (!firstName || !lastName || !email || !federationId || 
            !productTeamValue || !divisionValue || !timeZoneValue || 
          //  !startDayValue || !endDayValue  || 
            !environmentsValue || !business){
            window.scrollTo({ top: 0, behavior: 'smooth' });
            this.errorMessage = 'Please fill all the columns';
            this.scrollToError();
            return;
        }
    
        this.userObj.First_Name__c = firstName;
        console.log('this.userObj.First_Name__c'+this.userObj.First_Name__c)//firstName  
    
        this.userObj.Last_Name__c = lastName;
        console.log('this.userObj.Last_Name__c'+this.userObj.Last_Name__c)// LastName 
    
        this.userObj.Email__c = email; 
        console.log('this.userObj.Email__c'+this.userObj.Email__c)// Email 
    
        this.userObj.Federation_ID__c = federationId; 
        console.log('this.userObj.Federation_ID__c'+this.userObj.Federation_ID__c) //Federation ID 
    
        this.userObj.Product_Team__c = productTeamValue; 
        console.log('this.userObj.Product_Team__c=='+this.userObj.Product_Team__c); //Product Team 
        
        this.userObj.Divsion__c = divisionValue; 
        console.log('this.userObj.Divsion__c =='+this.userObj.Divsion__c); //Division 
        
        this.userObj.Time_Zone__c = timeZoneValue; 
        console.log('this.userObj.Time_Zone__c=='+this.userObj.Time_Zone__c); //Time Zone 
            
    /*    this.userObj.Start_Of_Day__c = startDayValue; 
        console.log('this.userObj.Start_Of_Day__c'+this.userObj.Start_Of_Day__c); // Start Of Day 
    
        this.userObj.End_of_Day__c = endDayValue; 
        console.log('this.userObj.End_of_Day__c'+this.userObj.End_of_Day__c); // End Of Day */

        this.userObj.Persona__c = personaValue; 
        console.log('this.userObj.Persona__c'+this.userObj.Persona__c); // Persona
    
        
        this.userObj.Access_Details__c = this.accessDetails; 
        console.log('this.userObj.Access_Details__c'+this.userObj.Access_Details__c) // Access Details 
    
    
        this.userObj.Environments__c = environmentsValue; 
        console.log('this.userObj.Environments__c'+this.userObj.Environments__c); // Environments 

        this.userObj.Access_Period_Start__c = accessStart; 
        console.log('this.userObj.Access_Period_Start__c'+this.userObj.Access_Period_Start__c); //access period start 

        this.userObj.Access_Period_End__c = accessEnd; 
        console.log('this.userObj.Access_Period_End__c'+this.userObj.Access_Period_End__c); //access period end 

        this.userObj.Request_Type__c = userType; 
        console.log('this.userObj.Request_Type__c'+this.userObj.Request_Type__c); //User Type

        this.userObj.Reference_User__c = selectedUserId; 
        console.log('this.userObj.Reference_User__c'+this.userObj.Reference_User__c); //Reference User

        this.userObj.Business_Justification__c = business; 
        console.log('this.userObj.Business_Justification__c'+this.userObj.Business_Justification__c); //Business Justification
    
    //    this.isSubmitButtonDisabled= true; 
        
        console.log('User object before calling Apex method:', this.userObj);
        createUserAccessRecord({ objUser: this.userObj, userType: this.userType }) 
        .then((result) => { 
            this.result = result;
            console.log('Result==> '+result);
            if (result && result.includes('Error')) { 
                try { 
                    let parsedResult = JSON.parse(result); 
                    if (parsedResult.body && parsedResult.body.message) { 
                        this.errorMessage = parsedResult.body.message; 
                        this.scrollToError();
                    } else { 
                        this.errorMessage = 'An error occurred while processing the request.'; 
                        this.scrollToError();
                    } 
                } catch (e) { 
                   // this.errorMessage = 'Parsing error occurred: ' + e.message; 

                   this.errorMessage = 'Please Fill all the Columns'; 
                    this.scrollToError();
                } 
            } else {
                this.showAccessForm = false; 
                this.showNewUserForm = false; 
                this.isSubmitted = true; 
                this.error = undefined; 
                this.scrollToError();
            } 
        }) 
        .catch((error) => { 
            this.error = error; 
            if (error.body && error.body.pageErrors && error.body.pageErrors.length > 0){ 
                this.errorMessage = error.body.pageErrors[0].message; 
                this.scrollToError();
            } else if (error.body && error.body.message) { 
                this.errorMessage = error.body.message; 
                this.scrollToError();
            } else { 
                this.errorMessage = 'An error occurred while submitting the application.'; 
                this.scrollToError();
            } 
            console.error("Error message: " + this.errorMessage); 
        //    this.isSubmitButtonDisabled = false;
            this.scrollToError();
        });
 
    }

    
    //Existing User details 
	existSubmitHandler() { 
        console.log('Inside submit handler');
        console.log('User Type:', this.userType);
        
        // Retrieve the input values
        let firstName = this.template.querySelector('lightning-input[data-formfield="firstname"]').value;
        let lastName = this.template.querySelector('lightning-input[data-formfield="lastname"]').value;
        let email = this.template.querySelector('lightning-input[data-formfield="email"]').value;
        let federationId = this.template.querySelector('lightning-input[data-formfield="federationId"]').value;
        let productTeamValue = this.productTeamValue;
        let environmentsValue = this.environmentsValue;
        let personaValue = this.personaValue;
        let addPerValue = this.addPerValue;
        let removePerValue = this.removePerValue;
        let userType = this.userType;
        let business = this.template.querySelector('lightning-input[data-formfield="business"]').value;
    
        // Check if any of the required fields are empty
        if (!firstName || !lastName || !email || !federationId || 
            !productTeamValue || !environmentsValue || !business){
            window.scrollTo({ top: 0, behavior: 'smooth' });
            this.errorMessage = 'Please fill all the columns';
            this.scrollToError();
            return;
        }
    
        this.userObj.First_Name__c = firstName;
        console.log('this.userObj.First_Name__c'+this.userObj.First_Name__c)//firstName  
    
        this.userObj.Last_Name__c = lastName;
        console.log('this.userObj.Last_Name__c'+this.userObj.Last_Name__c)// LastName 
    
        this.userObj.Email__c = email; 
        console.log('this.userObj.Email__c'+this.userObj.Email__c)// Email 
    
        this.userObj.Federation_ID__c = federationId; 
        console.log('this.userObj.Federation_ID__c'+this.userObj.Federation_ID__c) //Federation ID 
    
        this.userObj.Product_Team__c = productTeamValue; 
        console.log('this.userObj.Product_Team__c=='+this.userObj.Product_Team__c); //Product Team 

        this.userObj.Persona__c = personaValue; 
        console.log('this.userObj.Persona__c'+this.userObj.Persona__c); // Persona
    
        this.userObj.Access_Details__c = this.accessDetails; 
        console.log('this.userObj.Access_Details__c'+this.userObj.Access_Details__c); // Access Details

        // if(!this.accessDetails || this.accessDetails.trim().length === 0) { 
        //     this.errorMessage = 'Access Details is required.'; 
        //     this.scrollToError();
        //     return; 
        // } else { 
        //     this.userObj.Access_Details__c = this.accessDetails; 
        //     console.log('this.userObj.Access_Details__c'+this.userObj.Access_Details__c) // Access Details 
        // } 
    
        this.userObj.Environments__c = environmentsValue; 
        console.log('this.userObj.Environments__c'+this.userObj.Environments__c); // Environments 

        this.userObj.Addition_of_Permission__c = addPerValue; 
        console.log('this.userObj.Addition_of_Permission__c'+this.userObj.Addition_of_Permission__c); //Addition of Permissions

        this.userObj.Removal_of_Permissions__c = removePerValue; 
        console.log('this.userObj.Removal_of_Permissions__c'+this.userObj.Removal_of_Permissions__c); //Removal of Permissions

        this.userObj.Request_Type__c = userType; 
        console.log('this.userObj.Request_Type__c'+this.userObj.Request_Type__c); //User Type

        this.userObj.Business_Justification__c = business; 
        console.log('this.userObj.Business_Justification__c'+this.userObj.Business_Justification__c); //Business Justification
    
    //    this.isSubmitButtonDisabled= true; 
        
        console.log('User object before calling Apex method:', this.userObj);
        createUserAccessRecord({ objUser: this.userObj, userType: this.userType }) 
        .then((result) => { 
            this.result = result;
            console.log('Result==> '+result);
            if (result && result.includes('Error')) { 
                try { 
                    let parsedResult = JSON.parse(result); 
                    if (parsedResult.body && parsedResult.body.message) { 
                        this.errorMessage = parsedResult.body.message; 
                        this.scrollToError();
                    } else { 
                        this.errorMessage = 'An error occurred while processing the request.'; 
                        this.scrollToError();
                    } 
                } catch (e) { 
                   // this.errorMessage = 'Parsing error occurred: ' + e.message; 

                   this.errorMessage = 'Please Fill all the Columns'; 
                    this.scrollToError();
                } 
            } else {
                this.showAccessForm = false; 
                this.showNewUserForm = false; 
                this.isSubmitted = true; 
                this.error = undefined; 
                this.scrollToError();
            } 
        }) 
        .catch((error) => { 
            this.error = error; 
            if (error.body && error.body.pageErrors && error.body.pageErrors.length > 0){ 
                this.errorMessage = error.body.pageErrors[0].message; 
                this.scrollToError();
            } else if (error.body && error.body.message) { 
                this.errorMessage = error.body.message; 
                this.scrollToError();
            } else { 
                this.errorMessage = 'An error occurred while submitting the application.'; 
                this.scrollToError();
            } 
            console.error("Error message: " + this.errorMessage); 
        //    this.isSubmitButtonDisabled = false;
            this.scrollToError();
        });
 
    }
    

    scrollToError() {
        const errorElement = this.template.querySelector('.error-message');
        if (errorElement) {
            errorElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
        } else {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }

    clearErrorMessage() {
        
        this.errorMessage = '';
    //    this.isSubmitButtonDisabled = false;
       // window.location.reload();
      //  this.resethandler();
        this.isErrorMessage = false;
        this.isEndOfDayDisabled = true;

    }
    errorButtonHandler() {
        this.showNewUserForm = true;
        this.isError = false;
    }
    
    cancelHandler() {
        this.showAccessForm = false;
        this.showNewUserForm = false;
        this.showExistingUserForm = false;
     //   this.isSubmitButtonDisabled = false;
        this.isCanceled = true
        this.resethandler();
    }

    backButtonHandler(){
        window.location.reload();
        this.isSubmitted = false;
        this.isError = false; 
    //    this.isSubmitButtonDisabled = false;
        this.showNewUserForm = false;
        this.showAccessForm = true;
        this.showUsersImg = true;
        this.showExistingUserForm = false;
        this.isCanceled = false;
        this.isErrorMessage = false;
        this.errorMessage = false;
        this.resethandler();
        
    }
    resethandler(){
        this.startDayValue = ''; // Reset startDayValue
        this.accessDetails = ''; // Reset accessDetails
        this.divisionValue = ''; // Reset  divisionValue
        this.productTeamValue = ''; // Reset productTeamValue
        this.timeZoneValue = ''; // Reset timeZoneValue
        this.environmentsValue = ''; // Reset environmentsValue
    }
}