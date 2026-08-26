@isTest
private class ManageAppointmentActionTest {

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
        List<ManageAppointmentAction.Result> results =
            ManageAppointmentAction.run(new List<ManageAppointmentAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assertNotEquals(null, results[0].appointmentId);

        Appointment__c saved = [
            SELECT Status__c, Service_Type__c FROM Appointment__c
            WHERE Id = :results[0].appointmentId
        ];
        System.assertEquals('Scheduled', saved.Status__c);
        System.assertEquals('Support', saved.Service_Type__c);
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
        ManageAppointmentAction.run(new List<ManageAppointmentAction.Request>{ reschedule });
        Appointment__c afterReschedule = [SELECT Status__c FROM Appointment__c WHERE Id = :appt.Id];

        ManageAppointmentAction.run(new List<ManageAppointmentAction.Request>{ cancel });
        Appointment__c afterCancel = [SELECT Status__c FROM Appointment__c WHERE Id = :appt.Id];
        Test.stopTest();

        System.assertEquals('Rescheduled', afterReschedule.Status__c);
        System.assertEquals('Cancelled', afterCancel.Status__c);
    }

    @isTest
    static void unknownActionReturnsMessage() {
        ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
        req.action = 'teleport';

        Test.startTest();
        List<ManageAppointmentAction.Result> results =
            ManageAppointmentAction.run(new List<ManageAppointmentAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.contains('Unknown action'));
    }
}
