-module(compile_SUITE).

-include_lib("common_test/include/ct.hrl").
-compile(export_all).

all() ->
    [eunit, compile_query_errors].

eunit(Config) ->
    Datadir = ?config(data_dir, Config),
    Privdir = ?config(priv_dir, Config),

    Erls =
        [ filename:join(Datadir, Name)
          || Name <- filelib:wildcard("*_tests.erl", Datadir) ],

    up_to_date =
        make:files(
          Erls,
          [{outdir, Privdir},
           verbose,
           {d, 'TEST'},
           {d, 'EUNIT'}]),

    ok =
        eunit:test(
          [{dir, Privdir}],
          [verbose]).


compile_query_errors(Config) ->
    Datadir = ?config(data_dir, Config),
    Privdir = ?config(priv_dir, Config),

    M = erlack_db,
    Filename = filename:join(Datadir, "compile_query_errors.erl"),

    {ok, Forms} = epp:parse_file(Filename, [{macros, ['ERROR']}]),

    Errors = expected_error(Forms),
    Warnings = expected_warnings(Forms),

    io:format("~p~n", [{error, [{Filename,Errors}], [{Filename,Warnings}]}]),

    {error, [{Filename,Errors}], [{Filename,Warnings}]} =
        compile:file(
          Filename,
          [{outdir, Privdir},
           export_all,
           verbose,
           {d, 'ERROR'},
           return]).

expected_error([]) ->
    [];
expected_error([{attribute, _, err, Offset}, {function, Line, Error, _, _}|T]) when is_integer(Offset) ->
    [{Line+Offset, erlack_db, Error}|expected_error(T)];
expected_error([{attribute, _, err, {Offset, Module, Error}}, {function, Line, _, _, _}|T]) ->
    [{Line+Offset, Module, Error}|expected_error(T)];
expected_error([_|T]) ->
    expected_error(T).


expected_warnings([]) ->
    [];
expected_warnings([{attribute, _, warn, Warnings}, {function, Line, _, _, _}|_]) ->
    [{Line+Offset, Mod, Error} || {Offset, Mod, Error} <- Warnings];
expected_warnings([_|T]) ->
    expected_warnings(T).
