---
layout: post
title: "Elixir Phoenix Framework Memcached by poolboy"
date: 2015-10-19T13:57:48+09:00
---

# 동기

Raw SQL을 사용할 수 있게됨에 따라 mysql,posgresql은 잘 사용할 수 있게되었는데
memcached 캐시를 사용하고 싶은데 방법을 잘 모르겠어서 찾아보았습니다.

다행히 Yokohama에 사는 ymmtmsys(山本)이라는분께서 잘 정리해둔것이 있어서 쉽게 따라해볼 수 있습니다.

# 참고문헌

* https://github.com/EchoTeam/mcd
* https://gist.github.com/ymmtmsys/5b3340cb22aebf8436d8
( http://ymmtmsys.hatenablog.com/entry/2015/09/02/214254 )

# phoenix framework 준비

프로젝트 생성
{% highlight bash %}
mix phoenix.new myprj
{% endhighlight %}

# 로컬서버 실행

{% highlight bash %}
iex -S mix phoenix.server
{% endhighlight %}

http://localhost:4000
으로 접속하여 확인해봅니다.

# poolboy와 mcd 모듈 추가

* poolboy는 erlang의 worker pool factory 모듈입니다.
  https://github.com/devinus/poolboy

* mcd는 erlang의 memcached client library 입니다. EctoTeam에서 만들었네요..
  https://github.com/EchoTeam/mcd

mix.exs
{% highlight elixir %}
   def application do
     [mod: {Myprj, []},
      applications: [:phoenix, :phoenix_html, :cowboy, :logger,
-                    :phoenix_ecto, :postgrex]]
+                    :phoenix_ecto, :postgrex, :poolboy]]
   end

.
.
.

   defp deps do
     [{:phoenix, "~> 1.0.3"},
      {:phoenix_ecto, "~> 1.1"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.1"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
+     {:poolboy, "~> 1.5.1"},
+     {:mcd, github: "EchoTeam/mcd"},
      {:cowboy, "~> 1.0"}]
   end

{% endhighlight %}

# dep modules get

{% highlight bash %}
mix deps.get
{% endhighlight %}


# memcached Supervisor module add

lib/myprj.ex 의 끝부분에 추가. (다른 파일로 만들어도 됩니다)

{% highlight elixir %}
.
.
.

defmodule Memcached.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    pool_options = [
      name: {:local, :memcached_pool},
      worker_module: :mcd,
      size: 5,
      max_overflow: 0,
    ]

    arg = ['localhost', 11211]

    children = [
        :poolboy.child_spec(:memcached_pool, pool_options, arg)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
{% endhighlight %}


# memcached Supervisor start

lib/myprj.ex 수정

{% highlight elixir %}
   def start(_type, _args) do
     import Supervisor.Spec, warn: false

     children = [
       # Start the endpoint when the application starts
       supervisor(Myprj.Endpoint, []),
       # Start the Ecto repository
       worker(Myprj.Repo, []),
       # Here you could define other workers and supervisors as children
       # worker(Myprj.Worker, [arg1, arg2, arg3]),
+      supervisor(Memcached.Supervisor, []),
     ]
{% endhighlight %}


## 사용하기

# set,get,delete handler 작성

web/controllers/page_controller.ex


{% highlight elixir %}

  def set(conn, _params) do
    {result,_} = :poolboy.transaction(:memcached_pool, fn worker ->
      :mcd.set(worker, "testkey", "Hello Phoenix")
    end)
    json conn, %{request: "set", result: result}
  end

  def get(conn, _params) do
    result = :poolboy.transaction(:memcached_pool, fn worker ->
      :mcd.get(worker, "testkey")
      |> case do
          {:ok, resp} -> resp
          _           -> false
      end
    end)
    json conn, %{request: "get", result: result}
  end

  def delete(conn, _params) do
    {_,result} = :poolboy.transaction(:memcached_pool, fn worker ->
      :mcd.delete(worker, "testkey")
    end)
    json conn, %{request: "delete", result: result}
  end

{% endhighlight %}


# set,get route 설정

web/router.ex
{% highlight elixir %}
   scope "/", Myprj do
     pipe_through :browser # Use the default browser stack

     get "/", PageController, :index
+    get "/set", PageController, :set
+    get "/get", PageController, :get
+    get "/delete", PageController, :delete
   end
{% endhighlight %}

다음의 URL을 방문하여 확인

* http://localhost/4000/set

* http://localhost/4000/get

* http://localhost/4000/delete


