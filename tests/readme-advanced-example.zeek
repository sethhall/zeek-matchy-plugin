@load base/frameworks/notice

module ThreatIntel;

export {
    redef enum Notice::Type += {
        Threat_Detected
    };
}

event zeek_init() {
    Matchy::load_database("test", "test.mxy");
    
    # Test the JSON parsing logic
    local result = Matchy::query_ip("test", 1.2.3.4);
    
    if (result != "") {
        print "Testing JSON parsing...";
        
        # Parse JSON result (Zeek 5.0+ has built-in JSON support)
        local data = parse_json(result);
        
        if (data is table) {
            local threat_level = "";
            local category = "";
            
            if ("threat_level" in data) {
                threat_level = data["threat_level"];
            }
            if ("category" in data) {
                category = data["category"];
            }
            
            print fmt("Parsed - Category: %s, Threat Level: %s", category, threat_level);
        } else {
            print "ERROR: parse_json did not return a table";
        }
    }
    
    Matchy::unload_database("test");
}
