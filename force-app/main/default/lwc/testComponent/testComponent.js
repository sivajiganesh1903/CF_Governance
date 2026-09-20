import { LightningElement } from 'lwc';
export default class TestComponent extends LightningElement {
    name = 'World';

    handleChange(event) {
        this.name = event.target.value;
    }
}