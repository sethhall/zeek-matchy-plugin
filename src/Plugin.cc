#include "Plugin.h"
#include <matchy/matchy.h>
#include <zeek/Desc.h>

namespace zeek::plugin::Matchy {

Plugin plugin;

MatchyDB::~MatchyDB() {
    if (db_handle) {
        matchy_close(db_handle);
        db_handle = nullptr;
    }
}

void MatchyDB::ValDescribe(zeek::ODesc* d) const {
    d->Add("MatchyDB[");
    if (db_handle) {
        d->Add("open");
    } else {
        d->Add("closed");
    }
    d->Add("]");
}

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
