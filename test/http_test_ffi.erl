-module(http_test_ffi).
-export([make_request_full/1, make_request_with_method/3, raw_request/2,
         raw_exchange/3]).

%% GET request. Returns {ok, {StatusCode, Body}} or {error, Reason}.
make_request_full(Url) when is_binary(Url) ->
    inets:start(),
    UrlStr = binary_to_list(Url),
    Options = [{timeout, 15000}],
    to_result(httpc:request(get, {UrlStr, []}, Options, [])).

%% Request with a method and a body. Returns {ok, {StatusCode, Body}} or
%% {error, Reason}.
make_request_with_method(Url, Method, Body)
  when is_binary(Url), is_binary(Method), is_binary(Body) ->
    inets:start(),
    UrlStr = binary_to_list(Url),
    MethodAtom = method_to_atom(binary_to_list(Method)),
    Request = request(MethodAtom, UrlStr, binary_to_list(Body)),
    Options = [{timeout, 15000}],
    to_result(httpc:request(MethodAtom, Request, Options, [])).

%% httpc takes no body for GET and DELETE.
request(get, UrlStr, _Body) -> {UrlStr, []};
request(delete, UrlStr, _Body) -> {UrlStr, []};
request(_Method, UrlStr, Body) ->
    {UrlStr, [], "application/octet-stream", Body}.

to_result({ok, {{_Version, StatusCode, _ReasonPhrase}, _Headers, Body}}) ->
    {ok, {StatusCode, list_to_binary(ensure_string(Body))}};
to_result({error, Reason}) ->
    {error, reason_to_binary(Reason)}.

%% The connection errors that the tests check get a fixed name, so that the
%% text does not hold a port number.
reason_to_binary({failed_connect, Details}) ->
    case lists:keyfind(inet, 1, Details) of
        {inet, _Families, econnrefused} -> <<"econnrefused">>;
        _Other -> format_reason({failed_connect, Details})
    end;
reason_to_binary(Reason) when is_atom(Reason) ->
    atom_to_binary(Reason, utf8);
reason_to_binary(Reason) ->
    format_reason(Reason).

format_reason(Reason) ->
    list_to_binary(io_lib:format("~p", [Reason])).

ensure_string(Body) when is_list(Body) -> Body;
ensure_string(Body) when is_binary(Body) -> binary_to_list(Body).

method_to_atom("GET") -> get;
method_to_atom("POST") -> post;
method_to_atom("PUT") -> put;
method_to_atom("DELETE") -> delete;
method_to_atom("PATCH") -> patch.

%% Sends raw bytes to the local server on Port and returns every byte that
%% the server sends back until it closes the connection or is quiet for
%% two seconds.
raw_request(Port, Request) when is_integer(Port), is_binary(Request) ->
    case gen_tcp:connect({127, 0, 0, 1}, Port, [binary, {active, false}], 2000) of
        {ok, Socket} ->
            ok = gen_tcp:send(Socket, Request),
            Received = receive_all(Socket, <<>>),
            ok = gen_tcp:close(Socket),
            {ok, Received};
        {error, Reason} ->
            {error, reason_to_binary(Reason)}
    end.

receive_all(Socket, Received) ->
    case gen_tcp:recv(Socket, 0, 2000) of
        {ok, Data} -> receive_all(Socket, <<Received/binary, Data/binary>>);
        {error, _ClosedOrQuiet} -> Received
    end.

%% Sends First on one connection and reads what the server sends back until
%% it closes the connection or is quiet for half a second. Then sends Second
%% on the same connection and reads again until the server closes the
%% connection or is quiet for two seconds. Returns
%% {ok, {FirstAnswer, LaterAnswer, Closed}}: Closed is true when the server
%% closed the connection. The socket stays open for the second send after the
%% server closed its side, so that Second reaches the server.
raw_exchange(Port, First, Second)
  when is_integer(Port), is_binary(First), is_binary(Second) ->
    Options = [binary, {active, false}, {exit_on_close, false}],
    case gen_tcp:connect({127, 0, 0, 1}, Port, Options, 2000) of
        {ok, Socket} ->
            ok = gen_tcp:send(Socket, First),
            {FirstAnswer, _FirstEnd} = receive_until_end(Socket, <<>>, 500),
            _SendResult = gen_tcp:send(Socket, Second),
            {LaterAnswer, LaterEnd} = receive_until_end(Socket, <<>>, 2000),
            ok = gen_tcp:close(Socket),
            {ok, {FirstAnswer, LaterAnswer, LaterEnd =:= closed}};
        {error, Reason} ->
            {error, reason_to_binary(Reason)}
    end.

%% Returns {Received, closed} when the server closed or reset the connection,
%% and {Received, quiet} when no byte came for QuietMs milliseconds.
receive_until_end(Socket, Received, QuietMs) ->
    case gen_tcp:recv(Socket, 0, QuietMs) of
        {ok, Data} ->
            receive_until_end(Socket, <<Received/binary, Data/binary>>, QuietMs);
        {error, timeout} ->
            {Received, quiet};
        {error, _ClosedOrReset} ->
            {Received, closed}
    end.
