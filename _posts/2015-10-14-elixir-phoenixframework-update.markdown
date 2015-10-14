---
layout: post
title: "Elixir Phoenix Framework Update"
date: 2015-10-14T19:20:48+09:00
---

# phoenix 가 업그레이드 되었다

새로 프로젝트를 만들었는데 업데이트 된 내용때문에 동작을 안합니다.


에러메시지

~~~
...
== Compilation error on file lib/blocks_complaint/endpoint.ex ==
** (CompileError) lib/blocks_complaint/endpoint.ex:1: function router/2 undefined   
    (stdlib) lists.erl:1337: :lists.foreach/2
    (stdlib) erl_eval.erl:669: :erl_eval.do_apply/6

~~~


# phoenix 새로 업그레이드

~~~
mix archive.install https://github.com/phoenixframework/phoenix/releases/download/v1.0.3/phoenix_new-1.0.3.ez
~~~

이러면 간단히 됩니다.
프로젝트는 그냥 새로 만드는게 ... ㅜ.ㅠ

# mix 업그레이드

~~~
mix local.hex
~~~

안되면...

~~~
git clone https://github.com/hexpm/hex.git
cd hex
mix install
~~~

