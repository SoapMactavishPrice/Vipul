import { LightningElement, track, wire } from 'lwc';
import getTodos from '@salesforce/apex/CreateTask.getTasks';
import addTodo from '@salesforce/apex/CreateTask.addTask';
import markTodoAsDone from '@salesforce/apex/CreateTask.markTaskAsCompleted';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentUserName from '@salesforce/apex/CreateTask.getCurrentUserName';
import getUsers from '@salesforce/apex/CreateTask.getUsers';

export default class CreateTaskLwc extends LightningElement {
    @track todos = { openDueToday: [], openOverdue: [], completedTasks: [] };
    newTodoTitle = '';
    selectedDateTime;
    selectedPriority = 'Normal'; // Default priority
    selectedObject = '';
    searchTerm = '';
    searchResults = [];
    showSearchBox = false;
    selectedRecordId = '';
    filledByName = ''; // To store the current user name
    filledByID = ''; // Store the logged-in user's ID
    selectedOwnerId = ''; // Track the selected owner ID
    userOptions = []; // Store user options for combobox

    @wire(getCurrentUserName)
    currentUserName({ data, error }) {
        if (data) {
            console.log('getCurrentUserName', JSON.stringify(data));
            this.filledByName = data.Name; // Store the logged-in user's name
            this.filledByID = data.Id; // Store the logged-in user's ID
            this.selectedOwnerId = data.Id; // Set the default owner ID to the current user
        } else if (error) {
            console.error('Error fetching user name: ', error);
        }
    }

    @wire(getUsers)
    wiredUsers({ data, error }) {
        if (data) {
            this.userOptions = data.map(user => {
                return { label: user.Name, value: user.Id };
            });
        } else if (error) {
            console.error('Error fetching users: ', error);
        }
    }

    // Options for the priority combobox
    get priorityOptions() {
        return [
            { label: 'Low', value: 'Low' },
            { label: 'Normal', value: 'Normal' },
            { label: 'High', value: 'High' },
        ];
    }

    // Options for the related object combobox
    get objectOptions() {
        return [
            { label: 'Lead', value: 'Lead' },
            { label: 'Account', value: 'Account' },
            { label: 'Contact', value: 'Contact' },
        ];
    }

    // Wire to fetch tasks from Apex
    @wire(getTodos) wiredTodos(result) {
        if (result.data) {
            const today = new Date();
            const yesterday = new Date(today);
            yesterday.setDate(today.getDate() - 1);
            const dayBeforeYesterday = new Date(today);
            dayBeforeYesterday.setDate(today.getDate() - 2);

            this.todos = {
                openDueToday: result.data.filter(task => this.isOpenDueToday(task)),
                openOverdue: result.data.filter(task => this.isOpenOverdue(task)),
                completedTasks: result.data.filter(task => {
                    const taskCompletionDate = new Date(task.ActivityDate);
                    // Ensure the task completion date is today, yesterday, or the day before yesterday
                    return task.Status === 'Completed' && (
                        taskCompletionDate.toDateString() === today.toDateString() ||
                        taskCompletionDate.toDateString() === yesterday.toDateString() ||
                        taskCompletionDate.toDateString() === dayBeforeYesterday.toDateString()
                    );
                })
            };
        } else if (result.error) {
            console.log(result.error);
        }
    }

    // Filter method to check if the task is Open Due Today
    isOpenDueToday(task) {
        const taskDueDate = new Date(task.ActivityDate);
        const today = new Date();
        return taskDueDate.toDateString() === today.toDateString() && task.Status !== 'Completed';
    }

    // Filter method to check if the task is Open Overdue
    isOpenOverdue(task) {
        const taskDueDate = new Date(task.ActivityDate);
        const today = new Date();
        return taskDueDate < today && task.Status !== 'Completed' && taskDueDate.toDateString() !== today.toDateString();
    }

    // Method to handle the adding of a new task
    addTodo() {
        // Validate required fields
        if (this.newTodoTitle.trim() === '') {
            this.showToast('Error', 'Task name is required', 'error');
            return;
        }

        if (!this.selectedDateTime) {
            this.showToast('Error', 'Due date is required', 'error');
            return;
        }

        if (!this.selectedPriority) {
            this.showToast('Error', 'Priority is required', 'error');
            return;
        }

        if (!this.selectedObject) {
            this.showToast('Error', 'Related object is required', 'error');
            return;
        }

        if (!this.selectedRecordId) {
            this.showToast('Error', 'Please select a related record', 'error');
            return;
        }

        if (!this.selectedOwnerId) {
            this.showToast('Error', 'Assigned To is required', 'error');
            return;
        }

        // Determine the correct Id field to pass (WhatId or WhoId)
        let relatedRecordId = this.selectedRecordId;
        let whatId = null;
        let whoId = null;

        // If the selected object is Lead or Contact, use WhoId, else use WhatId
        if (this.selectedObject === 'Lead' || this.selectedObject === 'Contact') {
            whoId = relatedRecordId;
        } else {
            whatId = relatedRecordId;
        }

        // Call the addTask method from Apex
        addTodo({
            subject: this.newTodoTitle,
            dueDateTime: this.selectedDateTime,
            priority: this.selectedPriority,
            whatId: whatId,
            whoId: whoId,
            ownerId: this.selectedOwnerId // Pass the selected owner ID
        })
            .then(() => {
                this.showToast('Success', 'Task added successfully', 'success');
                this.newTodoTitle = ''; // Clear the task name input field
                location.reload(); // Refresh the page to show updated task list
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    // Method to mark a task as done
    markAsDone(event) {
        const taskId = event.target.dataset.id; // Get the task ID from the button's data-id attribute
        markTodoAsDone({ taskId })
            .then(() => {
                this.showToast('Success', 'Task marked as completed', 'success');
                location.reload();
            })
            .catch(error => {
                this.showToast('Error', 'Error marking task as completed', 'error');
            });
    }

    // Method to show a toast notification
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt); // Dispatch the toast event to show the notification
    }

    // Event handler for task name input change
    handleTitleChange(event) {
        this.newTodoTitle = event.target.value;
    }

    // Event handler for priority change
    handlePriorityChange(event) {
        this.selectedPriority = event.target.value;
    }

    // Event handler for date change
    handleDateChange(event) {
        this.selectedDateTime = event.target.value;
    }

    // Event handler for related object change
    handleObjectChange(event) {
        this.selectedObject = event.target.value;
        this.showSearchBox = true;
        this.searchTerm = '';
        this.searchResults = [];
    }

    // Event handler for owner change
    handleOwnerChange(event) {
        this.selectedOwnerId = event.detail.value;
    }

    // Event handler for search term change
    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
        console.log('Search Term:', this.searchTerm);
        this.selectedRecordId = event.detail.recordId;
        console.log('Selected Record Id:', this.selectedRecordId);
    }

    // Computed properties to determine which search box to show
    get isLead() {
        return this.selectedObject === 'Lead';
    }

    get isAccount() {
        return this.selectedObject === 'Account';
    }

    get isContact() {
        return this.selectedObject === 'Contact';
    }
}