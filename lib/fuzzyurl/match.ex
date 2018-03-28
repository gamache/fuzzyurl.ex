defmodule Fuzzyurl.Match do
  @doc ~S"""
  Returns an integer representing how closely `mask` (which may have
  wildcards) resembles `url` (which may not), or `nil` in the
  case of a conflict.
  """
  @spec match(%Fuzzyurl{}, %Fuzzyurl{}) :: non_neg_integer | nil
  def match(%Fuzzyurl{} = mask, %Fuzzyurl{} = url) do
    scores = match_scores(mask, url) |> Map.from_struct() |> Map.values()
    if Enum.member?(scores, nil), do: nil, else: Enum.sum(scores)
  end

  @doc ~S"""
  Returns `true` if `mask` (which may contain wildcards) matches `url`
  (which may not), or `false` otherwise.
  """
  @spec matches?(%Fuzzyurl{}, %Fuzzyurl{}) :: boolean
  def matches?(%Fuzzyurl{} = mask, %Fuzzyurl{} = url) do
    if match(mask, url) == nil, do: false, else: true
  end

  @doc ~S"""
  Returns a Fuzzyurl struct containing values representing how well different
  parts of `mask` and `url` match.  Values are integer; higher values indicate
  closer matches.
  """
  @spec match_scores(%Fuzzyurl{}, %Fuzzyurl{}) :: %Fuzzyurl{}
  def match_scores(%Fuzzyurl{} = mask, %Fuzzyurl{} = url) do
    ## Infer port from protocol, and vice versa.
    url_protocol = url.protocol || Fuzzyurl.Protocols.get_protocol(url.port)
    protocol_score = fuzzy_match(mask.protocol, url_protocol)
    url_port = url.port || Fuzzyurl.Protocols.get_port(url.protocol)
    port_score = fuzzy_match(mask.port, url_port)

    %Fuzzyurl{
      protocol: protocol_score,
      username: fuzzy_match(mask.username, url.username),
      password: fuzzy_match(mask.password, url.password),
      hostname: fuzzy_match(mask.hostname, url.hostname),
      port: port_score,
      path: fuzzy_match(mask.path, url.path),
      query: fuzzy_match(mask.query, url.query),
      fragment: fuzzy_match(mask.fragment, url.fragment)
    }
  end

  @doc ~S"""
  Returns 0 for wildcard match, 1 for exact match, or nil otherwise.

  Wildcard language:

      *              matches anything
      foo/*          matches "foo/" and "foo/bar/baz" but not "foo"
      foo/**         matches "foo/" and "foo/bar/baz" and "foo"
      *.example.com  matches "api.v1.example.com" but not "example.com"
      **.example.com matches "api.v1.example.com" and "example.com"

  Any other form is treated as a literal match.
  """
  @spec fuzzy_match(String.t(), String.t()) :: 0 | 1 | nil
  def fuzzy_match(mask, value) when is_binary(mask) and is_binary(value) do
    case {mask, value, String.reverse(mask), String.reverse(value)} do
      {"*", _, _, _} ->
        0

      {x, x, _, _} ->
        1

      {"**." <> m, v, _, _} ->
        if m == v or String.ends_with?(v, "." <> m), do: 0, else: nil

      {"*" <> m, v, _, _} ->
        if String.ends_with?(v, m), do: 0, else: nil

      {_, _, "**/" <> m, v} ->
        if m == v or String.ends_with?(v, "/" <> m), do: 0, else: nil

      {_, _, "*" <> m, v} ->
        if String.ends_with?(v, m), do: 0, else: nil

      _ ->
        nil
    end
  end

  def fuzzy_match("*", nil), do: 0
  def fuzzy_match(_, nil), do: nil
  def fuzzy_match(nil, _), do: nil

  @doc ~S"""
  From a list of Fuzzyurl masks, returns the list index of the one which
  best matches `url`.  Returns nil if none of `masks` match.

      iex> masks = [Fuzzyurl.mask(path: "/foo/*"), Fuzzyurl.mask(path: "/foo/bar"), Fuzzyurl.mask]
      iex> Fuzzyurl.Match.best_match_index(masks, Fuzzyurl.from_string("http://exmaple.com/foo/bar"))
      1
  """
  def best_match_index(masks, url) do
    masks
    |> Enum.with_index()
    |> Enum.map(fn {m, i} -> {i, match(m, url)} end)
    |> Enum.filter(fn {_i, score} -> score != nil end)
    |> Enum.sort(fn {_ia, a}, {_ib, b} -> a >= b end)
    |> List.first()
    |> elem(0)
  end
end
