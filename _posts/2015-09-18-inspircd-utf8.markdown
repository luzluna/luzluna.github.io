---
layout: post
title: "inspircd utf8"
date: 2015-09-18 15:05:03 +0900
comments: true
categories: 
---


utf8 한글 지원 방법

modules.conf 에 다음과 같이 추가하면 한글 닉을 사용할 수 있습니다.

{% highlight xml %}
<module name="m_nationalchars.so">
<nationalchars file="cjk-utf8">
{% endhighlight %}

이러고나면 locales/cjk-utf8 파일을 필요로 합니다.
그런데 디렉토리 위치가 inspircd 디렉토리와 같은 경로 아래에 있어야 합니다.

{% highlight bash %}
cd ~/inspircd
cd ..
mkdir locales
cd locales
cp ~/src/inspircd-2.0.20/locales/cjk-utf8 ./
{% endhighlight %}

대충 이런식이면 됩니다. locales 디렉토리가 inspircd아래가 아니라니 찜찜하네요 -_-;; 뒤 안닦은 기분


