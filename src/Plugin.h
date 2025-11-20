#pragma once

#include <zeek/plugin/Plugin.h>
#include <zeek/OpaqueVal.h>
#include <matchy/matchy.h>

namespace zeek::plugin::Matchy {

// Opaque type that wraps a Matchy database handle
class MatchyDB : public zeek::OpaqueVal {
public:
    explicit MatchyDB(matchy::matchy_t* db) 
        : zeek::OpaqueVal(zeek::make_intrusive<zeek::OpaqueType>("MatchyDB")), db_handle(db) {}
    ~MatchyDB();

    matchy::matchy_t* GetHandle() const { return db_handle; }

    // Required by Zeek's opaque type system
    const char* OpaqueName() const override { return "MatchyDB"; }
    void ValDescribe(zeek::ODesc* d) const override;

private:
    matchy::matchy_t* db_handle;
};

class Plugin : public zeek::plugin::Plugin {
protected:
    // Overridden from zeek::plugin::Plugin.
    zeek::plugin::Configuration Configure() override;
};

extern Plugin plugin;

}
