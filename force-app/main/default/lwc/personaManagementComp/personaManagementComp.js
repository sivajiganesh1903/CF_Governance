import { LightningElement, track, wire } from 'lwc';
import CF_IMAGE from '@salesforce/resourceUrl/CfLogo';
import HEADER_IMAGE from '@salesforce/resourceUrl/FirecallcenterImage';
import fetchSalesforceOrg from '@salesforce/apex/FirecallFrameworkController.fetchSalesforceOrg';
import getPersonaRecords from '@salesforce/apex/FirecallFrameworkController.getPersonaRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchUsersByUernameKeyword from '@salesforce/apex/UserPermissionFetcherController.fetchUsersByUernameKeyword';
import getPersonaPermissions from '@salesforce/apex/FirecallFrameworkController.getPersonaPermissions';
import createUAMandRequests from '@salesforce/apex/FirecallFrameworkController.createUAMandRequests';
import fetchUserPermissionsById from '@salesforce/apex/UserPermissionFetcherController.fetchUserPermissionsById';
import getDivisionPicklistValues from '@salesforce/apex/FirecallFrameworkController.getDivisionPicklistValues';

export default class PersonaManagementComp extends LightningElement {

    /* ────── images ────── */
    headerImageUrl = CF_IMAGE;
    imageUrl = HEADER_IMAGE;

    /* ────── page‑state flags ────── */
    @track showStartPage = true;
    @track showPersonaPage = false;
    @track showPersona = false;
    @track thankyouPage = false;
    @track showPermissionsPage = false;
    @track newUserPage = false;
    @track isCanceled = false;

    @track salesforceOrgOptions = [];
    selectedSalesforceOrg = '';
    selectedOrgName;
    orgMap = new Map();
    @track orgType = '';

    @wire(fetchSalesforceOrg)
    wiredOrgs({ data, error }) {
        if (data) {
            this.orgMap.clear();
            this.salesforceOrgOptions = data.map(rec => {
                this.orgMap.set(rec.Id, rec.Name);
                return { label: rec.Name, value: rec.Id };
            });
        } else if (error) {
            console.error(error);
        }
    }

    handleChangeSalesforceOrg(event) {
        this.selectedSalesforceOrg = event.detail.value;
        this.selectedOrgName = this.orgMap.get(this.selectedSalesforceOrg);
        console.log('Org Name: ' + this.selectedOrgName);
        console.log('Selected Org' + this.selectedSalesforceOrg);
        this.updatePermissionsView();
    }

