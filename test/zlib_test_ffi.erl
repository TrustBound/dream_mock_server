-module(zlib_test_ffi).
-export([gunzip/1, uncompress/1]).

%% Decompresses one gzip stream.
gunzip(Data) when is_binary(Data) ->
    zlib:gunzip(Data).

%% Decompresses one zlib (deflate) stream.
uncompress(Data) when is_binary(Data) ->
    zlib:uncompress(Data).
