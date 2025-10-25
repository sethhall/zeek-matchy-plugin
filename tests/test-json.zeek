type ThreatData: record {
    category: string &optional;
    threat_level: string &optional;
    description: string &optional;
};

event zeek_init() {
    # Load actual test database
    if (!Matchy::load_database("test", "test.mxy")) {
        print "Failed to load database!";
        return;
    }
    
    print "Testing JSON parsing with Matchy results...";
    
    # Get actual result from Matchy
    local result = Matchy::query_ip("test", 1.2.3.4);
    
    if ( result != "" ) {
        print "Raw JSON:", result;
        
        # Parse JSON into a record type
        local parsed = from_json(result, ThreatData);
        
        if ( parsed$valid ) {
            local threat: ThreatData = parsed$v;
            print "\nParsed threat data:";
            
            if ( threat?$category )
                print "  Category:", threat$category;
            
            if ( threat?$threat_level )
                print "  Threat level:", threat$threat_level;
                
            if ( threat?$description )
                print "  Description:", threat$description;
        } else {
            print "ERROR: Failed to parse JSON:", parsed$err;
        }
    }
    
    Matchy::unload_database("test");
}
