---
layout: post
title: "Elixir Phoenix Framework Memcached by poolboy"
date: 2015-10-26T15:35:48+09:00
---

# memcached cluster

지난번 포스팅에서 :mcd 모듈을 이용해서 memcached를 사용하는법을 알아냈습니다만, 여러대의 memcached cluster가 있을 경우에는 :mcd_cluster를 사용해야 합니다.

[https://github.com/EchoTeam/mcd](https://github.com/EchoTeam/mcd)
의 설명을 보면 erlang에서는 cluster 모드는 다음과 같이 사용할 수 있다고 나옵니다.

{% highlight erlang %}
{mainCluster,
    {mcd_cluster, start_link, [mainCluster, [
        {host1, ["localhost"], 10},
        {host2, ["localhost"], 20}
    ]]},
    permanent, 60000, worker, [mcd_cluster]}
{% endhighlight %}

erlang 문법이 익숙칠 않아서 elixir에는 어떻게 해야할지 몰라서 고생했네요. ^^
간단 요약하면 다음과 같이 하면 됩니다.

{% highlight elixir %}
:poolboy.child_spec(:memcached_pool,
	[ # pool_option
		name: {:local, :memcached_pool},
		worker_module: :mcd_cluster,
		size: 5,
		max_overflow: 0,
	],
	[ # argument
		{:node1, ['localhost', 11211], 10},
		{:node2, ['localhost', 11212], 10},
	])
{% endhighlight %}


# phoenix framework 준비

일단 차근차근 이전에 했던것과 같이 프로젝트를 만들어줍니다.

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

  [https://github.com/devinus/poolboy](https://github.com/devinus/poolboy)

  [https://github.com/EchoTeam/mcd](https://github.com/EchoTeam/mcd)

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


# memcached cluster Supervisor module add

**<font color="red">이 부분부터가 이전과 달라집니다.</font>**

**<font color="red">:mcd 대신 :mcd_cluster 를 사용하고 argument의 형식이 달라집니다.</font>**

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
      # worker_module: :mcd,	## 이부분이 변경되었습니다.
      worker_module: :mcd_cluster,
      size: 5,
      max_overflow: 0,
    ]

    # arg = ['localhost', 11211]  ## 그리고 여기 argument가 달라졌습니다.
    arg = [
        {:node1, ['localhost', 11211], 10},
        {:node1, ['localhost', 11212], 10},
    }

    children = [
        :poolboy.child_spec(:memcached_pool, pool_options, arg)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
{% endhighlight %}


# memcached Supervisor start

그리고 나머지는 이전과 같습니다..

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

# 다음의 URL을 방문하여 확인

* http://localhost:4000/set
{% highlight xml %}
{
    "result": "ok",
    "request": "set"
}
{% endhighlight %}

* http://localhost:4000/get
{% highlight xml %}
{
    "result": "Hello Phoenix",
    "request": "get"
}
{% endhighlight %}

* http://localhost:4000/delete
{% highlight xml %}
{
    "result": "deleted",
    "request": "delete"
}
{% endhighlight %}


# 결론

Memcached.Supervisor 설정하는 방법만 다르고 나머진 그대로 이용할 수 있어 좋네요...

