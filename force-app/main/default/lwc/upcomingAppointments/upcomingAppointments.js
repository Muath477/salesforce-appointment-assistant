import { LightningElement, api, wire } from 'lwc';
import getUpcomingAppointments from '@salesforce/apex/AppointmentController.getUpcomingAppointments';

export default class UpcomingAppointments extends LightningElement {
    // Exposed to App Builder so an admin can set how many rows to show without
    // touching code. Defaults to 5.
    @api maxRows = 5;

    appointments;
    errorMessage;

    // @wire calls the Apex method and re-runs it automatically when maxRows
    // changes. The result comes back as { data, error }; exactly one is set.
    @wire(getUpcomingAppointments, { maxRows: '$maxRows' })
    wiredAppointments({ data, error }) {
        if (data) {
            // Flatten the record shape into what the template needs. Doing it
            // here keeps the HTML simple (no nested Contact__r lookups there).
            this.appointments = data.map((row) => ({
                id: row.Id,
                name: row.Name,
                when: row.Appointment_Date_Time__c,
                status: row.Status__c,
                serviceType: row.Service_Type__c,
                customer: row.Contact__r ? row.Contact__r.Name : 'No contact'
            }));
            this.errorMessage = undefined;
        } else if (error) {
            this.errorMessage = 'Could not load appointments. Please try again.';
            this.appointments = undefined;
        }
    }

    // Getters keep the template simple: it just asks these yes/no questions.
    get hasAppointments() {
        return this.appointments && this.appointments.length > 0;
    }

    // True only after a successful load that returned zero rows, so the empty
    // message doesn't flash before the data arrives.
    get isEmpty() {
        return this.appointments && this.appointments.length === 0;
    }
}
