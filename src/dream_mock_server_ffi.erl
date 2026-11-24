-module(dream_mock_server_ffi).

-export([port_in_use/1, stop_supervisor/1]).

%% Returns true when a process accepts TCP connections on the port of
%% localhost (127.0.0.1), and false when the connection fails within 200 ms.
port_in_use(Port) when is_integer(Port) ->
    case gen_tcp:connect({127, 0, 0, 1}, Port, [{active, false}], 200) of
        {ok, Socket} ->
            ok = gen_tcp:close(Socket),
            true;
        {error, _ConnectionFailed} ->
            false
    end.

%% Stops the supervisor that mist:start/1 returns, from any process, and
%% returns nil when the supervisor is no longer running.
%%
%% An exit signal with reason normal does nothing unless it comes from the
%% parent of the supervisor, so the supervisor is stopped through the sys
%% protocol: gen_server:stop/1 calls proc_lib:stop(Pid, normal, infinity).
%% The supervisor then stops each child in reverse start order with the
%% shutdown that its child specification gives, and exits with reason
%% normal. Because the reason is normal, the linked process that started
%% the server does not get an exit that kills it. The call returns only
%% after the supervisor is down, so the port is free when it returns.
%%
%% gen_server:stop/1 exits the caller only when the supervisor is not
%% running: noproc when it was down before the call, or the exit reason of
%% the supervisor when it stopped for a different reason during the call.
%% In each case the supervisor is down, which is the result that stop asks
%% for, so the function returns nil.
stop_supervisor(Pid) when is_pid(Pid) ->
    try gen_server:stop(Pid) of
        ok -> nil
    catch
        exit:_SupervisorIsAlreadyDown -> nil
    end.
