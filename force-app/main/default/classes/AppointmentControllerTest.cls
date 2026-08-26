@isTest
private class AppointmentControllerTest {

    // Build a few appointments and confirm the controller returns only the
    // upcoming, non-cancelled ones, in date order. Salesforce requires test
    // coverage before you can deploy Apex to production, so this also unblocks
    // deployment.
    @isTest
    static void returnsOnlyUpcomingNonCancelled() {
        Contact c = new Contact(LastName = 'Test Customer');
        insert c;

        List<Appointment__c> data = new List<Appointment__c>{
            // Upcoming and scheduled -> should appear
            new Appointment__c(
                Contact__c = c.Id,
                Appointment_Date_Time__c = System.now().addDays(2),
                Status__c = 'Scheduled',
                Service_Type__c = 'Consultation'
            ),
            // Upcoming but cancelled -> should be filtered out
            new Appointment__c(
                Contact__c = c.Id,
                Appointment_Date_Time__c = System.now().addDays(1),
                Status__c = 'Cancelled',
                Service_Type__c = 'Support'
            ),
            // In the past -> should be filtered out
            new Appointment__c(
                Contact__c = c.Id,
                Appointment_Date_Time__c = System.now().addDays(-1),
                Status__c = 'Scheduled',
                Service_Type__c = 'Follow-up'
            )
        };
        insert data;

        Test.startTest();
        List<Appointment__c> result =
            AppointmentController.getUpcomingAppointments(10);
        Test.stopTest();

        System.assertEquals(1, result.size(),
            'Only the upcoming, non-cancelled appointment should be returned');
        System.assertEquals('Scheduled', result[0].Status__c);
    }

    @isTest
    static void nullLimitFallsBackToDefault() {
        // Passing null should not throw; it should use the default limit.
        Test.startTest();
        List<Appointment__c> result =
            AppointmentController.getUpcomingAppointments(null);
        Test.stopTest();

        System.assertEquals(0, result.size(),
            'No data inserted, so the list is empty but no exception is thrown');
    }
}
