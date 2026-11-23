-module(output_file_ffi).
-export([read/1, run_script/1]).

%% Reads a file. Returns {ok, Text} or {error, Message}.
read(Path) ->
    case file:read_file(Path) of
        {ok, Text} -> {ok, Text};
        {error, _Reason} -> {error, <<"Cannot read ", Path/binary>>}
    end.

%% Runs a shell script with sh, and returns {ExitStatus, StandardOutput}.
%% What the script writes to standard error is not kept: curl writes its
%% progress meter there when its output is not a terminal.
run_script(Path) ->
    Port = open_port(
        {spawn_executable, "/bin/sh"},
        [{args, ["-c", "exec sh \"$0\" 2>/dev/null", binary_to_list(Path)]},
         exit_status, binary, stream, use_stdio, hide]),
    collect(Port, []).

collect(Port, Chunks) ->
    receive
        {Port, {data, Data}} ->
            collect(Port, [Data | Chunks]);
        {Port, {exit_status, Status}} ->
            {Status, iolist_to_binary(lists:reverse(Chunks))}
    end.
