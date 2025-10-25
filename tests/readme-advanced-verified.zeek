# Define structure matching your database fields
type ThreatData: record {
    category: string &optional;
    threat_level: string &optional;
    description: string &optional;
};

event zeek_init() {
    Matchy::load_database("test", "test.mxy");
    
    # Simulate connection_new with a known threat IP
    local result = Matchy::query_ip("test", 1.2.3.4);
    
    if (result != "") {
        print "Testing advanced example with JSON parsing...";
        
        # Parse JSON result into typed record
        local parsed = from_json(result, ThreatData);
        
        if (parsed$valid) {
            local threat: ThreatData = parsed$v;
            
            print fmt("PASS: Parsed threat - %s (%s)", 
                     threat$category, threat$threat_level);
                     
            # Would generate NOTICE in production:
            # NOTICE([$note=Threat_Detected,
            #         $msg=fmt(...),
            #         $sub=fmt("IP: %s", 1.2.3.4)]);
        } else {
            print "FAIL: JSON parsing failed";
        }
    }
    
    Matchy::unload_database("test");
}
