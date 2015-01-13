-module(erlsqlmigrate_rebar_plugin).

-export(['create-migration'/2, 'migrate-up'/2, 'migrate-down'/2]).

'create-migration'(_Config, AppFile) ->
  {Dir, Conf} = config(AppFile),
  erlsqlmigrate:create([Conf], Dir, get_name_arg(args())).

'migrate-up'(_Config, AppFile) ->
  {Dir, Conf} = config(AppFile),
  erlsqlmigrate:up([Conf], Dir, get_name_arg(args())).

'migrate-down'(_Config, AppFile) ->
  {Dir, Conf} = config(AppFile),
  erlsqlmigrate:down([Conf], Dir, get_name_arg(args())).

config(AppFile) ->
  {ok, [{application, _, AppSrc}]} = file:consult(AppFile),
  {env, Env}= proplists:lookup(env, AppSrc),
  Db = db_config(Env, os:getenv("DATABASE")),
  {migration_dir, Dir} = proplists:lookup(migration_dir, Env),
  {Dir, Db}.

db_config(Env, false) ->
  lists:foldl(fun(E, P) ->
                {E, P1} = proplists:lookup(E, P), P1
              end, Env, [database, environment()] );
db_config(_Env, Uri) ->
  {ok, {Scheme, Auth, Host, Port, [$/|DB],[]}} = http_uri:parse(Uri),
  case re:split(Auth, ":", [{return, list}]) of
    [User, Pass] -> {Scheme, [Host, Port, DB, User, Pass]};
    [User]       -> {Scheme, [Host, Port, DB, User]}
  end.

environment() ->
  case os:getenv("ENV") of
    false -> development;
    Env   -> list_to_atom(Env)
  end.

get_name_arg([<<"name">>, Name]) -> binary_to_list(Name);
get_name_arg([]) -> "".

args() ->
  case init:get_plain_arguments() of
    [_, _] -> [];
    [_, _, ArgStr] -> init:get_plain_arguments(), re:split(ArgStr, "=")
  end.