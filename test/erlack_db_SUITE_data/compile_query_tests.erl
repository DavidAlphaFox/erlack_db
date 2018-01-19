-module(compile_query_tests).

-compile({parse_transform, erlack_db}).

-ifdef(EUNIT).
-include_lib("eunit/include/eunit.hrl").

apply_select_query({select, SQL, Params, Fun}, Input) ->
    {select, SQL, Params, Fun(Input)};
apply_select_query(X, _) ->
    {error, X}.

select_test_() ->
    Test =
        fun(Fun, Args) ->
                ?_test(
                   begin
                       {Expect, Query, Input} = apply(Fun, Args),
                       ?assertEqual(Expect, apply_select_query(Query, Input))
                   end)
        end,
    [ Test(
        fun() ->
                {{select,
                  "SELECT 1 FROM \"items\" AS T1",
                  [],
                  [1,1,1]},
                 erlack_db:compile(
                   select(
                     [ 1
                       || #{} <- from(items)
                     ])),
                 [{1},{1},{1}]}
        end,
        []),

      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"id\" FROM \"items\" AS T1",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ ID
                       || #{id := ID} <- from(items)
                     ])),
                 [{1},{2},{3}]}
        end,
        []),

      Test(
        fun(X) ->
                {{select,
                  "SELECT T1.\"name\" FROM \"items\" AS T1 WHERE (T1.\"id\" = $1)",
                  [X],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ Name
                       || #{id := ID, name := Name} <- from(items),
                          ID == X
                     ])),
                 [{1},{2},{3}]}
        end,
        [1]),

      Test(
        fun(X) ->
                {{select,
                  "SELECT T1.\"name\" FROM \"items\" AS T1 WHERE (T1.\"id\" = $1)",
                  [X],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ Name
                       || #{id := ID, name := Name} <- from(items),
                          ID == param(X)
                     ])),
                 [{1},{2},{3}]}
        end,
        [1]),

      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"id\" FROM \"i1\" AS T1 CROSS JOIN \"i2\" AS T2 WHERE (T1.\"id\" = T2.\"id\")",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ I1
                       || #{id := I1} <- from(i1),
                          #{id := I2} <- from(i2),
                          I1 == I2
                     ])),
                 [{1},{2},{3}]}
        end,
        []),

      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"id\", T2.\"name\" FROM \"i1\" AS T1 LEFT OUTER JOIN \"i2\" AS T2 ON (T2.\"id\" = T1.\"id\")",
                  [],
                  [{1,2},{2,3},{3,4}]},
                 erlack_db:compile(
                   select(
                     [ {I1, Name}
                       || #{id := I1} <- from(i1),
                          #{name := Name} <- join(i2, c(id) == I1)
                     ])),
                 [{1,2},{2,3},{3,4}]}
        end,
        []),

      Test(
        fun() ->
                {{select,
                  "SELECT count(T1.\"id\"), T1.\"name\" FROM \"items\" AS T1 GROUP BY T1.\"name\"",
                  [],
                  [{1,2},{2,3},{3,4}]},
                 erlack_db:compile(
                   select(
                     [ {Name, Count}
                       || #{id := ID, name := Name} <- from(items),
                          group_by(Name),
                          Count <- [count(ID)]
                     ])),
                 [{2,1},{3,2},{4,3}]}
        end,
        []),

      Test(
        fun(X) ->
                {{select,
                  "SELECT count(T1.\"id\"), T1.\"name\" FROM \"items\" AS T1 GROUP BY T1.\"name\" HAVING (count(T1.\"id\") = $1)",
                  [X],
                  [{1,2},{2,3},{3,4}]},
                 erlack_db:compile(
                   select(
                     [ {Name, Count}
                       || #{id := ID, name := Name} <- from(items),
                          group_by(Name),
                          Count <- [count(ID)],
                          Count == X
                     ])),
                 [{2,1},{3,2},{4,3}]}
        end,
        [1]),

      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"id\" FROM \"items\" AS T1 ORDER BY T1.\"id\" ASC",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ ID
                       || #{id := ID} <- from(items),
                          order_by(asc(ID))
                     ])),
                 [{1},{2},{3}]}
        end,
        []),


      Test(
        fun() ->
                {{select,
                  "SELECT DISTINCT ON (T1.\"name\") T1.\"name\" FROM \"items\" AS T1",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ Name
                       || #{name := Name} <- from(items),
                          distinct(Name)
                     ])),
                 [{1},{2},{3}]}
        end,
        []),

      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"id\" FROM \"items\" AS T1 ORDER BY T1.\"id\" ASC OFFSET (10) LIMIT (10)",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ ID
                       || #{id := ID} <- from(items),
                          order_by(asc(ID)),
                          offset(10),
                          limit(10)

                     ])),
                 [{1},{2},{3}]}
        end,
        []),


      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"id\" FROM \"i1\" AS T1 WHERE (EXISTS((SELECT 1 FROM \"i2\" AS T2 WHERE (T1.\"id\" = T2.\"id\"))))",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ A
                       || #{id := A} <- from(i1),
                          exists(
                            select(
                              [ #{}
                                || #{id := B} <- from(i2),
                                   A == B
                              ]))


                     ])),
                 [{1},{2},{3}]}
        end,
        []),

      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"name\" FROM \"i1\" AS T1 GROUP BY T1.\"name\" HAVING (EXISTS((SELECT T2.\"count\" AS count FROM \"i2\" AS T2 WHERE (T2.\"count\" = count(T1.\"id\")))))",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ Name
                       || #{id := ID, name := Name} <- from(i1),
                          group_by(Name),
                          Count <- [count(ID)],
                          exists(
                            select(
                              [ #{count => C}
                                || #{count := C} <- from(i2),
                                   C == Count
                              ]))

                     ])),
                 [{1},{2},{3}]}
        end,
        []),

      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"id\" FROM LATERAL (SELECT T2.\"id\" AS id FROM \"items\" AS T2) AS T1",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ ID
                       || #{id := ID} <-
                              from(
                                select(
                                  [ #{ id => ID}
                                    || #{id := ID} <- from(items)
                                  ]))

                     ])),
                 [{1},{2},{3}]}
        end,
        []),

      Test(
        fun() ->
                {{select,
                  "WITH RECURSIVE \"i\"(\"id\") AS ((SELECT T1.\"id\" AS id FROM \"items\" AS T1)) SELECT T2.\"id\" FROM \"i\" AS T2",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     #{i => [[#{id => ID} || #{id := ID} <- from(items)]]},
                     [ ID
                       || #{id := ID} <- from(i)

                     ])),
                 [{1},{2},{3}]}
        end,
        []),

      Test(
        fun() ->
                {{select,
                  "SELECT T1.\"id\" FROM LATERAL (WITH RECURSIVE \"i\"(\"id\") AS ((SELECT T2.\"id\" AS id FROM \"items\" AS T2)) SELECT T3.\"id\" AS id FROM \"i\" AS T3) AS T1",
                  [],
                  [1,2,3]},
                 erlack_db:compile(
                   select(
                     [ ID
                       || #{id := ID} <-
                              from(
                                select(
                                  #{i => [[#{id => ID} || #{id := ID} <- from(items)]]},
                                  [ #{id=> ID}
                                    || #{id := ID} <- from(i)
                                  ]
                                 ))
                     ])),
                 [{1},{2},{3}]}
        end,
        [])

    ].


-endif.
