##! Matchy plugin for Zeek - Fast IP and pattern matching
##!
##! This module provides integration with the Matchy database for high-performance
##! IP address and string pattern matching. Matchy databases support:
##!   - IP addresses and CIDR ranges
##!   - Exact string matching
##!   - Glob pattern matching (*.example.com, etc.)
##!
##! Example usage:
##!   # Load a threat intelligence database
##!   Matchy::load_database("threats", "/path/to/threats.mxy");
##!   
##!   # Query by IP
##!   local ip_result = Matchy::query_ip("threats", 1.2.3.4);
##!   if (ip_result != "") {
##!       # Parse JSON result
##!       print "Match found:", ip_result;
##!   }
##!   
##!   # Query by string/domain
##!   local str_result = Matchy::query_string("threats", "evil.example.com");
##!   if (str_result != "") {
##!       print "Match found:", str_result;
##!   }
##!   
##!   # Unload when done
##!   Matchy::unload_database("threats");

module Matchy;

# The BiFs are automatically exported by the plugin.
# No need to redeclare them here.
