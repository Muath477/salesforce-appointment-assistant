@isTest
private class ManageAppointmentActionTest {

    // Small helper so each test reads as the scenario it is testing rather than
    // as list-wrapping boilerplate.
    private static ManageAppointmentAction.Result runOne(ManageAppointmentAction.Request req) {
        return ManageAppointmentAction.run(
            new List<ManageAppointmentAction.Request>{ req }
        )[0];
    }

    @isTest
    static void createsAnAppointment() {
        Contact c = new Contact(LastName = 'Agent Test');
        insert c;

        ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
        req.action = 'create';
        req.contactId = c.Id;
        req.appointmentDateTime = System.now().addDays(3);
        req.serviceType = 'Support';

        Test.startTest();
        ManageAppointmentAction.Result result = runOne(req);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Create should succeed');
        System.assertNotEquals(null, result.appointmentId);

        Appointment__c saved = [
            SELECT Status__c, Service_Type__c FROM Appointment__c
            WHERE Id = :result.appointmentId
        ];
        System.assertEquals('Scheduled', saved.Status__c);
        System.assertEquals('Support', saved.Service_Type__c);
    }

    @isTest
    static void createDefaultsServiceTypeWhenOmitted() {
        Contact c = new Contact(LastName = 'Default Service');
        insert c;

        ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
        req.action = 'create';
        req.contactId = c.Id;
        req.appointmentDateTime = System.now().addDays(2);

        Test.startTest();
        ManageAppointmentAction.Result result = runOne(req);
        Test.stopTest();

        System.assertEquals(true, result.success);
        Appointment__c saved = [
            SELECT Service_Type__c FROM Appointment__c WHERE Id = :result.appointmentId
        ];
        System.assertEquals('Consultation', saved.Service_Type__c,
            'A missing service type should fall back to Consultation');
    }

    @isTest
    static void reschedulesAndCancels() {
        Contact c = new Contact(LastName = 'Agent Test 2');
        insert c;
        Appointment__c appt = new Appointment__c(
            Contact__c = c.Id,
            Appointment_Date_Time__c = System.now().addDays(1),
            Status__c = 'Scheduled',
            Service_Type__c = 'Consultation'
        );
        insert appt;

        ManageAppointmentAction.Request reschedule = new ManageAppointmentAction.Request();
        reschedule.action = 'reschedule';
        reschedule.appointmentId = appt.Id;
        reschedule.appointmentDateTime = System.now().addDays(5);

        ManageAppointmentAction.Request cancel = new ManageAppointmentAction.Request();
        cancel.action = 'cancel';
        cancel.appointmentId = appt.Id;

        Test.startTest();
        runOne(reschedule);
        Appointment__c afterReschedule = [SELECT Status__c FROM Appointment__c WHERE Id = :appt.Id];

        runOne(cancel);
        Appointment__c afterCancel = [SELECT Status__c FROM Appointment__c WHERE Id = :appt.Id];
        Test.stopTest();

        System.assertEquals('Rescheduled', afterReschedule.Status__c);
        System.assertEquals('Cancelled', afterCancel.Status__c);
    }

    @isTest
    static void listReturnsUpcomingAppointmentsForContact() {
        Contact c = new Contact(LastName = 'Lookup Customer');
        insert c;
        insert new List<Appointment__c>{
            new Appointment__c(Contact__c = c.Id, Appointment_Date_Time__c = System.now().addDays(4),
                Status__c = 'Scheduled', Service_Type__c = 'Consultation'),
            // Cancelled -> must not be offered back to the customer
            new Appointment__c(Contact__c = c.Id, Appointment_Date_Time__c = System.now().addDays(6),
                Status__c = 'Cancelled', Service_Type__c = 'Support')
        };

        ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
        req.action = 'list';
        req.contactId = c.Id;

        Test.startTest();
        ManageAppointmentAction.Result result = runOne(req);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assert(result.message.contains('1 upcoming appointment'),
            'Only the non-cancelled appointment should be counted: ' + result.message);
        System.assertNotEquals(null, result.appointmentId,
            'The soonest appointment Id is returned so the agent can act on it next');
    }

    @isTest
    static void listWithNoAppointmentsIsHandled() {
        Contact c = new Contact(LastName = 'Empty Customer');
        insert c;

        ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
        req.action = 'list';
        req.contactId = c.Id;

        Test.startTest();
        ManageAppointmentAction.Result result = runOne(req);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assert(result.message.contains('no upcoming appointments'));
    }

    @isTest
    static void pastDateIsRejected() {
        Contact c = new Contact(LastName = 'Time Traveller');
        insert c;

        ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
        req.action = 'create';
        req.contactId = c.Id;
        req.appointmentDateTime = System.now().addDays(-1);

        Test.startTest();
        ManageAppointmentAction.Result result = runOne(req);
        Test.stopTest();

        System.assertEquals(false, result.success, 'A past date must not be booked');
        System.assert(result.message.contains('past'));
    }

    @isTest
    static void missingInputsReturnFriendlyMessages() {
        ManageAppointmentAction.Request create = new ManageAppointmentAction.Request();
        create.action = 'create';

        ManageAppointmentAction.Request reschedule = new ManageAppointmentAction.Request();
        reschedule.action = 'reschedule';

        ManageAppointmentAction.Request cancel = new ManageAppointmentAction.Request();
        cancel.action = 'cancel';

        ManageAppointmentAction.Request list = new ManageAppointmentAction.Request();
        list.action = 'list';

        Test.startTest();
        List<ManageAppointmentAction.Result> results = ManageAppointmentAction.run(
            new List<ManageAppointmentAction.Request>{ create, reschedule, cancel, list }
        );
        Test.stopTest();

        // Bulkification: four requests in, four results out, in the same order.
        System.assertEquals(4, results.size());
        for (ManageAppointmentAction.Result r : results) {
            System.assertEquals(false, r.success);
            System.assertNotEquals(null, r.message, 'Every failure explains what is missing');
        }
    }

    @isTest
    static void unknownActionReturnsMessage() {
        ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
        req.action = 'teleport';

        Test.startTest();
        ManageAppointmentAction.Result result = runOne(req);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assert(result.message.contains('Unknown action'));
    }

    @isTest
    static void nullActionIsHandled() {
        ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
        req.action = null;

        Test.startTest();
        ManageAppointmentAction.Result result = runOne(req);
        Test.stopTest();

        System.assertEquals(false, result.success, 'A null action must not throw');
    }
}
