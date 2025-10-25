# Zeek Matchy Plugin

[![License](https://img.shields.io/badge/license-BSD--2-blue.svg)](LICENSE)
[![Zeek](https://img.shields.io/badge/zeek-5.0%2B-green.svg)](https://zeek.org)

A Zeek plugin for high-performance IP address and string pattern matching using [Matchy](https://github.com/sethhall/matchy) databases.

**Quick start:** See [QUICKSTART.md](QUICKSTART.md) for a 5-minute setup guide.

---

## Table of Contents
- [Why Matchy?](#why-matchy)
- [Installation](#installation)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Why Matchy?

Matchy brings several advantages over traditional threat intelligence approaches in Zeek:

### Memory Efficiency on Clusters
- **Shared memory across workers**: Databases are memory-mapped, so all Zeek workers on a host share the same physical memory
- **Zero heap memory per-process**: Unlike the Intel Framework which loads data into each worker's heap, Matchy uses the OS page cache
- **Massive scale**: On a 32-core cluster, this can save gigabytes of RAM compared to per-worker copies

### Operational Flexibility  
- **Hot-reloadable**: Databases open in <1ms, so you can close and reopen them at runtime during updates—no Zeek restart needed
- **No libmaxminddb dependency**: Load and query MaxMind GeoIP databases directly—one less C library to manage
- **Build databases offline**: Use the `matchy` CLI in CI/CD pipelines to build databases from any source (CSV, JSON, APIs)
- **Simple distribution**: Just copy `.mxy` files to your cluster—no Broker setup or Intel Framework synchronization

### Performance
- **7M+ IP queries/second**: Memory-mapped lookups with zero-copy access
- **3M+ pattern queries/second**: Efficient glob matching (`*.evil.com`)
- **Deterministic performance**: No GC pauses or unpredictable slowdowns (Rust + mmap)
- **Single unified API**: Query IPs, CIDRs, exact strings, and wildcards through one interface

### Developer Experience
- **Easy debugging**: Query `.mxy` files directly with the `matchy` CLI—no need to inspect Zeek's internal state
- **Type-safe with metadata**: Queries return structured JSON with arbitrary fields, not just boolean matches
- **Version control friendly**: Keep source CSVs in git, build binary databases in CI
- **Cross-platform**: Same `.mxy` file works on Linux, macOS, and BSD

Matchy excels at **read-heavy workloads** with infrequent updates (typical threat intel scenarios). For dynamic, frequently-changing data with complex sharing across clusters, Zeek's Intel Framework is still the better choice.

## Installation

**TL;DR:** See [QUICKSTART.md](QUICKSTART.md) for the fastest setup path.

### Requirements

- **Zeek 5.0 or later**
- **Matchy library** (see installation below)
- **CMake 3.15 or later**
- **C++17 compiler**
- **Rust 1.70+** (for building Matchy)

### Step-by-Step Installation

#### 1. Install Rust (if not already installed)

Matchy is written in Rust, so you'll need the Rust toolchain:

```bash
# Install Rust using rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Follow the prompts, then reload your shell
source $HOME/.cargo/env

# Verify installation
rustc --version
cargo --version
```

Or visit [rustup.rs](https://rustup.rs/) for more installation options.

#### 2. Install Matchy

Clone and build the Matchy library with C API support:

```bash
# Clone Matchy
git clone https://github.com/sethhall/matchy.git
cd matchy

# Build with C API (capi feature required for Zeek plugin)
cargo build --release --features capi

# Install the CLI tool (optional but recommended)
cargo install --path .

# Verify matchy CLI is available
matchy --version
```

**Option A: System-wide installation**

```bash
# Install C library and headers to standard location
sudo cp target/release/libmatchy.a /usr/local/lib/
sudo cp target/release/libmatchy.dylib /usr/local/lib/  # macOS
sudo cp target/release/libmatchy.so /usr/local/lib/     # Linux
sudo cp -r include/matchy /usr/local/include/
```

**Option B: Use MATCHY_ROOT** (easier, no sudo required)

Just set the `MATCHY_ROOT` environment variable when building the plugin:

```bash
export MATCHY_ROOT=/path/to/matchy
```

#### 3. Build the Zeek Plugin

```bash
cd /path/to/zeek-matchy
mkdir build && cd build

# Configure - CMake will find Matchy via MATCHY_ROOT or system paths
MATCHY_ROOT=/path/to/matchy cmake -DCMAKE_MODULE_PATH=$(zeek-config --cmake_dir) ..

# Build
make

# Test
cd ../tests
ZEEK_PLUGIN_PATH=../build zeek simple-test.zeek

# Install (optional)
cd ../build
sudo make install
```

#### 4. Verify Installation

Check that Zeek can see the plugin:

```bash
# If using ZEEK_PLUGIN_PATH
export ZEEK_PLUGIN_PATH=/path/to/zeek-matchy/build
zeek -N Matchy::DB

# If installed system-wide
zeek -N Matchy::DB
```

Expected output:
```
Matchy::DB - Fast IP and pattern matching using Matchy databases (dynamic, version 0.1.0)
```

Functions are automatically available in the `Matchy::` namespace:
- `Matchy::load_database(name, file)`
- `Matchy::query_ip(name, ip)` 
- `Matchy::query_string(name, string)`
- `Matchy::unload_database(name)`

## Usage

### Creating a Matchy Database

First, create a database using the Matchy CLI:

```bash
# Create a CSV file with threat indicators
cat > threats.csv << EOF
entry,threat_level,category,description
1.2.3.4,high,malware,Known C2 server
10.0.0.0/8,low,internal,RFC1918 private network
*.evil.com,critical,phishing,Phishing domain pattern
malware.example.com,high,malware,Malware distribution site
EOF

# Build the database
matchy build threats.csv -o threats.mxy --format csv
```

### Basic Zeek Script

```zeek
event zeek_init() {
    # Load the database
    if (!Matchy::load_database("threats", "/path/to/threats.mxy")) {
        print "Failed to load database!";
        return;
    }
    
    print "Database loaded successfully";
}

event connection_new(c: connection) {
    # Query the originator IP
    local result = Matchy::query_ip("threats", c$id$orig_h);
    
    if (result != "") {
        print fmt("Threat detected from %s: %s", c$id$orig_h, result);
        # Result is JSON - parse with to_json_string() or parseJSON()
    }
}

event dns_request(c: connection, msg: dns_msg, query: string, qtype: count, qclass: count) {
    # Query domain name
    local result = Matchy::query_string("threats", query);
    
    if (result != "") {
        print fmt("Malicious domain queried: %s - %s", query, result);
    }
}

event zeek_done() {
    # Clean up
    Matchy::unload_database("threats");
}
```

### Advanced Example with JSON Parsing

```zeek
@load base/frameworks/notice

module ThreatIntel;

export {
    redef enum Notice::Type += {
        Threat_Detected
    };
}

event zeek_init() {
    Matchy::load_database("threats", "/opt/threat-intel/threats.mxy");
}

event connection_new(c: connection) {
    local result = Matchy::query_ip("threats", c$id$orig_h);
    
    if (result != "") {
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
            
            NOTICE([$note=Threat_Detected,
                    $conn=c,
                    $msg=fmt("Threat: %s (%s)", category, threat_level),
                    $sub=fmt("IP: %s", c$id$orig_h)]);
        }
    }
}
```

## API Reference

### `load_database(db_name: string, filename: string): bool`

Load a Matchy database from file.

- **db_name**: Unique identifier for this database instance
- **filename**: Path to the `.mxy` database file
- **Returns**: `T` on success, `F` on failure

### `query_ip(db_name: string, ip: addr): string`

Query the database by IP address.

- **db_name**: Name of the loaded database
- **ip**: IP address to query
- **Returns**: JSON string with match data, or empty string if no match

### `query_string(db_name: string, query: string): string`

Query the database by string (exact match or pattern).

- **db_name**: Name of the loaded database  
- **query**: String to query (domain, exact string, or pattern)
- **Returns**: JSON string with match data, or empty string if no match

### `unload_database(db_name: string): bool`

Unload a database and free its resources.

- **db_name**: Name of the database to unload
- **Returns**: `T` on success, `F` if database not found

## Testing

The plugin includes comprehensive tests:

```bash
cd tests
ZEEK_PLUGIN_PATH=../build zeek simple-test.zeek
```

All tests should PASS. See [tests/README.md](tests/README.md) for details.

Example test script:

```zeek
event zeek_init() {
    if (Matchy::load_database("test", "test.mxy")) {
        # Test IP query
        local ip_result = Matchy::query_ip("test", 1.2.3.4);
        if (ip_result != "") {
            print "Match:", ip_result;
            # Output: {"category":"malware","threat_level":"high",...}
        }
        
        # Test pattern query  
        local pattern_result = Matchy::query_string("test", "sub.evil.com");
        if (pattern_result != "") {
            print "Match:", pattern_result;
            # Output: {"category":"phishing","threat_level":"critical",...}
        }
        
        Matchy::unload_database("test");
    }
}
```

## Troubleshooting

For detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

Common issues:

**Build fails with "Matchy library not found":**
- Make sure you built Matchy with `cargo build --release --features capi`
- Set `MATCHY_ROOT` environment variable when running cmake

**Plugin not found at runtime:**
- Set `ZEEK_PLUGIN_PATH` or install with `sudo make install`
- Verify with `zeek -N Matchy::DB`

**Library loading issues (macOS):**
```bash
export DYLD_LIBRARY_PATH=/path/to/matchy/target/release:$DYLD_LIBRARY_PATH
```

**Database won't load:**
- Verify with `matchy validate database.mxy`
- Use absolute paths in Zeek scripts
- Check file permissions

## License

BSD-2-Clause License. See [LICENSE](LICENSE) file.

## Contributing

Issues and pull requests welcome at https://github.com/sethhall/zeek-matchy-plugin

## See Also

- [Matchy](https://github.com/sethhall/matchy) - The underlying database library
- [Zeek Documentation](https://docs.zeek.org/) - Zeek network security monitor
- [Zeek Plugin Development](https://docs.zeek.org/en/master/devel/plugins.html) - Plugin API docs
