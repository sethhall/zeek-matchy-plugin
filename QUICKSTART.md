# Quick Start Guide

Get up and running with the Zeek Matchy plugin in 5 minutes.

## Prerequisites

- Zeek 5.0+
- Matchy library installed (requires Rust 1.70+)
- CMake 3.15+

If you haven't installed Matchy yet, see [README.md](README.md#installation) for detailed instructions.

## 1. Build the Plugin

```bash
cd /path/to/zeek-matchy
mkdir build && cd build

# Option A: If Matchy is installed system-wide
cmake -DCMAKE_MODULE_PATH=$(zeek-config --cmake_dir) ..

# Option B: If using MATCHY_ROOT (most common during development)
MATCHY_ROOT=/path/to/matchy \
  cmake -DCMAKE_MODULE_PATH=$(zeek-config --cmake_dir) ..

make
```

## 2. Test It

```bash
cd ../tests
ZEEK_PLUGIN_PATH=../build zeek simple-test.zeek
```

You should see all tests PASS.

## 3. Create a Database

```bash
# Create a CSV file with your data
cat > threats.csv << 'EOF'
entry,category,threat_level
1.2.3.4,malware,critical
10.0.0.0/8,internal,low
*.evil.com,phishing,high
EOF

# Build the database
matchy build threats.csv -o threats.mxy --format csv
```

## 4. Use in Zeek

```zeek
event zeek_init() {
    Matchy::load_database("threats", "threats.mxy");
}

event connection_new(c: connection) {
    local result = Matchy::query_ip("threats", c$id$orig_h);
    if (result != "") {
        print fmt("Threat detected: %s from %s", result, c$id$orig_h);
    }
}

event dns_request(c: connection, msg: dns_msg, query: string, qtype: count, qclass: count) {
    local result = Matchy::query_string("threats", query);
    if (result != "") {
        print fmt("Malicious domain: %s - %s", query, result);
    }
}
```

Run with:
```bash
export ZEEK_PLUGIN_PATH=/path/to/zeek-matchy/build
zeek -i eth0 your-script.zeek
```

## 5. Install (Optional)

To install permanently:

```bash
cd build
sudo make install
```

Then you can use it without `ZEEK_PLUGIN_PATH`:

```bash
zeek -N Matchy::DB  # Should show the plugin
```

## API Summary

| Function | Purpose |
|----------|---------|
| `Matchy::load_database(name, file)` | Load a .mxy database |
| `Matchy::query_ip(name, ip)` | Query by IP address |
| `Matchy::query_string(name, str)` | Query by string/pattern |
| `Matchy::unload_database(name)` | Unload and free memory |

All query functions return:
- **JSON string** with match data if found
- **Empty string `""`** if no match or error

See [README.md](README.md) for full documentation.
