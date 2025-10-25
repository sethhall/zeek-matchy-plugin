# Zeek Matchy Plugin Tests

## Running Tests

### Quick Test

```bash
cd tests
ZEEK_PLUGIN_PATH=../build zeek simple-test.zeek
```

Expected output: All tests should PASS

### Building Test Database

The test database is pre-built, but you can rebuild it:

```bash
cd tests
../../matchy/target/release/matchy build test-data.csv -o test.mxy --format csv
```

## Test Coverage

The `simple-test.zeek` script tests:

1. **Loading database** - Loads test.mxy successfully
2. **Exact IP match** - Queries 1.2.3.4 (exact match)
3. **CIDR match** - Queries 10.0.0.5 (matches 10.0.0.0/8)
4. **Exact string match** - Queries malware.example.com
5. **Pattern match** - Queries sub.evil.com (matches *.evil.com)
6. **No match** - Queries google.com (not in database)
7. **Unloading database** - Cleans up resources

## Test Data

`test-data.csv` contains:

| Type | Entry | Data |
|------|-------|------|
| IP | 1.2.3.4 | threat_level=high, category=malware |
| CIDR | 10.0.0.0/8 | threat_level=low, category=internal |
| CIDR | 192.168.1.0/24 | threat_level=medium, category=suspicious |
| Pattern | *.evil.com | threat_level=critical, category=phishing |
| String | malware.example.com | threat_level=high, category=malware |
| String | test.local | threat_level=low, category=test |

## Expected Results

All queries should return JSON objects with the associated metadata:

```json
{"category":"malware","threat_level":"high","description":"Known C2 server"}
```

Non-matching queries return empty strings `""`.
