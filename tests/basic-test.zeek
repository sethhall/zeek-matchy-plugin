@load Matchy/DB

event zeek_init() {
    print "=== Matchy Plugin Basic Test ===";
    
    # Load database
    print "\n1. Loading database...";
    local loaded = Matchy::load_database("test", "test.mxy");
    if (!loaded) {
        print "FAIL: Could not load database";
        return;
    }
    print "PASS: Database loaded successfully";
    
    # Test 1: Query exact IP match
    print "\n2. Testing exact IP match (1.2.3.4)...";
    local result1 = Matchy::query_ip("test", 1.2.3.4);
    if (result1 == "") {
        print "FAIL: Expected match for 1.2.3.4";
    } else {
        print "PASS: Found match:", result1;
    }
    
    # Test 2: Query IP in CIDR range
    print "\n3. Testing CIDR match (10.0.0.5 in 10.0.0.0/8)...";
    local result2 = Matchy::query_ip("test", 10.0.0.5);
    if (result2 == "") {
        print "FAIL: Expected match for 10.0.0.5";
    } else {
        print "PASS: Found match:", result2;
    }
    
    # Test 3: Query IP not in database
    print "\n4. Testing no match (8.8.8.8)...";
    local result3 = Matchy::query_ip("test", 8.8.8.8);
    if (result3 != "") {
        print "FAIL: Should not match 8.8.8.8";
    } else {
        print "PASS: No match as expected";
    }
    
    # Test 4: Query exact string match
    print "\n5. Testing exact string match (malware.example.com)...";
    local result4 = Matchy::query_string("test", "malware.example.com");
    if (result4 == "") {
        print "FAIL: Expected match for malware.example.com";
    } else {
        print "PASS: Found match:", result4;
    }
    
    # Test 5: Query pattern match
    print "\n6. Testing pattern match (sub.evil.com matches *.evil.com)...";
    local result5 = Matchy::query_string("test", "sub.evil.com");
    if (result5 == "") {
        print "FAIL: Expected match for sub.evil.com";
    } else {
        print "PASS: Found match:", result5;
    }
    
    # Test 6: Query string not in database
    print "\n7. Testing no string match (google.com)...";
    local result6 = Matchy::query_string("test", "google.com");
    if (result6 != "") {
        print "FAIL: Should not match google.com";
    } else {
        print "PASS: No match as expected";
    }
    
    # Test 7: Query non-existent database
    print "\n8. Testing query on non-existent database...";
    local result7 = Matchy::query_ip("nonexistent", 1.2.3.4);
    if (result7 != "") {
        print "FAIL: Should not return results for non-existent database";
    } else {
        print "PASS: No match for non-existent database (check for warning above)";
    }
    
    # Test 8: Unload database
    print "\n9. Unloading database...";
    local unloaded = Matchy::unload_database("test");
    if (!unloaded) {
        print "FAIL: Could not unload database";
    } else {
        print "PASS: Database unloaded successfully";
    }
    
    # Test 9: Query after unload
    print "\n10. Testing query after unload...";
    local result8 = Matchy::query_ip("test", 1.2.3.4);
    if (result8 != "") {
        print "FAIL: Should not return results after unload";
    } else {
        print "PASS: No match after unload (check for warning above)";
    }
    
    print "\n=== Test Complete ===";
}
