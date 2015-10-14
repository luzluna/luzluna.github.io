---
layout: post
title: "Perl ZooKeeper BugFix"
date: 2013-05-20T00:00:00+09:00
---


## ZooKeeper Perl BugFix

~~~
In ZooKeeper Stable Release version (3.4.5) has 2 bugs.
~~~

# 1. Fisrst one is 100% CPU usage bug.

it's from  pthread_cond_timedwait() function parameter time value calculation misstake.

{% highlight C %}
 int pthread_cond_timedwait(pthread_cond_t *restrict cond, 
	pthread_mutex_t *restrict mutex, 
	const struct timespec *restrict abstime);
{% endhighlight %}

last parameter is abstime. but code was relative time. patch is in here.

https://github.com/chrisa/perl-Net-ZooKeeper/commit/26c87fe751e075dda0308533ca18942a928cb5d8

{% highlight C %}
@@ -2603,6 +2603,7 @@ zkw_wait(zkwh, ...)
         zk_watch_t *watch;
         unsigned int timeout;
         struct timeval end_timeval;
+        struct timespec wait_timespec;
         int i, done;
     PPCODE:
         watch = _zkw_get_handle_outer(aTHX_ zkwh, NULL);
@@ -2630,30 +2631,16 @@ zkw_wait(zkwh, ...)
         end_timeval.tv_sec += timeout / 1000;
         end_timeval.tv_usec += (timeout % 1000) * 1000;

+        wait_timespec.tv_sec = end_timeval.tv_sec + 0;
+        wait_timespec.tv_nsec = end_timeval.tv_usec * 1000;
+
         pthread_mutex_lock(&watch->mutex);

         while (!watch->done) {
-            struct timeval curr_timeval;
-            struct timespec wait_timespec;
-
-            gettimeofday(&curr_timeval, NULL);
-
-            wait_timespec.tv_sec = end_timeval.tv_sec - curr_timeval.tv_sec;
-            wait_timespec.tv_nsec =
-                (end_timeval.tv_usec - curr_timeval.tv_usec) * 1000;
-
-            if (wait_timespec.tv_nsec < 0) {
-                --wait_timespec.tv_sec;
-                wait_timespec.tv_nsec += 1000000000;
-            }
-
-            if (wait_timespec.tv_sec < 0 ||
-                (wait_timespec.tv_sec == 0 && wait_timespec.tv_nsec <= 0)) {
-                break;
-            }
-
-            pthread_cond_timedwait(&watch->cond, &watch->mutex,
-                                   &wait_timespec);
+            int err = pthread_cond_timedwait(&watch->cond, &watch->mutex,
+                                             &wait_timespec);
+            if (err == ETIMEDOUT)
+              break;
         }

         done = watch->done;
{% endhighlight %}


# 2. Second one is doublely linked list delete code bug. it can lead to segfault or infinity loop sometimes.

patch is in here.

[https://issues.apache.org/jira/browse/ZOOKEEPER-1380](https://issues.apache.org/jira/browse/ZOOKEEPER-1380)


{% highlight C %}
@@ -251,12 +251,12 @@
     if (list) {
         if (watch->prev) {
             watch->prev->next = watch->next;
-            watch->prev = NULL;
         }
         if (watch->next) {
             watch->next->prev = watch->prev;
-            watch->next = NULL;
         }
+        watch->prev = NULL;
+        watch->next = NULL;
     }

     if (--watch->ref_count == 0) {
{% endhighlight %}

