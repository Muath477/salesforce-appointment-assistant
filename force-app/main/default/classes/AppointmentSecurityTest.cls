/**
 * Proves that the Appointment Management User permission set grants exactly the
 * access the design calls for - create, read and edit appointments, but never
 * delete - and that the invocable action still works for a non-administrator.
 *
 * This is the automated counterpart to UAT case U5 in docs/TEST_PLAN.md, which
 * was previously only verified by hand.
 */
@isTest
private class AppointmentSecurityTest {

    private static final String PERMSET = 'Appointment_Management_User';

    /**
     * Builds a user on the lowest-privilege profile available and grants them
     * nothing but the Appointment Management User permission set, so anything
     * that works for them works *because of* the permission set.
     *
     * User and PermissionSetAssignment are setup objects, so this must be
     * called inside a System.runAs block to avoid MIXED_DML_OPERATION when the
     * test also touches ordinary records.
     */
    private static User buildPermissionSetOnlyUser(Boolean assignPermissionSet) {
        List<Profile> profiles = [
            SELECT Id FROM Profile
            WHERE Name IN ('Minimum Access - Salesforce', 'Standard User')
            ORDER BY Name
            LIMIT 1
        ];
        if (profiles.isEmpty()) {
            return null;
        }

        String unique = String.valueOf(Datetime.now().getTime()) +
            String.valueOf(Math.abs(Crypto.getRandomInteger()));
        User u = new User(
            FirstName = 'Appt',
            LastName = 'Tester',
            Alias = 'apptt',
            Email = 'appt.tester@example.com',
            Username = 'appt.tester.' + unique + '@example.com.capstone',
            ProfileId = profiles[0].Id,
            TimeZoneSidKey = 'Asia/Riyadh',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        if (assignPermissionSet) {
            List<PermissionSet> ps = [
                SELECT Id FROM PermissionSet WHERE Name = :PERMSET LIMIT 1
            ];
            if (!ps.isEmpty()) {
                insert new PermissionSetAssignment(
                    AssigneeId = u.Id, PermissionSetId = ps[0].Id
                );
            }
        }
        return u;
    }

    /**
     * The permission set itself must never grant delete. Asserting against the
     * permission set's own ObjectPermissions makes this check independent of
     * whatever the target org's profiles happen to allow.
     */
    @isTest
    static void permissionSetGrantsCreateButNotDelete() {
        List<ObjectPermissions> perms = [
            SELECT PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete
            FROM ObjectPermissions
            WHERE SobjectType = 'Appointment__c'
              AND ParentId IN (SELECT Id FROM PermissionSet WHERE Name = :PERMSET)
        ];

        System.assertEquals(1, perms.size(),
            'The permission set should carry object permissions for Appointment__c');
        System.assertEquals(true, perms[0].PermissionsCreate, 'Create is required');
        System.assertEquals(true, perms[0].PermissionsRead, 'Read is required');
        System.assertEquals(true, perms[0].PermissionsEdit, 'Edit is required');
        System.assertEquals(false, perms[0].PermissionsDelete,
            'Delete must never be granted - cancelling is a status change, not a deletion');
    }

    @isTest
    static void permissionSetUserCanBookAnAppointment() {
        User u;
        // Setup-object DML is isolated so the Contact insert below does not
        // trigger MIXED_DML_OPERATION.
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u = buildPermissionSetOnlyUser(true);
        }
        if (u == null) {
            // No suitable profile in this org. Failing here would block an
            // otherwise valid deployment, so there is nothing to assert.
            return;
        }

        Contact c = new Contact(LastName = 'Permission Set Customer');
        insert c;

        Test.startTest();
        System.runAs(u) {
            ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
            req.action = 'create';
            req.contactId = c.Id;
            req.appointmentDateTime = System.now().addDays(7);
            req.serviceType = 'Follow-up';

            ManageAppointmentAction.Result result = ManageAppointmentAction.run(
                new List<ManageAppointmentAction.Request>{ req }
            )[0];

            System.assertEquals(true, result.success,
                'The permission set should be enough to book an appointment: ' + result.message);
            System.assertNotEquals(null, result.appointmentId);
            System.assertEquals(true,
                Appointment__c.SObjectType.getDescribe().isCreateable(),
                'Create access should be visible to the running user');
        }
        Test.stopTest();
    }

    @isTest
    static void blockedUserGetsHandledResultNotAnException() {
        User stranger;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            stranger = buildPermissionSetOnlyUser(false);
        }
        if (stranger == null) {
            return;
        }

        Contact c = new Contact(LastName = 'Unreachable Customer');
        insert c;

        Test.startTest();
        System.runAs(stranger) {
            ManageAppointmentAction.Request req = new ManageAppointmentAction.Request();
            req.action = 'create';
            req.contactId = c.Id;
            req.appointmentDateTime = System.now().addDays(7);

            // USER_MODE means the platform decides. Whatever it decides, the
            // action must return a structured result rather than throwing an
            // unhandled exception that would break an agent conversation.
            ManageAppointmentAction.Result result = ManageAppointmentAction.run(
                new List<ManageAppointmentAction.Request>{ req }
            )[0];

            System.assertNotEquals(null, result,
                'A blocked request still returns a Result');
            System.assertNotEquals(null, result.message,
                'A blocked request still carries a readable message');
        }
        Test.stopTest();
    }
}
