public with sharing class AppointmentController {

    // Returns upcoming, non-cancelled appointments ordered by date so the
    // soonest one shows first. `cacheable=true` lets the LWC pull this with the
    // @wire adapter and get automatic caching/refresh on the client.
    @AuraEnabled(cacheable=true)
    public static List<Appointment__c> getUpcomingAppointments(Integer maxRows) {
        // Guard the boundary: the component may pass null, so fall back to a
        // sensible default instead of letting the SOQL LIMIT blow up.
        Integer rowLimit = (maxRows == null || maxRows <= 0) ? 5 : maxRows;

        // WITH SECURITY_ENFORCED makes the query respect the running user's
        // field- and object-level security. If they can't see a field, the
        // query fails loudly rather than leaking data.
        return [
            SELECT Id, Name, Appointment_Date_Time__c, Status__c,
                   Service_Type__c, Contact__r.Name
            FROM Appointment__c
            WHERE Appointment_Date_Time__c >= :System.now()
              AND Status__c != 'Cancelled'
            WITH SECURITY_ENFORCED
            ORDER BY Appointment_Date_Time__c ASC
            LIMIT :rowLimit
        ];
    }
}
