defmodule Fuzzyurl do

  ## N.B. when this moduledoc changes, it should be copy/pasted into README.md
  @moduledoc ~S"""
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
      "/foo/bar"

  If you'd prefer the list index of the best-matching URL mask, use
  `Fuzzyurl.best_match_index` instead:

      iex> masks = ["/foo/*", "/foo/bar", Fuzzyurl.mask]
      iex> Fuzzyurl.best_match_index(masks, "http://example.com/foo/bar")
      1
  """

  @type t :: %Fuzzyurl{}
  @type string_or_fuzzyurl :: String.t | Fuzzyurl.t

  alias Fuzzyurl.Match
  alias Fuzzyurl.Strings

  @default [ protocol: nil,
             username: nil,
             password: nil,
             hostname: nil,
             port: nil,
             path: nil,
             query: nil,
             fragment: nil ]

  defstruct @default

  @doc ~S"""
  Creates an empty Fuzzyurl.

      iex> Fuzzyurl.new()
      %Fuzzyurl{fragment: nil, hostname: nil, password: nil, path: nil, port: nil, protocol: nil, query: nil, username: nil}
  """
  @spec new() :: Fuzzyurl.t
  def new(), do: %Fuzzyurl{}

  @doc ~S"""
  Creates a new Fuzzyurl with the given parameters.

      iex> Fuzzyurl.new("http", "user", "pass", "example.com", "80", "/", "query=true", "123")
      %Fuzzyurl{fragment: "123", hostname: "example.com", password: "pass", path: "/", port: "80", protocol: "http", query: "query=true", username: "user"}
  """
  @spec new(String.t, String.t, String.t, String.t, String.t, String.t, String.t, String.t) :: Fuzzyurl.t
  def new(protocol, username, password, hostname, port, path, query, fragment) do
    %Fuzzyurl{
      protocol: protocol,
      username: username,
      password: password,
      hostname: hostname,
      port: port,
      path: path,
      query: query,
      fragment: fragment
    }
  end

  @doc ~S"""
  Creates a new Fuzzyurl with the given parameters.

  `params` may be a map or a keyword list.

      iex> Fuzzyurl.new(hostname: "example.com", protocol: "http")
      %Fuzzyurl{fragment: nil, hostname: "example.com", password: nil, path: nil, port: nil, protocol: "http", query: nil, username: nil}
  """
  @spec new([tuple]) :: Fuzzyurl.t
  def new(params), do: new |> Fuzzyurl.with(params)


  @doc ~S"""
  Returns a new Fuzzyurl based on `fuzzy_url`, with the given arguments
  changed.

  `params` may be a map or a keyword list.

      iex> fuzzy_url = Fuzzyurl.new(hostname: "example.com", protocol: "http")
      iex> fuzzy_url |> Fuzzyurl.with(protocol: "https", path: "/index.html")
      %Fuzzyurl{fragment: nil, hostname: "example.com", password: nil, path: "/index.html", port: nil, protocol: "https", query: nil, username: nil}
  """
  @spec with(Fuzzyurl.t, map) :: Fuzzyurl.t
  def with(fuzzy_url, %{} = params) do
    Fuzzyurl.with(fuzzy_url, Map.to_list(params))
  end

  @spec with(Fuzzyurl.t, [tuple]) :: Fuzzyurl.t
  def with(fuzzy_url, params) do
    Enum.reduce(params, fuzzy_url, fn ({k,v}, acc) ->
      ## prevent struct damage by checking keys
      if Dict.has_key?(@default, k), do: Map.put(acc, k, v), else: acc
    end)
  end


  @doc ~S"""
  Returns a Fuzzyurl containing all wildcard matches, that will match any
  Fuzzyurl.

      iex> Fuzzyurl.mask()
      %Fuzzyurl{fragment: "*", hostname: "*", password: "*", path: "*", port: "*", protocol: "*", query: "*", username: "*"}
  """
  @spec mask() :: Fuzzyurl.t
  def mask(), do: new("*", "*", "*", "*", "*", "*", "*", "*")

  @doc ~S"""
  Returns a Fuzzyurl mask with the given parameters set.
  `params` may be a map or a keyword list.

      iex> Fuzzyurl.mask(hostname: "example.com")
      %Fuzzyurl{fragment: "*", hostname: "example.com", password: "*", path: "*", port: "*", protocol: "*", query: "*", username: "*"}
  """
  @spec mask(map | [tuple]) :: Fuzzyurl.t
  def mask(params), do: mask |> Fuzzyurl.with(params)


  @doc ~S"""
  Returns an integer representing how closely `mask` (which may have
  wildcards) resembles `url` (which may not), or `nil` in the
  case of a conflict.

  `mask` and `url` may each be a Fuzzyurl or a string.

      iex> Fuzzyurl.match("http://example.com", "http://example.com")
      2
      iex> Fuzzyurl.match("example.com", "http://example.com")
      1
      iex> Fuzzyurl.match("**.example.com", "http://example.com")
      0
      iex> Fuzzyurl.match("*.example.com", "http://example.com")
      nil
  """
  @spec match(string_or_fuzzyurl, string_or_fuzzyurl) :: non_neg_integer | nil
  def match(mask, url) do
    m = if is_binary(mask), do: from_string(mask, default: "*"), else: mask
    u = if is_binary(url), do: from_string(url), else: url
    Match.match(m, u)
  end


  @doc ~S"""
  Returns true if `mask` matches `url`, false otherwise.

  `mask` and `url` may each be a Fuzzyurl or a string.

      iex> mask = Fuzzyurl.mask(hostname: "example.com")
      iex> Fuzzyurl.matches?(mask, "http://example.com")
      true
      iex> Fuzzyurl.matches?(mask, "http://nope.example.com")
      false
  """
  @spec matches?(string_or_fuzzyurl, string_or_fuzzyurl) :: false | true
  def matches?(mask, url) do
    m = if is_binary(mask), do: from_string(mask, default: "*"), else: mask
    u = if is_binary(url), do: from_string(url), else: url
    Match.matches?(m, u)
  end


  @doc ~S"""
  Returns a Fuzzyurl struct containing values indicating match quality:
  0 for a wildcard match, 1 for exact match, and nil otherwise.

  `mask` and `url` may each be a Fuzzyurl or a string.

      iex> mask = Fuzzyurl.mask(hostname: "example.com")
      iex> Fuzzyurl.match_scores(mask, "http://example.com")
      %Fuzzyurl{fragment: 0, hostname: 1, password: 0, path: 0, port: 0, protocol: 0, query: 0, username: 0}
  """
  @spec match_scores(string_or_fuzzyurl, string_or_fuzzyurl) :: Fuzzyurl.t
  def match_scores(mask, url) do
    m = if is_binary(mask), do: from_string(mask, default: "*"), else: mask
    u = if is_binary(url), do: from_string(url), else: url
    Match.match_scores(m, u)
  end


  @doc ~S"""
  From a list of Fuzzyurl masks, returns the one which best matches `url`.
  Returns nil if none of `masks` match.

  `url` and each mask may be a Fuzzyurl or a string.

      iex> masks = ["/foo/*", "/foo/bar", Fuzzyurl.mask]
      iex> Fuzzyurl.best_match(masks, "http://example.com/foo/bar")
      "/foo/bar"
  """
  @spec best_match([string_or_fuzzyurl], string_or_fuzzyurl) :: string_or_fuzzyurl | nil
  def best_match(masks, url) do
    index = best_match_index(masks, url)
    if index, do: Enum.at(masks, index), else: nil
  end


  @doc ~S"""
  From a list of Fuzzyurl masks, returns the list index of the one which
  best matches `url`.  Returns nil if none of `masks` match.

  `url` and each mask may be a Fuzzyurl or a string.

      iex> masks = ["/foo/*", "/foo/bar", Fuzzyurl.mask]
      iex> Fuzzyurl.best_match_index(masks, "http://example.com/foo/bar")
      1
  """
  @spec best_match_index([string_or_fuzzyurl], string_or_fuzzyurl) :: Integer | nil
  def best_match_index(masks, url) do
    masks
    |> Enum.map(fn (m) -> if is_binary(m), do: from_string(m, default: "*"), else: m end)
    |> Match.best_match_index(if is_binary(url), do: from_string(url), else: url)
  end


  @doc ~S"""
  Returns a String representation of `fuzzy_url`.

      iex> fuzzy_url = Fuzzyurl.new(hostname: "example.com", protocol: "http")
      iex> Fuzzyurl.to_string(fuzzy_url)
      "http://example.com"
  """
  @spec to_string(Fuzzyurl.t) :: String.t
  def to_string(%Fuzzyurl{}=fuzzy_url) do
    Strings.to_string(fuzzy_url)
  end


  @doc ~S"""
  Creates a new Fuzzyurl from the given URL string.  Provide `default: "*"`
  when creating a URL mask.

      iex> Fuzzyurl.from_string("http://example.com")
      %Fuzzyurl{fragment: nil, hostname: "example.com", password: nil, path: nil, port: nil, protocol: "http", query: nil, username: nil}
      iex> Fuzzyurl.from_string("*.example.com:443", default: "*")
      %Fuzzyurl{fragment: "*", hostname: "*.example.com", password: "*", path: "*", port: "443", protocol: "*", query: "*", username: "*"}
  """
  @spec from_string(String.t, [tuple]) :: Fuzzyurl.t
  def from_string(string, opts \\ []) when is_binary(string) do
    {:ok, fuzzy_url} = Strings.from_string(string, opts)
    fuzzy_url
  end

end

