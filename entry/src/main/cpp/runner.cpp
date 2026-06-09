#include "napi/native_api.h"
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string>
#include <vector>
#include <sstream>
#include <cstring>

extern char **environ;

static napi_value RunCommand(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    size_t cmdLen;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &cmdLen);
    std::string cmd(cmdLen + 1, '\0');
    napi_get_value_string_utf8(env, args[0], &cmd[0], cmdLen + 1, &cmdLen);
    cmd.resize(cmdLen);

    int pipefd[2];
    if (pipe(pipefd) != 0) {
        napi_value result;
        napi_create_string_utf8(env, "pipe failed", NAPI_AUTO_LENGTH, &result);
        return result;
    }

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&actions, pipefd[0]);
    posix_spawn_file_actions_addclose(&actions, pipefd[1]);

    std::vector<char*> argv;
    argv.push_back(const_cast<char*>("/bin/sh"));
    argv.push_back(const_cast<char*>("-c"));
    argv.push_back(const_cast<char*>(cmd.c_str()));
    argv.push_back(nullptr);

    pid_t pid;
    int ret = posix_spawn(&pid, "/bin/sh", &actions, nullptr, argv.data(), environ);
    posix_spawn_file_actions_destroy(&actions);
    close(pipefd[1]);

    std::string output;
    if (ret == 0) {
        char buf[4096];
        ssize_t n;
        while ((n = read(pipefd[0], buf, sizeof(buf))) > 0) {
            output.append(buf, n);
        }
        int status;
        waitpid(pid, &status, 0);
    } else {
        output = "spawn failed: " + std::string(strerror(ret));
    }
    close(pipefd[0]);

    napi_value result;
    napi_create_string_utf8(env, output.c_str(), output.size(), &result);
    return result;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"runCommand", nullptr, RunCommand, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module runnerModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "runner",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterRunnerModule(void) {
    napi_module_register(&runnerModule);
}
