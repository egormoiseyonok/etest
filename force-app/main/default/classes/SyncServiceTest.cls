
@isTest
public class SyncServiceTest {
    
    // Test data setup for Leads
    private static List<Lead> createTestLeads() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(FirstName='FirstName' + i, LastName='LastName' + i, Email='test' + i + '@example.com', Company='TestCo', Status='Open'));
        }
        insert leads;
        return leads;
    }
    
    // Test data setup for Contacts
    private static List<Contact> createTestContacts() {
        Account account = new Account(Name='TestAccount');
        insert account;
        
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(FirstName='FirstName' + i, LastName='LastName' + i, Email='test' + i + '@example.com', AccountId=account.Id));
        }
        insert contacts;
        return contacts;
    }
    
    // Test data setup for Opportunities
    private static List<Opportunity> createTestOpportunities() {
        Account account = new Account(Name='TestAccount');
        insert account;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opportunities.add(new Opportunity(Name='Opportunity' + i, StageName='Prospecting', CloseDate=Date.today().addDays(30), AccountId=account.Id));
        }
        insert opportunities;
        return opportunities;
    }

    // Mocking HTTP response for callPostgreSQLAPI method
    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true, "recordsProcessed": 5}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    /**
     * Test method for SyncService.syncToPostgreSQL covering positive scenario
     */
    @isTest
    static void testSyncToPostgreSQLSuccess() {
        // Setup
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        List<Lead> leads = createTestLeads();
        
        Test.startTest();
        // Call the method and assert
        SyncService.SyncResult result = SyncService.syncToPostgreSQL(SyncService.ObjectType.LEAD, new List<Id>{leads[0].Id, leads[1].Id});
        Test.stopTest();
        
        // Verify results
        System.assertEquals('SUCCESS', result.logEntries[result.logEntries.size() - 1].level);
        System.assertEquals(true, result.success);
        System.assertEquals(5, result.recordsProcessed);
    }
    
    /**
     * Test method for SyncService.syncToPostgreSQL with no records to sync
     */
    @isTest
    static void testSyncToPostgreSQLNoRecords() {
        // Setup
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        // Call the method and assert
        SyncService.SyncResult result = SyncService.syncToPostgreSQL(SyncService.ObjectType.LEAD, new List<Id>());
        Test.stopTest();
        
        // Verify results
        System.assertEquals('INFO', result.logEntries[result.logEntries.size() - 1].level);
        System.assertEquals(true, result.success);
        System.assertEquals('Нет записей для синхронизации', result.message);
    }
    
    /**
     * Test method for SyncService.syncFromPostgreSQL covering positive scenario
     */
    @isTest
    static void testSyncFromPostgreSQLSuccess() {
        // Setup
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        // Call the method and assert
        SyncService.SyncResult result = SyncService.syncFromPostgreSQL(SyncService.ObjectType.LEAD, new Map<String, Object>());
        Test.stopTest();
        
        // Verify results
        System.assertEquals('SUCCESS', result.logEntries[result.logEntries.size() - 1].level);
        System.assertEquals(true, result.success);
        System.assertEquals(5, result.recordsProcessed);
    }
    
    /**
     * Test method for SyncService.syncFromPostgreSQL with HTTP error code
     */
    @isTest
    static void testSyncFromPostgreSQLHttpError() {
        // Mocking HTTP response for error
        class MockHttpErrorResponse implements HttpCalloutMock {
            public HttpResponse respond(HttpRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setStatusCode(500);
                return res;
            }
        }
        
        // Setup
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponse());
        
        Test.startTest();
        // Call the method and assert
        SyncService.SyncResult result = SyncService.syncFromPostgreSQL(SyncService.ObjectType.LEAD, new Map<String, Object>());
        Test.stopTest();
        
        // Verify results
        System.assertEquals('ERROR', result.logEntries[result.logEntries.size() - 1].level);
        System.assertEquals(false, result.success);
        System.assertEquals('HTTP 500', result.message);
    }
    
    /**
     * Test method for SyncService.syncBidirectional covering positive scenario
     */
    @isTest
    static void testSyncBidirectionalSuccess() {
        // Setup
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        List<Contact> contacts = createTestContacts();
        
        Test.startTest();
        // Call the method and assert
        SyncService.SyncResult result = SyncService.syncBidirectional(SyncService.ObjectType.CONTACT, new List<Id>{contacts[0].Id, contacts[1].Id}, new Map<String, Object>());
        Test.stopTest();
        
        // Verify results
        System.assertEquals('SUCCESS', result.logEntries[result.logEntries.size() - 1].level);
        System.assertEquals(true, result.success);
    }
    
}
