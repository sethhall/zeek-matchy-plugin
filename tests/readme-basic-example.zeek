# Test the basic example from README
event zeek_init() {
    # Load the database
    if (!Matchy::load_database("test", "test.mxy")) {
        print "Failed to load database!";
        return;
    }
    
    print "Database loaded successfully";
    
    # Simulate what would happen in connection_new
    local result = Matchy::query_ip("test", 1.2.3.4);
    if (result != "") {
        print fmt("Threat detected from %s: %s", 1.2.3.4, result);
    }
    
    # Simulate what would happen in dns_request
    local domain_result = Matchy::query_string("test", "malware.example.com");
    if (domain_result != "") {
        print fmt("Malicious domain queried: %s - %s", "malware.example.com", domain_result);
    }
    
    # Clean up
    Matchy::unload_database("test");
    print "Test complete";
}
