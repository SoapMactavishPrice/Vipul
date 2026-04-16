import { LightningElement, wire, api, track } from 'lwc';
import getRecentActivities from '@salesforce/apex/ActivityTimelineController.getRecentActivities';

export default class ActivityTimelineData extends LightningElement {
    @api recordId;

    // @wire(getRecentActivities, { recordId: '$recordId' })
    // activities;

    activities;
    error;
    activeSection = null;  // Keeps track of which section is currently active.
    openSections = [];  // Manages which sections are open

    // @wire(getRecentActivities, { recordId: '$recordId' })
    // wiredActivities({ error, data }) {
    //     if (data) {
    //         this.activities = data;
    //         this.error = undefined;
    //     } else if (error) {
    //         this.activities = undefined;
    //         this.error = error;
    //     }
    // }


    connectedCallback() {
        console.log('activities', this.activities);
        console.log('recordId', this.recordId);
        setTimeout(() => {
            this.getData();
        }, 4000);
    }


    getData() {
        console.log('recordId2', this.recordId);
        getRecentActivities({ recordId: this.recordId })
            .then((result) => {
                console.log('palletdata', result);
                this.activities = result;
            })
            .catch((error) => {

            })
    }

    // Handle section toggle event and manage open sections manually
    handleAccordionToggle(event) {
        const openedSections = event.detail.openSections; // This will be an array of section values
        console.log('openedSections', openedSections);

        // Update the openSections array with the new set of open sections
        this.openSections = openedSections;

        console.log('openSections after toggle', this.openSections);
    }


}