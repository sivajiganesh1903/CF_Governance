import { LightningElement, track, wire } from 'lwc';
import getEnvironments from '@salesforce/apex/ScmGlobalSettingPageController.getEnvironments';
import getSettings from '@salesforce/apex/ScmGlobalSettingPageController.getSettings';
import saveSettings from '@salesforce/apex/ScmGlobalSettingPageController.saveSettings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GlobalSettingPage extends LightningElement {
    @track environmentOptions = [];
    @track metadataOptions = [
        { label: 'ApexClass', value: 'ApexClass' },
        { label: 'ApexComponent', value: 'ApexComponent' },
        { label: 'ApexPage', value: 'ApexPage' },
        { label: 'ApexTrigger', value: 'ApexTrigger' },
        { label: 'AppMenu', value: 'AppMenu' },
        { label: 'ApprovalProcess', value: 'ApprovalProcess' },
        { label: 'AssignmentRules', value: 'AssignmentRules' },
        { label: 'AuraDefinition', value: 'AuraDefinition' },
        { label: 'AutoResponseRules', value: 'AutoResponseRules' },
        { label: 'Bot', value: 'Bot' },
        { label: 'BrandingSet', value: 'BrandingSet' },
        { label: 'BusinessProcess', value: 'BusinessProcess' },
        { label: 'CallCenter', value: 'CallCenter' },
        { label: 'CampaignInfluenceModel', value: 'CampaignInfluenceModel' },
        { label: 'CaseSubjectParticle', value: 'CaseSubjectParticle' },
        { label: 'Certificate', value: 'Certificate' },
        { label: 'CleanDataService', value: 'CleanDataService' },
        { label: 'CmsConnectSource', value: 'CmsConnectSource' },
        { label: 'Community', value: 'Community' },
        { label: 'CompactLayout', value: 'CompactLayout' },
        { label: 'ConnectedApp', value: 'ConnectedApp' },
        { label: 'ContentAsset', value: 'ContentAsset' },
        { label: 'CorsWhitelistEntry', value: 'CorsWhitelistEntry' },
        { label: 'CustomApplication', value: 'CustomApplication' },
        { label: 'CustomApplicationComponent', value: 'CustomApplicationComponent' },
        { label: 'CustomFeedFilter', value: 'CustomFeedFilter' },
        { label: 'CustomField', value: 'CustomField' },
        { label: 'CustomHelpMenuSection', value: 'CustomHelpMenuSection' },
        { label: 'CustomMetadata', value: 'CustomMetadata' },
        { label: 'CustomObject', value: 'CustomObject' },
        { label: 'CustomObjectTranslation', value: 'CustomObjectTranslation' },
        { label: 'CustomPageWebLink', value: 'CustomPageWebLink' },
        { label: 'CustomPermission', value: 'CustomPermission' },
        { label: 'CustomSite', value: 'CustomSite' },
        { label: 'CustomTab', value: 'CustomTab' },
        { label: 'Dashboard', value: 'Dashboard' },
        { label: 'DashboardFolder', value: 'DashboardFolder' },
        { label: 'DataCategoryGroup', value: 'DataCategoryGroup' },
        { label: 'DataCategoryGroupTranslation', value: 'DataCategoryGroupTranslation' },
        { label: 'DelegateGroup', value: 'DelegateGroup' },
        { label: 'Document', value: 'Document' },
        { label: 'DocumentFolder', value: 'DocumentFolder' },
        { label: 'DuplicateRule', value: 'DuplicateRule' },
        { label: 'EclairGeoData', value: 'EclairGeoData' },
        { label: 'EmbeddedServiceBranding', value: 'EmbeddedServiceBranding' },
        { label: 'EmbeddedServiceConfig', value: 'EmbeddedServiceConfig' },
        { label: 'EmbeddedServiceFieldService', value: 'EmbeddedServiceFieldService' },
        { label: 'EmbeddedServiceLiveAgent', value: 'EmbeddedServiceLiveAgent' },
        { label: 'EmbeddedServiceMenuItem', value: 'EmbeddedServiceMenuItem' },
        { label: 'EmbeddedServiceQuickAction', value: 'EmbeddedServiceQuickAction' },
        { label: 'EmailFolder', value: 'EmailFolder' },
        { label: 'EmailTemplate', value: 'EmailTemplate' },
        { label: 'EscalationRules', value: 'EscalationRules' },
        { label: 'EventDelivery', value: 'EventDelivery' },
        { label: 'EventSubscription', value: 'EventSubscription' },
        { label: 'ExternalServiceRegistration', value: 'ExternalServiceRegistration' },
        { label: 'FieldSet', value: 'FieldSet' },
        { label: 'FlexiPage', value: 'FlexiPage' },
        { label: 'Flow', value: 'Flow' },
        { label: 'FlowDefinition', value: 'FlowDefinition' },
        { label: 'GlobalValueSet', value: 'GlobalValueSet' },
        { label: 'GlobalValueSetTranslation', value: 'GlobalValueSetTranslation' },
        { label: 'Group', value: 'Group' },
        { label: 'HomePageComponent', value: 'HomePageComponent' },
        { label: 'HomePageLayout', value: 'HomePageLayout' },
        { label: 'IdeasSettings', value: 'IdeasSettings' },
        { label: 'InstalledPackage', value: 'InstalledPackage' },
        { label: 'IntegrationHubSettings', value: 'IntegrationHubSettings' },
        { label: 'KeywordList', value: 'KeywordList' },
        { label: 'Layout', value: 'Layout' },
        { label: 'Letterhead', value: 'Letterhead' },
        { label: 'ListView', value: 'ListView' },
        { label: 'LiveChatAgentConfig', value: 'LiveChatAgentConfig' },
        { label: 'LiveChatButton', value: 'LiveChatButton' },
        { label: 'LiveChatDeployment', value: 'LiveChatDeployment' },
        { label: 'LiveChatSensitiveDataRule', value: 'LiveChatSensitiveDataRule' },
        { label: 'ManagedTopics', value: 'ManagedTopics' },
        { label: 'MarketingResourceType', value: 'MarketingResourceType' },
        { label: 'MatchingRule', value: 'MatchingRule' },
        { label: 'MobileApplicationDetail', value: 'MobileApplicationDetail' },
        { label: 'NamedCredential', value: 'NamedCredential' },
        { label: 'Network', value: 'Network' },
        { label: 'PathAssistant', value: 'PathAssistant' },
        { label: 'PermissionSet', value: 'PermissionSet' },
        { label: 'PermissionSetGroup', value: 'PermissionSetGroup' },
        { label: 'PlatformCachePartition', value: 'PlatformCachePartition' },
        { label: 'Portal', value: 'Portal' },
        { label: 'ProductConsumerGroup', value: 'ProductConsumerGroup' },
        { label: 'ProfileSkill', value: 'ProfileSkill' },
        { label: 'ProfileSkillUser', value: 'ProfileSkillUser' },
        { label: 'Queue', value: 'Queue' },
        { label: 'QuickAction', value: 'QuickAction' },
        { label: 'RecommendationStrategy', value: 'RecommendationStrategy' },
        { label: 'RecordType', value: 'RecordType' },
        { label: 'RemoteSiteSetting', value: 'RemoteSiteSetting' },
        { label: 'Report', value: 'Report' },
        { label: 'ReportFolder', value: 'ReportFolder' },
        { label: 'ReportType', value: 'ReportType' },
        { label: 'Role', value: 'Role' },
        { label: 'SamlSsoConfig', value: 'SamlSsoConfig' },
        { label: 'Scontrol', value: 'Scontrol' },
        { label: 'ServiceChannel', value: 'ServiceChannel' },
        { label: 'ServicePresenceStatus', value: 'ServicePresenceStatus' },
        { label: 'SharingRules', value: 'SharingRules' },
        { label: 'SharingSet', value: 'SharingSet' },
        { label: 'SiteDotCom', value: 'SiteDotCom' },
        { label: 'Skill', value: 'Skill' },
        { label: 'StandardValueSet', value: 'StandardValueSet' },
        { label: 'StandardValueSetTranslation', value: 'StandardValueSetTranslation' },
        { label: 'StaticResource', value: 'StaticResource' },
        { label: 'SynonymDictionary', value: 'SynonymDictionary' },
        { label: 'Territory', value: 'Territory' },
        { label: 'Territory2', value: 'Territory2' },
        { label: 'Territory2Model', value: 'Territory2Model' },
        { label: 'Territory2Rule', value: 'Territory2Rule' },
        { label: 'Territory2Type', value: 'Territory2Type' },
        { label: 'TopicsForObjects', value: 'TopicsForObjects' },
        { label: 'TransactionSecurityPolicy', value: 'TransactionSecurityPolicy' },
        { label: 'Translations', value: 'Translations' },
        { label: 'UserCriteria', value: 'UserCriteria' },
        { label: 'ValidationRules', value: 'ValidationRules' },
        { label: 'WebLink', value: 'WebLink' },
        { label: 'WorkflowAlert', value: 'WorkflowAlert' },
        { label: 'WorkflowFieldUpdate', value: 'WorkflowFieldUpdate' },
        { label: 'WorkflowKnowledgePublish', value: 'WorkflowKnowledgePublish' },
        { label: 'WorkflowOutboundMessage', value: 'WorkflowOutboundMessage' },
        { label: 'WorkflowRule', value: 'WorkflowRule' },
        { label: 'WorkflowSend', value: 'WorkflowSend' },
    ];

    @track scmStrategyOptions = [
        { label: 'Back Promote', value: 'Back Promote' },
        { label: 'Approval Process', value: 'Approval Process' }
    ];
    @track validityOptions = [
        { label: '4 hours', value: '4 hours' },
        { label: '8 hours', value: '8 hours' },
        { label: '12 hours', value: '12 hours' },
        { label: '16 hours', value: '16 hours' },
        { label: '20 hours', value: '20 hours' },
        { label: '24 hours', value: '24 hours' }
    ];

    @track selectedEnvironments = [];
    @track selectedMetadataTypes = [];
    @track selectedScmStrategy = '';
    @track selectedValidity = '';
    @track isEditMode = false;
    originalState = {};


    get isViewMode() {
        return !this.isEditMode;
    }

    @wire(getEnvironments)
    wiredEnvironments({ error, data }) {
        if (data) {
            this.environmentOptions = data.map(env => {
                return { label: env.Name, value: env.Name };
            });
        } else if (error) {
            // handle error
        }
    }

    /* @wire(getSettings)
     wiredSettings({ error, data }) {
         if (data) {
             let environments = new Set();
             let metadataTypes = new Set();
             data.forEach(setting => {
                 if (setting.Type__c === 'environment') {
                     environments.add(setting.Value__c);
                 } else if (setting.Type__c === 'metadata') {
                     metadataTypes.add(setting.Value__c);
                 }
             });
             this.selectedEnvironments = Array.from(environments);
             this.selectedMetadataTypes = Array.from(metadataTypes);
         } else if (error) {
             // handle error
         }
     }*/

    @wire(getSettings)
    wiredSettings({ error, data }) {
        if (data) {
            let environments = new Set();
            let metadataTypes = new Set();
            let scmStrategy = '';
            let validity = '';
            data.forEach(setting => {
                if (setting.Type__c === 'environment') {
                    environments.add(setting.Value__c);
                } else if (setting.Type__c === 'metadata') {
                    metadataTypes.add(setting.Value__c);
                } else if (setting.Type__c === 'scmStrategy') {
                    scmStrategy = setting.Value__c;
                } else if (setting.Type__c === 'validity') {
                    validity = setting.Value__c;
                }
            });
            this.selectedEnvironments = Array.from(environments);
            this.selectedMetadataTypes = Array.from(metadataTypes);
            this.selectedScmStrategy = scmStrategy;
            this.selectedValidity = validity;

            // store original values
            this.originalState = {
                environments: [...this.selectedEnvironments],
                metadata: [...this.selectedMetadataTypes],
                scmStrategy: this.selectedScmStrategy,
                validity: this.selectedValidity
            };

        } else if (error) {
            // handle error
        }
    }
    handleEdit() {
        this.isEditMode = true;
    }
    handleCancel() {
        this.selectedEnvironments = [...this.originalState.environments];
        this.selectedMetadataTypes = [...this.originalState.metadata];
        this.selectedScmStrategy = this.originalState.scmStrategy;
        this.selectedValidity = this.originalState.validity;

        this.isEditMode = false;
    }


    handleEnvironmentChange(event) {
        this.selectedEnvironments = event.detail.value;
        console.log('this.selectedEnvironments ==' + this.selectedEnvironments)
    }

    handleMetadataChange(event) {
        this.selectedMetadataTypes = event.detail.value;
    }
    handleScmStrategyChange(event) {
        this.selectedScmStrategy = event.detail.value;
        this.selectedValidity = '';
    }

    handleValidityChange(event) {
        this.selectedValidity = event.detail.value;
    }
    
    async handleSave() {
        if (this.selectedEnvironments.length === 0) {
            this.showToast('Error', 'Please select at least one Environment.', 'error');
        } else if (this.selectedMetadataTypes.length === 0) {
            this.showToast('Error', 'Please select at least one Metadata Type.', 'error');
        } else if (this.selectedScmStrategy.length === 0) {
            this.showToast('Error', 'Please select at least one Strategy.', 'error');
        } else if (  this.selectedValidity.length === 0 ) {
            this.showToast('Error', 'Please select at least one Validity.', 'error');
        } else {
            try {
                const result = await saveSettings({
                    selectedEnvironments: this.selectedEnvironments,
                    selectedMetadataTypes: this.selectedMetadataTypes,
                    selectedScmStrategy: this.selectedScmStrategy,
                    selectedValidity: this.selectedValidity
                });
                if (result.startsWith('Error:')) {
                    this.showToast('Error', result, 'error');
                } else {
                    this.showToast('Success', 'Settings saved successfully', 'success');

                    // update original state
                    this.originalState = {
                        environments: [...this.selectedEnvironments],
                        metadata: [...this.selectedMetadataTypes],
                        scmStrategy: this.selectedScmStrategy,
                        validity: this.selectedValidity
                    };

                    this.isEditMode = false;
                  //  window.location.reload();
                }
            } catch (error) {
                this.showToast('Error saving settings', error.body.message, 'error');
            }
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

}