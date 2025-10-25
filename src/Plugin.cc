#include "Plugin.h"

namespace zeek::plugin::Matchy {

Plugin plugin;

zeek::plugin::Configuration Plugin::Configure() {
    zeek::plugin::Configuration config;
    config.name = "Matchy::DB";
    config.description = "Fast IP and pattern matching using Matchy databases";
    config.version.major = 0;
    config.version.minor = 1;
    config.version.patch = 0;
    return config;
}

}
