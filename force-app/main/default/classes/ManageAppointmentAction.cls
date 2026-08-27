/**
 * Invocable action that creates, reschedules, cancels, or lists appointments.
 *
 * Because it is an @InvocableMethod, it can be called from an Agentforce agent
 * action, an autolaunched Flow, or a Screen Flow with no code changes. This is
 * the "agent ready" bridge described in the project docs: the conversational
 * agent interprets the customer's natural-language request, then hands the
 * structured values (action + details) to this method to do the actual work on
 * the record.
 *
 * Security: every SOQL query and DML statement runs in AccessLevel.USER_MODE,
 * so the platform enforces the running user's object- and field-level
 * permissions as well as sharing. A user without access gets a clean, handled
 * error message rather than an unauthorised write.
 */
public with sharing class ManageAppointmentAction {

    // The input wrapper. Each @InvocableVariable becomes a field the agent or
    // Flow maps values into.
    public class Request {
        @InvocableVariable(required=true label='Action (create, reschedule, cancel, list)')
        public String action;

        @InvocableVariable(label='Contact Id (for create and list)')
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
    @InvocableMethod(label='Manage Appointment' description='Create, reschedule, cancel, or list appointments')
    public static List<Result> run(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res;
            // Normalise so 'Create', 'CREATE', ' create ' all work the same.
            String action = (req.action == null) ? '' : req.action.trim().toLowerCase();

            try {
                if (action == 'create') {
                    res = createAppointment(req);
                } else if (action == 'reschedule') {
                    res = rescheduleAppointment(req);
                } else if (action == 'cancel') {
                    res = cancelAppointment(req);
                } else if (action == 'list') {
                    res = listAppointments(req);
                } else {
                    res = new Result();
                    res.success = false;
                    res.message = 'Unknown action "' + req.action +
                        '". Use create, reschedule, cancel, or list.';
                }
            } catch (Exception e) {
                // Catch here so one bad request returns a clean message to the
                // agent instead of failing the whole conversation. This also
                // catches the exception raised by USER_MODE when the running
                // user lacks permission on the object or one of its fields.
                res = new Result();
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
        if (req.appointmentDateTime < System.now()) {
            res.success = false;
            res.message = 'That date is in the past. Please choose a future date and time.';
            return res;
        }

        Appointment__c appt = new Appointment__c(
            Contact__c = req.contactId,
            Appointment_Date_Time__c = req.appointmentDateTime,
            Service_Type__c = String.isBlank(req.serviceType) ? 'Consultation' : req.serviceType,
            Status__c = 'Scheduled'
        );
        // USER_MODE makes the platform enforce CRUD and FLS on this insert.
        Database.insert(appt, AccessLevel.USER_MODE);

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
        if (req.appointmentDateTime < System.now()) {
            res.success = false;
            res.message = 'That date is in the past. Please choose a future date and time.';
            return res;
        }

        Appointment__c appt = new Appointment__c(
            Id = req.appointmentId,
            Appointment_Date_Time__c = req.appointmentDateTime,
            Status__c = 'Rescheduled'
        );
        Database.update(appt, AccessLevel.USER_MODE);

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
        Database.update(appt, AccessLevel.USER_MODE);

        res.success = true;
        res.appointmentId = appt.Id;
        res.message = 'Your appointment has been cancelled.';
        return res;
    }

    /**
     * Lets the agent answer "when is my appointment?" and work out which record
     * the customer means before rescheduling or cancelling it. Returns the
     * upcoming, non-cancelled appointments for the contact as a readable
     * sentence the agent can speak back verbatim - which is what keeps the
     * agent grounded in real record data instead of inventing details.
     */
    private static Result listAppointments(Request req) {
        Result res = new Result();
        if (String.isBlank(req.contactId)) {
            res.success = false;
            res.message = 'To look up appointments I need to know which customer.';
            return res;
        }

        List<Appointment__c> appts = [
            SELECT Id, Name, Appointment_Date_Time__c, Service_Type__c, Status__c
            FROM Appointment__c
            WHERE Contact__c = :req.contactId
              AND Appointment_Date_Time__c >= :System.now()
              AND Status__c != 'Cancelled'
            WITH USER_MODE
            ORDER BY Appointment_Date_Time__c ASC
            LIMIT 10
        ];

        res.success = true;
        if (appts.isEmpty()) {
            res.message = 'You have no upcoming appointments.';
            return res;
        }

        List<String> lines = new List<String>();
        for (Appointment__c a : appts) {
            lines.add(a.Name + ': ' + a.Service_Type__c + ' on ' +
                a.Appointment_Date_Time__c.format() + ' (' + a.Status__c + ')');
        }
        // The first (soonest) appointment is the one the customer most likely
        // means, so hand its Id back for a follow-up reschedule or cancel.
        res.appointmentId = appts[0].Id;
        res.message = 'You have ' + appts.size() +
            (appts.size() == 1 ? ' upcoming appointment. ' : ' upcoming appointments. ') +
            String.join(lines, ' ');
        return res;
    }
}
