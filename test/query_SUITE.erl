-module(query_SUITE).

-compile({parse_transform, erlack_db}).

-include_lib("common_test/include/ct.hrl").
-compile(export_all).

all() ->
    [test_compile].

suite() ->
    [{require, {postgresql, [host, username, password]}}].

connect() ->
    connect([]).

connect(Opts) ->
    Host = ct:get_config({postgresql, host}),
    Username = ct:get_config({postgresql, username}),
    Password = ct:get_config({postgresql, password}),
    epgsql:connect(Host, Username, Password, Opts).

recreate_database(Database) ->
    {ok, C} = connect(),
    {ok, _, _} = epgsql:squery(C, io_lib:format("DROP DATABASE IF EXISTS \"~s\"", [erlack_db:escape_id(Database)])),
    {ok, _, _} = epgsql:squery(C, io_lib:format("CREATE DATABASE \"~s\"", [erlack_db:escape_id(Database)])),
    ok = epgsql:close(C).

init_per_testcase(_, Config) ->
    DB = "erlack_db_test",
    ok = recreate_database(DB),
    [{database, DB}|Config].

test_compile(Config) ->
    {ok, C} = connect([{database, ?config(database, Config)}]),
    Query = erlack_db:compile(select([ 1 || true ])),
    {ok, [1]} = erlack_db:query(C, Query).
