import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentUserName from '@salesforce/apex/MarketingForm.getCurrentUserName';
import getAccounts from '@salesforce/apex/MarketingForm.getAccounts';
import getUsers from '@salesforce/apex/MarketingForm.getUsers';
import getCountries from '@salesforce/apex/MarketingForm.getCountries';
import createOpportunityRecord from '@salesforce/apex/MarketingForm.createOpportunityRecord';

export default class MarketingForm extends LightningElement {
    filledByName = ''; // To store the current user name
    opportunityName = '';
    closeDate = '';
    enquiryMode = ''; // No default value, will show "None"
    enquiryType = ''; // No default value, will show "None"
    customerType = ''; // No default value, will show "None"
    accountId = '';
    whoWillAttend = '';
    description = '';
    countryId = ''; // No default value, will show "None"

    accountOptions = [];
    userOptions = [];
    countryOptions = [];

    // Enquiry Mode Options with "None"
    enquiryModeOptions = [
        { label: 'None', value: '' }, // Default empty value for "None"
        { label: 'Web', value: 'Web' },
        { label: 'Phone', value: 'Phone' },
        { label: 'Email', value: 'Email' },
        { label: 'Referral', value: 'Referral' },
    ];

    // Enquiry Type Options with "None"
    enquiryTypeOptions = [
        { label: 'None', value: '' }, // Default empty value for "None"
        { label: 'Lead', value: 'Lead' },
        { label: 'Opportunity', value: 'Opportunity' },
    ];

    // Customer Type Options with "None"
    customerTypeOptions = [
        { label: 'None', value: '' }, // Default empty value for "None"
        { label: 'Old', value: 'Old' },
        { label: 'New', value: 'New' },
    ];

    // Wire to fetch current user's name
    @wire(getCurrentUserName)
    currentUserName({ data, error }) {
        if (data) {
            this.filledByName = data; // Store the logged-in user's name
        } else if (error) {
            console.error('Error fetching user name: ', error);
        }
    }

    // Wire to fetch Accounts for Client Name
    @wire(getAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.accountOptions = data.map(account => ({
                label: account.Name,
                value: account.Id
            }));
        } else if (error) {
            console.error('Error fetching accounts: ', error);
        }
    }

    // Wire to fetch Users for "Who will attend"
    @wire(getUsers)
    wiredUsers({ data, error }) {
        if (data) {
            this.userOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        } else if (error) {
            console.error('Error fetching users: ', error);
        }
    }

    // Wire to fetch Country options
    @wire(getCountries)
    wiredCountries({ data, error }) {
        if (data) {
            this.countryOptions = data.map(country => ({
                label: country.label,
                value: country.value
            }));
        } else if (error) {
            console.error('Error fetching countries: ', error);
        }
    }

    // Handle input changes
    handleInputChange(event) {
        const field = event.target.dataset.id;
        if (field === 'opportunityName') {
            this.opportunityName = event.target.value;
        } else if (field === 'enquiryMode') {
            this.enquiryMode = event.target.value;
        } else if (field === 'enquiryType') {
            this.enquiryType = event.target.value;
        } else if (field === 'customerType') {
            this.customerType = event.target.value;
        } else if (field === 'accountId') {
            this.accountId = event.target.value;
        } else if (field === 'whoWillAttend') {
            this.whoWillAttend = event.target.value;
        } else if (field === 'description') {
            this.description = event.target.value;
        } else if (field === 'countryId') {
            this.countryId = event.target.value;
        }
    }

    // Create Opportunity function
    createOpportunity() {
        const today = new Date();
        const closeDate = new Date(today.setDate(today.getDate() + 30)).toISOString().split('T')[0];

        createOpportunityRecord({
            opportunityName: this.opportunityName,
            closeDate: closeDate,
            filledBy: this.filledByName, // Use the filledByName for creating opportunity
            enquiryMode: this.enquiryMode,
            enquiryType: this.enquiryType,
            customerType: this.customerType,
            accountId: this.accountId,
            whoWillAttend: this.whoWillAttend,
            countryId: this.countryId,
            description: this.description
        })
            .then(result => {
                this.showToast('Success', 'Opportunity created successfully', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Error creating opportunity: ' + error.body.message, 'error');
            });
    }

    // Helper function to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}