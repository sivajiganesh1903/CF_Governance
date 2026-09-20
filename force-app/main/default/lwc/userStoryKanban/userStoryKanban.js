import { LightningElement, wire } from 'lwc';
import getTasks from '@salesforce/apex/UserStoryViewController.getTasks';
import { NavigationMixin } from 'lightning/navigation';

export default class UserStoryKanban extends NavigationMixin(LightningElement) {
    environments = [];
    statuses = [];
    taskMatrix = [];

    @wire(getTasks)
    wiredTasks({ error, data }) {
        if (data) {
            this.processTasks(data);
        } else if (error) {
            console.error('Error fetching tasks:', error);
        }
    }

    processTasks(data) {
        const envSet = new Set();
        const statusSet = new Set();
        const taskMatrix = [];

        // Collect all unique environments and statuses
        data.forEach(task => {
            envSet.add(task.environment);
            statusSet.add(task.status);
        });

        this.environments = Array.from(envSet).sort();
        this.statuses = Array.from(statusSet).sort();

        // Prepare task matrix for rendering
        this.statuses.forEach(status => {
            const row = { status, taskCells: [] };
            this.environments.forEach(env => {
                const tasks = data.filter(
                    task => task.environment === env && task.status === status
                );

                row.taskCells.push({
                    environment: env,
                    tasks: tasks.length > 0 ? tasks : null
                });
            });
            taskMatrix.push(row);
        });

        this.taskMatrix = taskMatrix;
    }

    // Handle task click event to open the record in a new tab
    handleTaskClick(event) {
        const recordId = event.target.dataset.id;
        if (recordId) {
            window.open(`/lightning/r/${recordId}/view`, '_blank');
        }
    }
}