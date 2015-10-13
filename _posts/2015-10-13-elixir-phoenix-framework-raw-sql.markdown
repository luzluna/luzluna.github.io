---
layout: post
title: "Elixir Phoenix Framework Raw SQL"
date: 2015-08-25T11:37:48+09:00
---

= phoenix project create

```
# phoenix install
mix archive.install https://github.com/phoenixframework/phoenix/releases/download/v1.0.3/phoenix_new-1.0.3.ez
# project create without ecto
mix phoenix.new myprj --no-ecto
cd myprj
```

= ecto add for raw sql

mix.exs
```
   def application do
     [mod: {Myprj, []},
-     applications: [:phoenix, :phoenix_html, :cowboy, :logger]]
+     applications: [:phoenix, :phoenix_html, :cowboy, :logger, :postgrex, :ecto]]
   end

.
.
.

   defp deps do
     [{:phoenix, "~> 1.0.3"},
      {:phoenix_html, "~> 2.1"},
+     {:ecto, "~> 1.0.4"},
+     {:postgrex, ">= 0.0.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:cowboy, "~> 1.0"}]
   end
```

lib/myprj.ex
```
   def start(_type, _args) do
     import Supervisor.Spec, warn: false

     children = [
       # Start the endpoint when the application starts

       supervisor(Kara.Endpoint, []),
       # Here you could define other workers and supervisors as children
       # worker(Kara.Worker, [arg1, arg2, arg3]),
+
+      # Start the Ecto repository
+      worker(Kara.Repo, []),
     ]

.
.
.

+defmodule Myprj.Repo do
+  use Ecto.Repo, otp_app: :myprj
+end
```


config/dev.exs
```
+
+config :kara, Kara.Repo,
+  adapter: Ecto.Adapters.Postgres,
+  database: "kara",
+  username: "kara",
+  password: "",
+  hostname: "localhost"
```


끝.

테스트해보려면..
web/controllers/page_controller.ex
```
   def index(conn, _params) do
+    Ecto.Adapters.SQL.query(Kara.Repo, "SELECT 1",[])
     render conn, "index.html"
   end
```

http://localhost:4000 으로 접속해보면 로그에 다음과같이 나옵니다.
```
[debug] SELECT 1 [] OK query=170.4ms queue=7.1ms
```

성공!
