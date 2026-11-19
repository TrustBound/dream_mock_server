-module(http_test_ffi).
-export([make_request_full/1, make_request_with_method/3]).

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
