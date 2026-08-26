/**
 * Invocable action that creates, reschedules, or cancels an appointment.
 *
 * Because it is an @InvocableMethod, it can be called from an Agentforce agent
 * action, a Flow, or a Screen Flow with no code changes. This is the "agent
 * ready" bridge described in the project docs: the conversational agent
 * interprets the customer's natural-language request, then hands the structured
 * values (action + details) to this method to do the actual work on the record.
 */
public with sharing class ManageAppointmentAction {

    // The input wrapper. Each @InvocableVariable becomes a field the agent or
    // Flow maps values into.
    public class Request {
        @InvocableVariable(required=true label='Action (create, reschedule, cancel)')
        public String action;

        @InvocableVariable(label='Contact Id (for create)')
        public String contactId;

        @InvocableVariable(label='Appointment Id (for reschedule/cancel)')
        public String appointmentId;

        @InvocableVariable(label='Appointment Date/Time')
        public Datetime appointmentDateTime;

        @InvocableVariable(label='Service Type')
        public String serviceType;
    }

    // The output wrapper. Returning a friendly message and the record Id lets
    // the agent confirm back to the customer in natural language.
    public class Result {
        @InvocableVariable(label='Was the action successful?')
        public Boolean success;

        @InvocableVariable(label='Message to show the customer')
        public String message;

        @InvocableVariable(label='Appointment Id')
        public String appointmentId;
    }

    // Invocable methods take and return Lists so they can be bulkified. Here we
    // process each request and return one Result per request, in the same order.
    @InvocableMethod(label='Manage Appointment' description='Create, reschedule, or cancel an appointment')
    public static List<Result> run(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            // Normalise so 'Create', 'CREATE', ' create ' all work the same.
            String action = (req.action == null) ? '' : req.action.trim().toLowerCase();

            try {
                if (action == 'create') {
                    res = createAppointment(req);
                } else if (action == 'reschedule') {
                    res = rescheduleAppointment(req);
                } else if (action == 'cancel') {
                    res = cancelAppointment(req);
                } else {
                    res.success = false;
                    res.message = 'Unknown action "' + req.action +
                        '". Use create, reschedule, or cancel.';
                }
            } catch (Exception e) {
                // Catch here so one bad request returns a clean message to the
                // agent instead of failing the whole conversation.
                res.success = false;
                res.message = 'Something went wrong: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    private static Result createAppointment(Request req) {
        Result res = new Result();
        if (String.isBlank(req.contactId) || req.appointmentDateTime == null) {
            res.success = false;
            res.message = 'To book an appointment I need a contact and a date/time.';
            return res;
        }

        Appointment__c appt = new Appointment__c(
            Contact__c = req.contactId,
            Appointment_Date_Time__c = req.appointmentDateTime,
            Service_Type__c = String.isBlank(req.serviceType) ? 'Consultation' : req.serviceType,
            Status__c = 'Scheduled'
        );
        insert appt;

        res.success = true;
        res.appointmentId = appt.Id;
        res.message = 'Your appointment is booked for ' +
            req.appointmentDateTime.format() + '.';
        return res;
    }

    private static Result rescheduleAppointment(Request req) {
        Result res = new Result();
        if (String.isBlank(req.appointmentId) || req.appointmentDateTime == null) {
            res.success = false;
            res.message = 'To reschedule I need the appointment and a new date/time.';
            return res;
        }

        Appointment__c appt = new Appointment__c(
            Id = req.appointmentId,
            Appointment_Date_Time__c = req.appointmentDateTime,
            Status__c = 'Rescheduled'
        );
        update appt;

        res.success = true;
        res.appointmentId = appt.Id;
        res.message = 'Your appointment has been moved to ' +
            req.appointmentDateTime.format() + '.';
        return res;
    }

    private static Result cancelAppointment(Request req) {
        Result res = new Result();
        if (String.isBlank(req.appointmentId)) {
            res.success = false;
            res.message = 'To cancel I need the appointment id.';
            return res;
        }

        Appointment__c appt = new Appointment__c(
            Id = req.appointmentId,
            Status__c = 'Cancelled'
        );
        update appt;

        res.success = true;
        res.appointmentId = appt.Id;
        res.message = 'Your appointment has been cancelled.';
        return res;
    }
}
