This was an attempt to get [Hockeypuck](https://hockeypuck.io), a pgp keyserver, onto the [Sandstorm](https://sandstorm.org) platform. As of now I don't think it will work with the `gpg` command line tool, and as such it's kind of pointless IMHO.

The Hockeypuck integration (not Hockeypuck itself) was written by Daniel Krol.

The postgres part was courtesy of [Troy Farrell](https://github.com/troyjfarrell), though he is working on improving this. If you're looking to do the same in your app, check out what he and/or the [Sandstorm project](https://sandstorm.org/community) may have said about this recently for the latest.

# Why I suspect this can't work

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

## Possible Solutions

**`/.sandstorm-token/<token>/some/path`** - [I missed this](https://docs.sandstorm.io/en/latest/developing/http-apis/). The workaround for websockets has the option of putting the token into the path. Would this concession work for https as well? Would be nice. Also, the `/some/path` portion gets passed to my grain, which I actually need as well. I'm not sure if the normal http api export gives us that either.

**Curl + GPG** - This would be ugly, but maybe there's some sort of command that we could give users that chains curl and gpg to recreate recv-keys and send-key. Something like `curl https://username:password@whatever.yourserver.sandcats.io | gpg --import` and `gpg --export yourkey | curl -X POST -d @- https://username:password@whatever.yourserver.sandcats.io`. But at that point I could just as well invent my own protocol on the server end as well, and it doesn't need to be a normal keyserver.

**Proxy** - If there were some sort of one-line proxy that a user could run, which only required common, trusted software, that could add the http auth headers to the gpg request, maybe we could make it work. Anything more than that, it would just bad UX.

**SequoiaPGP**: Another thought - what about trying [Sequoia](https://sequoia-pgp.org/) to see if it passes on auth headers? The problem (to me) is, it hasn't passed a [security audit](https://sequoia-pgp.org/status/) due to lack of funding. But for some reason 1) It's in the Debian repository and 2) It's been adopted by [SecureDrop](https://securedrop.org/news/migrating-securedrops-pgp-backend-from-gnupg-to-sequoia/). So maybe it's okay?

**Sandstorm static publishing** Maybe we could set up static publishing for read-only (`--recv-keys`, etc) keyserver transactions. It would need to match gpg's query strings perfectly, though, I think. Who knows if it'll change format within the spec.

# License

The files in the repository are dual-licensed under the MIT and Apache 2.0
licenses, with the exception of the `util` directory, which contains its own
release from copyright (CC0).

Hockeypuck is licensed as AGPL: https://github.com/hockeypuck/hockeypuck/blob/master/src/hockeypuck/server/LICENSE
