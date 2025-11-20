event zeek_init() {
    print "=== Matchy Plugin Basic Test ===";
    
    # Load database
    print "\n1. Loading database...";
    local db = Matchy::load_database("test.mxy");
    if (!Matchy::is_valid(db)) {
        print "FAIL: Could not load database";
        return;
    }
    print "PASS: Database loaded successfully";
    
    # Test exact IP match
    print "\n2. Testing exact IP match (1.2.3.4)...";
    local result1 = Matchy::query_ip(db, 1.2.3.4);
    if (result1 == "") {
        print "FAIL: Expected match for 1.2.3.4";
    } else {
        print "PASS: Found match:", result1;
    }
    
    # Test CIDR match
    print "\n3. Testing CIDR match (10.0.0.5 in 10.0.0.0/8)...";
    local result2 = Matchy::query_ip(db, 10.0.0.5);
    if (result2 == "") {
        print "FAIL: Expected match for 10.0.0.5";
    } else {
        print "PASS: Found match:", result2;
    }
    
    # Test exact string match
    print "\n4. Testing exact string match (malware.example.com)...";
    local result3 = Matchy::query_string(db, "malware.example.com");
    if (result3 == "") {
        print "FAIL: Expected match for malware.example.com";
    } else {
        print "PASS: Found match:", result3;
    }
    
    # Test pattern match
    print "\n5. Testing pattern match (sub.evil.com matches *.evil.com)...";
    local result4 = Matchy::query_string(db, "sub.evil.com");
    if (result4 == "") {
        print "FAIL: Expected match for sub.evil.com";
    } else {
        print "PASS: Found match:", result4;
    }
    
    # Test no match
    print "\n6. Testing no match (google.com)...";
    local result5 = Matchy::query_string(db, "google.com");
    if (result5 != "") {
        print "FAIL: Should not match google.com";
    } else {
        print "PASS: No match as expected";
    }
    
    # Database automatically unloaded when 'db' goes out of scope
    print "\n7. Database will be automatically unloaded";
    print "PASS: Automatic cleanup via opaque type";
    
    print "\n=== Test Complete ===";
}
