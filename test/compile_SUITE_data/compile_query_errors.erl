-module(compile_query_errors).

-compile({parse_transform, erlack_db}).

-ifdef(ERROR).

-err(1).
illegal_generate() ->
    erlack_db:compile(select([1 || 1 <- x])).

-err(1).
b_generate() ->
    erlack_db:compile(select([1 || <<>> <= x])).

-err(1).
not_lc() ->
    erlack_db:compile(select(1)).

-err(3).
not_lc() ->
    erlack_db:compile(
      select(
        #{i => [1]},
        [1 || true])).

-err(1).
illegal_cte() ->
    erlack_db:compile(select(1,1)).

-err(1).
illegal_cte() ->
    erlack_db:compile(select(#{1 := 1},1)).

-err(3).
not_proper_list() ->
    erlack_db:compile(
      select(
        #{i => 1},
        1)).

-err(3).
output_name_conflict() ->
    erlack_db:compile(
      select(
        #{i => [[#{a => 1} || true], [#{b => 1} || true]]},
        [1 || true])).

-err(3).
illegal_output_expression() ->
    erlack_db:compile(
      select(
        #{i => [[1 || true]]},
        [1 || true])).

-err(3).
illegal_output_expression() ->
    erlack_db:compile(
      select(
        #{i => [[#{1 := 1} || true]]},
        [1 || true])).

-err(3).
illegal_output_expression() ->
    erlack_db:compile(
      select(
        #{i => [[#{1 := 1} || true]]},
        [1 || true])).


-err({3, erlack_db, {output_conflict, a}}).
output_conflict() ->
    erlack_db:compile(
      select(
        #{i => [[#{a => 1, a => 2} || true]]},
        [1 || true])).


-err(2).
illegal_select_expression() ->
    erlack_db:compile(
      select([ 1 || #{} <- from(select()) ])).

-err(2).
illegal_pattern() ->
    erlack_db:compile(
      select([ 1 || 1 <- from(items) ])).

-err(2).
illegal_pattern() ->
    erlack_db:compile(
      select([ 1 || #{a => 1} <- from(items) ])).

-err(2).
illegal_pattern() ->
    erlack_db:compile(
      select([ 1 || #{a := 1} <- from(items) ])).


-err(1).
illegal_expression() ->
    erlack_db:compile(select([ 1 || atom ])).

-err(1).
illegal_order_expression() ->
    erlack_db:compile(select([ 1 || order_by(1) ])).

-err(1).
integer_not_allowed() ->
    erlack_db:compile(select([ 1 || order_by(asc(1)) ])).

-err({5, erlack_db, {once, order_by}}).
illegal_order_expression() ->
    erlack_db:compile(
      select([ 1
               || #{a := A} <- from(items),
                  order_by(asc(A)),
                  order_by(asc(A)) ])).

-err(1).
first_table_join() ->
    erlack_db:compile(select([ 1 || #{} <- join(items)])).

-err({1, erlack_db, {bound, 'X'}}).
bound() ->
    erlack_db:compile(select([ 1 || #{a := X, b := X} <- join(items)])).

-err({1, erlack_db, {unbound, 'X'}}).
unbound() ->
    erlack_db:compile(select([ 1 || X == 0])).

-err({1, erlack_db, {unbound, '_X'}}).
unbound() ->
    erlack_db:compile(select([ 1 || _X == 0])).

-err(5).
aggregate_in_join() ->
    erlack_db:compile(
      select(
        [ 1
          || #{id := ID} <- from(items),
             #{} <- join(items, c(id) == count(ID))])).


-warn(
   [{7, erlack_db, {unused_var, 'ID'}},
    {12, erl_lint, {unused_var, 'Name'}},
    {20, erlack_db, unused_param}
   ]).
warnings() ->
    erlack_db:compile(
     select(
       [ 1
         || #{} <-
                from(
                  select(
                    [ #{} || #{id := ID} <- from(items) ]))
       ])),

    erlack_db:compile(
     select(
       [ ID
         || #{id := ID, name := Name} <- from(items)
       ])),

    erlack_db:compile(
     select(
       [ ID
         || #{id := ID} <- from(items),
            _ <- [param(1)]
       ])).

-endif.
