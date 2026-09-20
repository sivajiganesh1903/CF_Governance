import { LightningElement, track, wire } from 'lwc';
import getstoryReleatedSCA from '@salesforce/apex/UserStoryController.storyReleatedSCA';

export default class ScaStatistics extends LightningElement {
    @track chartConfiguration;
    @track error;

    @wire(getstoryReleatedSCA)
    getstoryReleatedSCA({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            let chartScore = [];
            let chartLabel = [];
            data.forEach(sca => {
                if (sca.copado__Static_Code_Analysis_Results__r && sca.copado__Static_Code_Analysis_Results__r.length > 0) {
                    chartScore.push(sca.copado__Static_Code_Analysis_Results__r[0].copado__Score_v11__c);
                    chartLabel.push(sca.Name);
                }
            });
            this.chartConfiguration = {
                type: 'bar',
                data: {
                    datasets: [{
                        label: 'SCA Score',
                        backgroundColor: "green",
                        data: chartScore,
                    }],
                    labels: chartLabel,
                },
            };
            this.error = undefined;
        }
    }
}