    /* ────── NAVIGATION buttons ────── */
    exPsHandleClick() {
        console.log('Check existing permissions');
        this.showStartPage = false;
        this.newUserPage = false;
        this.isPermissionLoading = true;

        if (this.selectedUsers && this.selectedUsers.length > 0) {
            if (this.selectedUsers.length === 1) {
                this.showPermissionsPage = true;
                this.showPersonaPage = false;
                this.showPersona = false;
            } else {
                this.showPermissionsPage = false;
                this.showPersonaPage = true;
                this.showPersona = true;
            }

            if (this.selectedSalesforceOrg) {
                if (this.selectedUsers.length === 1) {
                    const uid = this.selectedUsers[0].Id;
                    this.loadUserPermissions(uid);
                }
            } else {
                this.isPermissionLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Component mis-configured',
                        message: 'selectedSalesforceOrg and userId are required.',
                        variant: 'error'
                    })
                );
            }

        } else {
            this.isPermissionLoading = false;
            this.showError('Please select at least one user.');
            this.showStartPage = true;
        }
    }


    @track personaList = [];
    @track permissionRows = null;
    @track permissionColumns = [];

    @track selectedPersonaId = '';
    errorPersona;
    showPersonaHeading = 'Select Persona';
    permissionMessage = '';
    selectedPersonaName = '';
    userObj = { 'sobjectType': 'User_Access_Managment__c' };
    accessDetails
    @track accessPeriodStart;
    @track accessPeriodEnd;
    @track isModalOpen = false;
    @track permissionsFound = true;
    userAccessResult;
    isRequested = false;

    get showAccessPeriod() {
        if (this.orgType?.toLowerCase() === 'production') {
            return true;
        }
        const persona = this.personaList.find(p => p.Id === this.selectedPersonaId);
        return persona?.IsSensitive__c === true;
    }

    //For Access Details
    aceessDetailshandleChange(event) {
        this.accessDetails = event.detail.value;
    }

    //Access Period Start   
    handleDateChange(event) {
        this.accessPeriodStart = event.target.value;
        console.log('Access Period Start: ' + this.accessPeriodStart);
    }

    //Access Period End
    handleDateEndChange(event) {
        this.accessPeriodEnd = event.target.value;
        console.log('Access Period End: ' + this.accessPeriodEnd);
    }

    formatLabel(key) {
        return key
            .replace(/_|-/g, ' ')
            .replace(/([a-z\d])([A-Z])/g, '$1 $2')
            .replace(/\w\S*/g, w => w.charAt(0).toUpperCase() + w.slice(1));
    }

    /* ---------- fetch permissions ---------- */
    loadPersonaPermissions(personaId) {
        if (!personaId) return;

        this.permissionsFound = true;
        this.permissionRows = null;
        this.permissionMessage = '';

        getPersonaPermissions({ personaId })
            .then(jsonStr => {
                if (!jsonStr) {
                    this._setNoPermissions();
                    return;
                }

                const parsed = JSON.parse(jsonStr);
                if (!Array.isArray(parsed) || parsed.length === 0) {
                    this._setNoPermissions();
                    return;
                }
                const visibleKeys = ['Name', 'Description', 'ComponentType'];
                this.permissionColumns = visibleKeys.map(k => ({
                    label: this.formatLabel(k),
                    fieldName: k,
                    type: 'text'
                }));
                this.permissionRows = parsed.map((row, idx) => ({
                    id: idx + 1,
                    ...row
                }));
            })
            .catch(err => {
                this._setNoPermissions(
                    err?.body?.message || err.message
                );
            });
    }

    _setNoPermissions(customMsg) {
        this.permissionsFound = false;
        this.permissionRows = null;
        this.permissionColumns = [];
        this.permissionMessage =
            customMsg ??
            '*No permissions have been assigned to this persona. ' +
            'Please contact the DevOps team.';
    }
    handlePersonaChange(evt) {
        const id = evt.target.dataset.id;
        this.setSelectedPersona(id);
        this.loadUserPermissions(this.selectedUsers[0].Id);;
    }

    handlePersonaDoubleClick(evt) {
        const id = evt.target.dataset.id;
        if (this.selectedPersonaId === id) {
            this.setSelectedPersona(null);
            this.permissionRows = null;
            this.permissionColumns = [];
        }
    }

    setSelectedPersona(id) {
        this.selectedPersonaId = id || '';
        console.log('Selected Persona Id: ' + this.selectedPersonaId);

        const rec = id ? this.personaList.find(p => p.Id === id) : null;
        this.selectedPersonaName = rec ? rec.Name__c : '';
        console.log('Selected Persona Name : ' + this.selectedPersonaName);

        this.personaList = this.personaList.map(p => ({
            ...p,
            isSelected: id && p.Id === id,
            cssClass: id && p.Id === id ? 'radio-tile selected'
                : 'radio-tile'
        }));
    }

    fetchAllPersonas() {
        getPersonaRecords({ orgId: this.selectedSalesforceOrg })
            .then(result => {
                this.personaList = result.map(p => ({
                    ...p,
                    isSelected: false,
                    cssClass: 'radio-tile'
                }));

            })
            .catch(err => {
                this.errorPersona = err.body ? err.body.message : err;
            });
    }

    handleCheckPermissions(event) {
        event.preventDefault();

        const id = event.target.dataset.id;
        const name = event.target.dataset.name;

        this.selectedPersonaId = id;
        this.selectedPersonaName = name;
        this.isModalOpen = true;

        this.loadPersonaPermissions(id);
    }

    closeModal() {
        this.isModalOpen = false;
        this.permissionRows = null;
        this.permissionColumns = [];
        this.permissionMessage = '';
        this.permissionsFound = true;
    }

    @track uamRecordName;
    handleRequestPersonaForExistingUser() {
        console.log('Inside handleRequestPersonaForExistingUser');

        try {
            if (!this.selectedUsers) {
                this.showError('Please select a user first.');
                this.showStartPage = true;
                return;
            }
            const businessInput = this.template.querySelector('[data-formfield="business"]');
            businessInput.reportValidity();
            if (!businessInput.checkValidity()) {
                this.showError('Please fill all required fields.');
                return;
            }

            const business = businessInput.value.trim();

            const uamRec = {
                Division__c: this.selectedDivision,
                Persona_New__c: this.selectedPersonaId,
                Business_Justification__c: businessInput.value.trim(),
                Access_Details__c: this.accessDetailsNew,
                Access_Period_Start__c: this.accessPeriodStartNew,
                Access_Period_End__c: this.accessPeriodEndNew,
                Requested_Environment__c: this.selectedSalesforceOrg,
                Request_Type__c: this.userType
            };
            const userRequests = (this.selectedUsers || []).map(u => ({
                First_Name__c: u.FirstName,
                Last_Name__c: u.LastName,
                Federation_Id__c: u.FederationIdentifier,
                Email__c: u.Email
            }));

            if (userRequests.length === 0) {
                this.showError('Please select at least one user.');
                this.showStartPage = true;
                return;
            }


            this.isRequested = true;
            console.log('Selected Users:', JSON.stringify(this.selectedUsers));
            console.log('UAM record:', JSON.stringify(uamRec));
            console.log('User Requests:', JSON.stringify(userRequests));

            this.showStartPage = false;

            createUAMandRequests({ uamRec, userRequests })
                .then(result => {
                    this.uamRecordName = result.Name;
                    console.log('UAM Name: ' + this.uamRecordName);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `User-access request created: ${this.uamRecordName}`,
                            variant: 'success'
                        })
                    );
                    this.showPersonaPage = false;
                    this.showPermissionsPage = false;
                    this.showPersona = false;
                    this.thankyouPage = true;
                    this.newUserPage = false;
                    this.noUsersFound = false;
                })
                .catch(err => {
                    this.showError(
                        err?.body?.message || err?.message || 'Failed to create record.'
                    );
                })
                .finally(() => { this.isRequested = false; });

        } catch (e) {
            this.showError(e.message || 'Unexpected script error.');
            console.error('JS error in handleRequestPersonaForExistingUser:', e);
            this.isRequested = false;
        }
    }


    handlePrevious3() {
        this.showPersonaPage = false;
        this.showPersona = false;
        this.showPermissionsPage = this.selectedUsers.length === 1;

        if (this.showPermissionsPage) {
            this.loadUserPermissions(this.selectedUsers[0].Id);
            this.showStartPage = false;
        } else {
            this.profileName = null;
            this.permissionSets = [];
            this.permissionSetGroups = [];
            this.territories = [];
            this.dataLoaded = false;
            this.permissionError = false;
            this.errorMessage = '';
            this.showStartPage = true;
        }
    }
    goHomeHandler() {
        window.location.reload();
        eval("$A.get('e.force:refreshView').fire();");
        this.showStartPage = true;
        this.showPersonaPage = false;
        this.showPermissionsPage = false;
        this.showPersona = false;
        this.thankyouPage = false;

    }

    /* ────── USER SCOPE radio group ────── */

    delayTimeout;
    searchValue = '';
    suggestedUsers = [];
    @track selectedUsers = [];
    // @track selectedUserId = [];
    @track noUsersFound = false;
    @track selectedFirstName;
    @track selectedLastName;
    @track selectedEmail;
    @track selectedFederation;
    @track selectedDivision;

    handleSearchKeyUp(event) {
        this.searchValue = event.target.value;
        this.searchUsersByUsername();
    }

    async searchUsersByUsername() {
        // guard clauses
        if (!this.searchValue.trim() || !this.selectedSalesforceOrg) {
            this.suggestedUsers = [];
            this.noUsersFound = false;
            this.clearSuggestions();
            return;
        }
        try {
            const result = await fetchUsersByUernameKeyword({
                orgId: this.selectedSalesforceOrg,
                usernameKeyword: this.searchValue.trim()
            });
            const users = result?.users || [];
            this.suggestedUsers = users.map(u => ({
                ...u,
                Username: u.Username,
                Id: u.Id,

            }));
            this.noUsersFound = users.length === 0;
        } catch (err) {
            console.error('Username lookup failed', err);
            this.suggestedUsers = [];
            this.noUsersFound = true;
        }
    }

    get hasSuggestions() { return this.suggestedUsers.length > 0; }

    get last() {
        return this.selectedUsers.length
            ? this.selectedUsers[this.selectedUsers.length - 1]
            : {};
    }
    get selectedFirstName() { return this.last.FirstName; }
    get selectedLastName() { return this.last.LastName; }
    get selectedEmail() { return this.last.Email; }
    get selectedFederation() { return this.last.FederationIdentifier; }
    get selectedDivision() { return this.last.Division; }

    handleUserClick(event) {
        const userId = event.currentTarget.dataset.userId;
        if (!userId) { return; }

        const chosen = this.suggestedUsers.find(u => u.Id === userId);
        if (!chosen) { return; }

        const alreadyChosen = this.selectedUsers.some(u => u.Id === userId);
        if (!alreadyChosen) {
            this.selectedUsers = [...this.selectedUsers, chosen];
            console.log('Selected User: ' + this.selectedUsers);
            console.log('Selected User:', JSON.stringify(this.selectedUsers));
        }

        this.selectedFirstName = chosen.FirstName;
        this.selectedLastName = chosen.LastName;
        this.selectedEmail = chosen.Email;
        this.selectedFederation = chosen.FederationIdentifier;
        this.selectedDivision = chosen.Division;
        console.log('User Firstname: ' + this.selectedFirstName);
        console.log('User Lastname: ' + this.selectedLastName);
        console.log('User Email: ' + this.selectedEmail);
        console.log('User Federation: ' + this.selectedFederation);
        console.log('User Division: ' + this.selectedDivision);

        this.clearSuggestions();
    }


    handleUserRemove(event) {
        this.selectedUser = null;
        this.template.querySelector('lightning-input').focus();
        const removeId = event.target.dataset.id;
        this.selectedUsers = this.selectedUsers.filter(u => u.Id !== removeId);
        this.template.querySelector('lightning-input').focus();
        this.updatePermissionsView();
    }

    clearSuggestions() {
        this.searchValue = '';
        this.suggestedUsers = [];
        this.noUsersFound = false;
    }
    handleCreateNewUser() {
        console.log('Inside Create new User');
        this.userType = 'New User Request';
        console.log('User Type:', this.userType);
        this.showStartPage = false;
        this.showPersonaPage = true;
        this.showPermissionsPage = false;
        this.showPersona = false;
        this.newUserPage = true;
        this.fetchAllPersonas();
    }


    /*Show existing Permissions*/
    @track profileName;
    @track permissionSets = [];
    @track permissionSetGroups = [];
    @track territories = [];

    @track dataLoaded = false;
    permissionError;
    @track isPermissionLoading = false;
    @track showPersona = false;
    errorMessage = '';

    updatePermissionsView() {
        // this.showPermissionsPage = this.selectedUsers.length === 1 && !!this.selectedSalesforceOrg;

        //    this.showPersona = this.selectedUsers.length > 1;
        //    this.showPersonaPage = this.showPersona;


        if (this.showPermissionsPage) {
            const uid = this.selectedUsers[0].Id;
            this.loadUserPermissions(uid);
        } else if (this.selectedUsers.length > 1) {
            this.profileName = null;
            this.permissionSets = [];
            this.permissionSetGroups = [];
            this.territories = [];
            this.dataLoaded = false;
            this.permissionError = false;
            this.errorMessage = '';
            this.showPersona = true;
            this.showPersonaPage = true;
        }
    }

    /*    updatePermissionsView() {

            const userList  = Array.isArray(this.selectedUsers) ? this.selectedUsers : [];
            const userCount = userList.length;
        
            this.showPermissionsPage = false;
            this.showPersonaPage     = false;
            this.showPersona         = false;
        
            if (userCount === 0 || !this.selectedSalesforceOrg) {
                return;
            }
        
            if (userCount === 1) {
                this.showPermissionsPage = true;
       
                const uid = userList[0].Id;
                if (uid) {
                    this.loadUserPermissions(uid);
                }
                return;
            }
                    this.showPersona        = true;
            this.showPersonaPage    = true;
        
     
            this.profileName         = null;
            this.permissionSets      = [];
            this.permissionSetGroups = [];
            this.territories         = [];
            this.dataLoaded          = false;
            this.permissionError     = false;
            this.errorMessage        = '';
        }   */




    loadUserPermissions(userId) {
        console.log('Starting loadUserPermissions...');
        console.log('orgId:', this.selectedSalesforceOrg);
        console.log('UserId inside loadUserPermissions: ' + userId);

        if (!this.selectedSalesforceOrg || !userId) {
            this.permissionError = true;
            this.errorMessage = 'Both orgId and userId are required.';
            return;
        }

        this.isPermissionLoading = true;
        this.permissionError = false;
        this.errorMessage = '';

        console.log('Sending to Apex → orgId:', this.selectedSalesforceOrg, 'userId:', userId);


        fetchUserPermissionsById({ orgId: this.selectedSalesforceOrg, userId: userId.trim() })
            .then((result) => {
                console.log('Apex result:', JSON.stringify(result));

                this.profileName = result.Profile;
                this.permissionSets = result.PermissionSets || [];
                this.permissionSetGroups = result.PermissionSetGroups || [];
                this.territories = result.Territories || [];

                console.log('Profile:', this.profileName);
                console.log('Sets:', this.permissionSets);
                console.log('Groups:', this.permissionSetGroups);
                console.log('Territories:', this.territories);

                this.dataLoaded = true;
                this.permissionError = false;
            })
            .catch((err) => {
                console.error('Apex error:', err);
                this.permissionError = true;
                this.errorMessage = this.extractErrorMessage(err);
            })
            .finally(() => {
                this.isPermissionLoading = false;
            });
    }
    extractErrorMessage(err) {
        if (Array.isArray(err?.body)) { return err.body.map(e => e.message).join(', '); }
        if (err?.body?.message) { return err.body.message; }
        return 'Unknown error occurred.';
    }
    handleNextScreen2() {
        this.showStartPage = false;
        this.showPersonaPage = true;
        this.showPermissionsPage = false;
        this.showPersona = true;
        this.newUserPage = false;
        this.userType = 'Existing User Request';
        console.log('User Type:', this.userType);
        this.fetchAllPersonas();
    }
    handlePrevScreen2() {
        this.showStartPage = true;
        this.showPersonaPage = false;
        this.showPermissionsPage = false;
        this.showPersona = false;
        this.newUserPage = false;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    /*New User Form */
    @track divisionOptions = [];
    divisionValue = '';
    accessDetailsNew;
    accessPeriodStartNew;
    accessPeriodEndNew;
    errorMessage;
    isSubmitButtonDisabled = false;
    isCanceled = false;
    userType = '';

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

    //For Access Details
    aceessDetailshandleChangeNew(event) {
        this.accessDetailsNew = event.detail.value;
        console.log('this.accessDetails' + this.accessDetailsNew);
    }

    //Access Period Start   
    handleDateChangeNew(event) {
        this.accessPeriodStartNew = event.target.value;
        console.log('Access Period Start: ' + this.accessPeriodStartNew);
    }

    //Access Period End
    handleDateEndChangeNew(event) {
        this.accessPeriodEndNew = event.target.value;
        console.log('Access Period End: ' + this.accessPeriodEndNew);
    }
    submitHandler() {
        console.log('Inside submitHandler');

        try {
            const requiredFields = [
                'firstname',
                'lastname',
                'emailNew',
                'federationIdNew',
                'businessNew',
                'division'
            ];

            let allValid = true;

            requiredFields.forEach((fieldName) => {
                const input = this.template.querySelector(`[data-formfield="${fieldName}"]`);
                if (input) {
                    input.reportValidity();
                    if (!input.checkValidity()) {
                        allValid = false;
                    }
                }
            });

            if (!allValid) {
                this.showError('Please fill all required fields.');
                return;
            }

            const firstName = this.template.querySelector('[data-formfield="firstname"]').value?.trim();
            const lastName = this.template.querySelector('[data-formfield="lastname"]').value?.trim();
            const email = this.template.querySelector('[data-formfield="emailNew"]').value?.trim();
            const federation = this.template.querySelector('[data-formfield="federationIdNew"]').value?.trim();
            const business = this.template.querySelector('[data-formfield="businessNew"]').value?.trim();
            const personaId = this.selectedPersonaId;
            const division = this.divisionValue;
            const accessStart = this.accessPeriodStartNew;
            const accessEnd = this.accessPeriodEndNew;
            const details = this.accessDetailsNew;
            const envValue = this.selectedSalesforceOrg;
            const userType = this.userType;

            // Construct UAM parent
            const uamRec = {
                sobjectType: 'User_Access_Managment__c',
                Division__c: division,
                Persona_New__c: personaId,
                Business_Justification__c: business,
                Access_Details__c: details,
                Access_Period_Start__c: accessStart,
                Access_Period_End__c: accessEnd,
                Requested_Environment__c: envValue,
                Request_Type__c: userType
            };

            // Construct child UR records
            const userRequests = [
                {
                    sobjectType: 'User_Request__c',
                    First_Name__c: firstName,
                    Last_Name__c: lastName,
                    Federation_Id__c: federation,
                    Email__c: email
                }
            ];

            this.isSubmitButtonDisabled = true;

            createUAMandRequests({ uamRec, userRequests })
                .then((result) => {
                    this.uamRecordName = result.Name;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `User Access Management record created (Name: ${this.uamRecordName})`,
                            variant: 'success'
                        })
                    );
                    this.showStartPage = false;
                    this.showPersonaPage = false;
                    this.showPermissionsPage = false;
                    this.showPersona = false;
                    this.thankyouPage = true;
                    this.newUserPage = false;
                    this.noUsersFound = false;
                })
                .catch((error) => {
                    this.showError(
                        error?.body?.message || error?.message || 'Failed to create record.'
                    );
                    this.scrollToError();
                });

        } catch (e) {
            this.showError(e.message || 'Unexpected script error.');
            console.error('JS error in submitHandler:', e);
            //  this.isSubmitButtonDisabled = false;
        }
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
        this.isSubmitButtonDisabled = false;
        this.isErrorMessage = false;
    }
    errorButtonHandler() {
        this.isError = false;
    }

    cancelHandler() {
        this.showStartPage = false;
        this.isCanceled = true;
        this.showPersonaPage = false;
        this.showPermissionsPage = false;
        this.showPersona = false;
        this.thankyouPage = false;
        this.isSubmitButtonDisabled = false;
        this.newUserPage = false;
        this.noUsersFound = false;
    }
    backButtonHandler() {
        this.showStartPage = true;
        window.location.reload();
        eval("$A.get('e.force:refreshView').fire();");
        this.isSubmitted = false;
        this.isError = false;
        this.showPersonaPage = false;
        this.showPermissionsPage = false;
        this.showPersona = false;
        this.thankyouPage = false;
        this.isCanceled = false;
        this.isErrorMessage = false;
        this.errorMessage = false;
        this.resethandler();
        this.selectedSalesforceOrg = '';
        this.searchValue = '';

    }

    showError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }

}