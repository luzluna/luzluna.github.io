---
layout: post
title: "Perl new feature PERL_NEW_COPY_ON_WRITE benchmark"
date: 2013-06-21T00:00:00+09:00
---


##  PERL_NEW_COPY_ON_WRITE feature test.

In 5.18.0 optional. 5.19.1 default.

to build with Copy on write feature.


{% highlight bash %}
perlbrew -v install perl-5.18.0 --as perl-5.18cow -D=usethreads \
    -Accflags=-DPERL_NEW_COPY_ON_WRIT
{% endhighlight %}




then benchmark source is

{% highlight perl %}
use Benchmark;
sub A {my ($s) = @_; length($s) }
sub B { my ($s) = @_; $s .= "B"; length($s) }
Benchmark::cmpthese(1000000,{
   test => sub { my $s = 'A'x50000; A($s) },
   test2 => sub { my $s = 'A'x50000; B($s) }
});
{% endhighlight %}


# benchmark result

system defaul perl 5.14.2

{% highlight bash %}
$ /usr/bin/perl bench2.pl 
          Rate  test test2
test  156740/s    --   -0%
test2 157233/s    0%    --
{% endhighlight %}


without PERL_NEW_COPY_ON_WRITE 5.18.0

{% highlight bash %}
$ perl bench2.pl 
          Rate test2  test
test2 215054/s    --   -2%
test  218341/s    2%    --
{% endhighlight %}

with PERL_NEW_COPY_ON_WRITE 5.18.0

{% highlight bash %}
$ perl bench2.pl 
          Rate test2  test
test2 210970/s    --  -48%
test  406504/s   93%    --
{% endhighlight %}


# Result

|test	|5.16.2	|5.18.0	|5.18.0cow |
|------:|------:|------:|---------:|
|ops	|156740/s	|218341/s	|406504/s |
|%	|0%	|+39.3%	|159.3% |

