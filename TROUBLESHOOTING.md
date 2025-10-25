# Troubleshooting Guide

Common issues and solutions for building and using the Zeek Matchy plugin.

## Build Issues

### "Matchy library not found"

**Error:**
```
CMake Error at CMakeLists.txt:27 (message):
  Matchy library not found. Set MATCHY_ROOT environment variable or install matchy.
```

**Solutions:**

1. **Make sure you built Matchy with the C API:**
   ```bash
   cd /path/to/matchy
   cargo build --release --features capi
   ```
   
   The `--features capi` flag is **required**. Without it, the C library won't be built.

2. **Set MATCHY_ROOT when running cmake:**
   ```bash
   MATCHY_ROOT=/path/to/matchy cmake -DCMAKE_MODULE_PATH=$(zeek-config --cmake_dir) ..
   ```

3. **Check that the library files exist:**
   ```bash
   ls /path/to/matchy/target/release/libmatchy.*
   ```
   
   You should see:
   - `libmatchy.a` (static library)
   - `libmatchy.dylib` (macOS) or `libmatchy.so` (Linux)

4. **Check that headers exist:**
   ```bash
   ls /path/to/matchy/include/matchy/matchy.h
   ```

### "zeek-config not found"

**Error:**
```
zeek-config: command not found
```

**Solution:**

Make sure Zeek is installed and in your PATH:
```bash
which zeek
zeek --version
```

If Zeek is installed but not in PATH:
```bash
export PATH=/opt/zeek/bin:$PATH  # Adjust path as needed
```

### "ZeekPlugin.cmake not found"

**Error:**
```
CMake Error: include could not find requested file: ZeekPlugin.cmake
```

**Solution:**

Use `zeek-config --cmake_dir` to find the correct path:
```bash
cmake -DCMAKE_MODULE_PATH=$(zeek-config --cmake_dir) ..
```

## Runtime Issues

### "Plugin not found" or "can't find Matchy::DB"

**Error:**
```
error: plugin Matchy::DB is not available
```

**Solutions:**

1. **Set ZEEK_PLUGIN_PATH:**
   ```bash
   export ZEEK_PLUGIN_PATH=/path/to/zeek-matchy/build
   zeek -N Matchy::DB
   ```

2. **Install the plugin system-wide:**
   ```bash
   cd build
   sudo make install
   zeek -N Matchy::DB
   ```

3. **Verify the plugin built correctly:**
   ```bash
   ls build/lib/Matchy-DB.*.so
   ```

### "dyld: Library not loaded: libmatchy.dylib" (macOS)

**Error:**
```
dyld: Library not loaded: @rpath/libmatchy.dylib
```

**Solution:**

Set the dynamic library path:
```bash
export DYLD_LIBRARY_PATH=/path/to/matchy/target/release:$DYLD_LIBRARY_PATH
zeek your-script.zeek
```

Or use the static library by copying it to a standard location:
```bash
sudo cp /path/to/matchy/target/release/libmatchy.a /usr/local/lib/
```

### "Failed to open Matchy database"

**Error (in Zeek output):**
```
warning: Failed to open Matchy database: /path/to/db.mxy
```

**Solutions:**

1. **Check the file exists:**
   ```bash
   ls -la /path/to/db.mxy
   ```

2. **Verify it's a valid Matchy database:**
   ```bash
   matchy validate /path/to/db.mxy
   ```

3. **Check file permissions:**
   ```bash
   chmod 644 /path/to/db.mxy
   ```

4. **Use an absolute path in your Zeek script:**
   ```zeek
   Matchy::load_database("db", "/absolute/path/to/db.mxy");
   ```

### "Matchy database 'name' not found" when querying

**Warning:**
```
warning: Matchy database 'mydb' not found
```

**Solution:**

Make sure you loaded the database first:
```zeek
event zeek_init() {
    if (!Matchy::load_database("mydb", "path/to/db.mxy")) {
        print "Failed to load database!";
        return;
    }
}

event connection_new(c: connection) {
    # Now queries will work
    local result = Matchy::query_ip("mydb", c$id$orig_h);
}
```

## Testing Issues

### Tests fail with "FAIL: Expected match"

**Solution:**

Rebuild the test database:
```bash
cd tests
../../matchy/target/release/matchy build test-data.csv -o test.mxy --format csv
ZEEK_PLUGIN_PATH=../build zeek simple-test.zeek
```

### "No such file or directory: matchy"

**Solution:**

Install the matchy CLI tool:
```bash
cd /path/to/matchy
cargo install --path .
matchy --version
```

## Rust Issues

### "rustc: command not found" or "cargo: command not found"

**Solution:**

Install Rust:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustc --version
```

### "package 'matchy' does not contain this feature: c-api"

**Solution:**

The feature is named `capi` (no hyphen):
```bash
cargo build --release --features capi  # Correct
cargo build --release --features c-api  # Wrong
```

## Getting Help

If you're still stuck:

1. **Check the build output carefully** - it often shows the exact problem
2. **Run with verbose output:**
   ```bash
   cmake -DCMAKE_VERBOSE_MAKEFILE=ON ..
   make VERBOSE=1
   ```
3. **Open an issue** at https://github.com/sethhall/zeek-matchy-plugin with:
   - Your OS and versions (Zeek, Rust, CMake)
   - Complete error messages
   - Build commands you ran
