# Fuzzyurl

Non-strict parsing, manipulation, and fuzzy matching of URLs in Elixir.

[![Build Status](https://travis-ci.org/gamache/fuzzyurl.ex.svg?branch=master)](https://travis-ci.org/gamache/fuzzyurl.ex)
[![Hex.pm Version](http://img.shields.io/hexpm/v/fuzzyurl.svg?style=flat)](https://hex.pm/packages/fuzzyurl)
[![Coverage Status](https://coveralls.io/repos/gamache/fuzzyurl.ex/badge.svg?branch=master&service=github)](https://coveralls.io/github/gamache/fuzzyurl.ex?branch=master)


[The full documentation for Fuzzyurl is
here.](http://hexdocs.pm/fuzzyurl/Fuzzyurl.html)


## Adding Fuzzyurl to Your Project

To use Fuzzyurl with your projects, edit your `mix.exs` file and
add it as a dependency:

```elixir
defp deps do
  [{:fuzzyurl, "~> 0.2"}]
end
```


## Introduction

Fuzzyurl provides two related functions: non-strict parsing of URLs or
URL-like strings into their component pieces (protocol, username, password,
hostname, port, path, query, and fragment), and fuzzy matching of URLs
and URL patterns.

Specifically, URLs that look like this:

    [protocol ://] [username [: password] @] [hostname] [: port] [/ path] [? query] [# fragment]

Fuzzyurls can be constructed using some or all of the above
fields, optionally replacing some or all of those fields with a `*`
wildcard if you wish to use the Fuzzyurl as a URL mask.


## Parsing URLs

    iex> f = Fuzzyurl.from_string("https://api.example.com/users/123?full=true")
    %Fuzzyurl{fragment: nil, hostname: "api.example.com", password: nil, path: "/users/123", port: nil, protocol: "https", query: "full=true", username: nil}
    iex> f.protocol
    "https"
    iex> f.hostname
    "api.example.com"
    iex> f.query
    "full=true"


## Constructing URLs

    iex> f = Fuzzyurl.new(hostname: "example.com", protocol: "http", port: "8080")
    %Fuzzyurl{fragment: nil, hostname: "example.com", password: nil, path: nil, port: "8080", protocol: "http", query: nil, username: nil}
    iex> Fuzzyurl.to_string(f)
    "http://example.com:8080"


## Matching URLs

Fuzzyurl supports wildcard matching:

* `*` matches anything, including `nil`.
* `foo*` matches `foo`, `foobar`, `foo/bar`, etc.
* `*bar` matches `bar`, `foobar`, `foo/bar`, etc.

Path and hostname matching allows the use of a greedier wildcard `**` in
addition to the naive wildcard `*`:

* `*.example.com` matches `filsrv-01.corp.example.com` but not `example.com`.
* `**.example.com` matches `filsrv-01.corp.example.com` and `example.com`.
* `/some/path/*` matches `/some/path/foo/bar` and `/some/path/`
   but not `/some/path`
* `/some/path/**` matches `/some/path/foo/bar` and `/some/path/`
   and `/some/path`

The `Fuzzyurl.mask/0` and `Fuzzyurl.mask/1` functions aid in the
creation of URL masks.

    iex> m = Fuzzyurl.mask
    %Fuzzyurl{fragment: "*", hostname: "*", password: "*", path: "*", port: "*", protocol: "*", query: "*", username: "*"}
    iex> Fuzzyurl.matches?(m, "http://example.com/a/b/c")
    true

    iex> m2 = Fuzzyurl.mask(path: "/a/b/**")
    %Fuzzyurl{fragment: "*", hostname: "*", password: "*", path: "/a/b/**", port: "*", protocol: "*", query: "*", username: "*"}
    iex> Fuzzyurl.matches?(m2, "https://example.com/a/b/")
    true
    iex> Fuzzyurl.matches?(m2, "git+ssh://jen@example.com/a/b")
    true
    iex> Fuzzyurl.matches?(m2, "https://example.com/a/bar")
    false

`Fuzzyurl.best_match`, given a list of URL masks and a URL, will return
the mask which most closely matches the URL:

    iex> masks = ["/foo/*", "/foo/bar", Fuzzyurl.mask]
    iex> Fuzzyurl.best_match(masks, "http://example.com/foo/bar")
    %Fuzzyurl{fragment: "*", hostname: "*", password: "*", path: "/foo/bar", port: "*", protocol: "*", query: "*", username: "*"}


## Authorship and License

Fuzzyurl is copyright 2015, Pete Gamache.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

