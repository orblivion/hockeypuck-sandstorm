This was an attempt to get [Hockeypuck](https://hockeypuck.io), a pgp keyserver, onto the [Sandstorm](https://sandstorm.org) platform. As of now I don't think it will work with the `gpg` command line tool, and as such it's kind of pointless IMHO.

The Hockeypuck integration (not Hockeypuck itself) was written by Daniel Krol.

The postgres part was courtesy of [Troy Farrell](https://github.com/troyjfarrell), though he is working on improving this. If you're looking to do the same in your app, check out what he and/or the [Sandstorm project](https://sandstorm.org/community) may have said about this recently for the latest.

# Why this can't work

My intention was to expose a sandstorm [HTTP API](https://docs.sandstorm.io/en/latest/developing/http-apis/), and instruct users who interact with it to specify a special keyserver URL that would send the necessary auth headers. This works for some applications, such as curl or any web browser.

Does it work for GnuPG? Keyservers have a few different protocols. The one that seems most likely to work for us is called hkps, which goes over https. Let's test if we can specify auth headers in the URL to send auth headers. To make this test simpler, I used hkp which goes over plain http.

I threw together a python server that output the headers it received. For reference, you can see the Authorization header show up if I put the basic auth in the URL for curl:

```
> curl http://username:password@localhost:8000
```

```
Host: localhost:8000
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
User-Agent: curl/7.74.0
Accept: */*


127.0.0.1 - - [22/Apr/2024 23:30:42] "GET / HTTP/1.1" 200 -
```

For gpg, first let's try to request a key over hpk without the basic auth: 

```
> gpg --keyserver hkp://localhost:8000 --recv-keys 0x0000000000000000
gpg: no valid OpenPGP data found.
gpg: Total number processed: 0
```

```
Host: localhost:8000
Pragma: no-cache
Cache-Control: no-cache


127.0.0.1 - - [22/Apr/2024 23:30:56] "GET /pks/lookup?op=get&options=mr&search=0x0000000000000000 HTTP/1.0" 200 -
```

Now let's try adding the basic auth to the URL:

```
> gpg --keyserver hkp://username:password@localhost:8000 --recv-keys 0x0000000000000000
gpg: no valid OpenPGP data found.
gpg: Total number processed: 0
```

```
Host: localhost:8000
Pragma: no-cache
Cache-Control: no-cache


127.0.0.1 - - [22/Apr/2024 23:31:06] "GET /pks/lookup?op=get&options=mr&search=0x0000000000000000 HTTP/1.0" 200 -
```

We get the same thing. Without an auth header, we don't have a way to get past Sandstorm's defenses to even contact our Hockeypuck grain.

## Possible Solution

If there were some sort of one-line proxy that a user could run, which only required common, trusted software, that could add the http auth headers to the gpg request, maybe we could make it work. Anything more than that, it would just bad UX.

Another thought - what about trying [Sequoia](https://sequoia-pgp.org/)? It's even in the debian repository. The problem (to me) is, it hasn't passed a [security audit](https://sequoia-pgp.org/status/) due to lack of funding.

# License

The files in the repository are dual-licensed under the MIT and Apache 2.0
licenses, with the exception of the `util` directory, which contains its own
release from copyright (CC0).

Hockeypuck is licensed as AGPL: https://github.com/hockeypuck/hockeypuck/blob/master/src/hockeypuck/server/LICENSE
