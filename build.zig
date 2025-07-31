const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Configuration options
    const build_gmock = b.option(bool, "build-gmock", "Build the googlemock subproject") orelse true;
    const gtest_has_absl = b.option(bool, "gtest-has-absl", "Use Abseil and RE2") orelse false;
    const build_tests = b.option(bool, "build-tests", "Build all tests") orelse false;
    const build_samples = b.option(bool, "build-samples", "Build sample programs") orelse false;
    const disable_pthreads = b.option(bool, "disable-pthreads", "Disable uses of pthreads") orelse false;

    // GTest library
    const gtest = b.addStaticLibrary(.{
        .name = "gtest",
        .target = target,
        .optimize = optimize,
    });
    gtest.linkLibCpp();
    
    // Add include directories
    gtest.addIncludePath(b.path("googletest/include"));
    gtest.addIncludePath(b.path("googletest"));
    
    // Add source files
    gtest.addCSourceFile(.{
        .file = b.path("googletest/src/gtest-all.cc"),
        .flags = &[_][]const u8{"-std=c++17"},
    });

    // Platform-specific configurations
    // QNX support would go here if needed

    if (disable_pthreads) {
        gtest.root_module.addCMacro("GTEST_HAS_PTHREAD", "0");
    }

    if (gtest_has_absl) {
        gtest.root_module.addCMacro("GTEST_HAS_ABSL", "1");
        // Note: You'll need to link against absl and re2 libraries here
        // This example assumes they're available as system libraries
        gtest.linkSystemLibrary("absl_failure_signal_handler");
        gtest.linkSystemLibrary("absl_stacktrace");
        gtest.linkSystemLibrary("absl_symbolize");
        gtest.linkSystemLibrary("absl_flags_parse");
        gtest.linkSystemLibrary("absl_flags_reflection");
        gtest.linkSystemLibrary("absl_flags_usage");
        gtest.linkSystemLibrary("absl_strings");
        gtest.linkSystemLibrary("re2");
    }

    b.installArtifact(gtest);

    // GTest main library
    const gtest_main = b.addStaticLibrary(.{
        .name = "gtest_main",
        .target = target,
        .optimize = optimize,
    });
    gtest_main.linkLibCpp();
    gtest_main.addIncludePath(b.path("googletest/include"));
    gtest_main.addIncludePath(b.path("googletest"));
    gtest_main.addCSourceFile(.{
        .file = b.path("googletest/src/gtest_main.cc"),
        .flags = &[_][]const u8{"-std=c++17"},
    });
    gtest_main.linkLibrary(gtest);
    b.installArtifact(gtest_main);

    // GMock library (if enabled)
    if (build_gmock) {
        const gmock = b.addStaticLibrary(.{
            .name = "gmock",
            .target = target,
            .optimize = optimize,
        });
        gmock.linkLibCpp();
        gmock.addIncludePath(b.path("googlemock/include"));
        gmock.addIncludePath(b.path("googlemock"));
        gmock.addIncludePath(b.path("googletest/include"));
        gmock.addIncludePath(b.path("googletest"));
        gmock.addCSourceFile(.{
            .file = b.path("googlemock/src/gmock-all.cc"),
            .flags = &[_][]const u8{"-std=c++17"},
        });
        gmock.linkLibrary(gtest);
        b.installArtifact(gmock);

        // GMock main library
        const gmock_main = b.addStaticLibrary(.{
            .name = "gmock_main",
            .target = target,
            .optimize = optimize,
        });
        gmock_main.linkLibCpp();
        gmock_main.addIncludePath(b.path("googlemock/include"));
        gmock_main.addIncludePath(b.path("googlemock"));
        gmock_main.addIncludePath(b.path("googletest/include"));
        gmock_main.addIncludePath(b.path("googletest"));
        gmock_main.addCSourceFile(.{
            .file = b.path("googlemock/src/gmock_main.cc"),
            .flags = &[_][]const u8{"-std=c++17"},
        });
        gmock_main.linkLibrary(gmock);
        gmock_main.linkLibrary(gtest);
        b.installArtifact(gmock_main);
    }

    // Sample programs (if enabled)
    if (build_samples) {
        // Sample 1
        const sample1 = b.addExecutable(.{
            .name = "sample1_unittest",
            .target = target,
            .optimize = optimize,
        });
        sample1.linkLibCpp();
        sample1.addIncludePath(b.path("googletest/include"));
        sample1.addCSourceFiles(.{
            .files = &[_][]const u8{
                "googletest/samples/sample1.cc",
                "googletest/samples/sample1_unittest.cc",
            },
            .flags = &[_][]const u8{"-std=c++17"},
        });
        sample1.linkLibrary(gtest_main);
        b.installArtifact(sample1);

        // Sample 2
        const sample2 = b.addExecutable(.{
            .name = "sample2_unittest",
            .target = target,
            .optimize = optimize,
        });
        sample2.linkLibCpp();
        sample2.addIncludePath(b.path("googletest/include"));
        sample2.addCSourceFiles(.{
            .files = &[_][]const u8{
                "googletest/samples/sample2.cc",
                "googletest/samples/sample2_unittest.cc",
            },
            .flags = &[_][]const u8{"-std=c++17"},
        });
        sample2.linkLibrary(gtest_main);
        b.installArtifact(sample2);

        // Add more samples as needed...
    }

    // Tests (if enabled)
    if (build_tests) {
        // Example test
        const test_exe = b.addExecutable(.{
            .name = "gtest_unittest",
            .target = target,
            .optimize = optimize,
        });
        test_exe.linkLibCpp();
        test_exe.addIncludePath(b.path("googletest/include"));
        test_exe.addIncludePath(b.path("googletest"));
        test_exe.addCSourceFile(.{
            .file = b.path("googletest/test/gtest_unittest.cc"),
            .flags = &[_][]const u8{"-std=c++17"},
        });
        test_exe.linkLibrary(gtest_main);
        
        const run_test = b.addRunArtifact(test_exe);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_test.step);
    }

}