defmodule Fuzzyurl.Match do

  @doc ~S"""
  Returns an integer representing how closely `mask` (which may have
  wildcards) resembles `url` (which may not), or `:no_match` in the
  case of a conflict.
  """
  @spec match(%Fuzzyurl{}, %Fuzzyurl{}) :: non_neg_integer | :no_match
  def match(%Fuzzyurl{}=mask, %Fuzzyurl{}=url) do
    scores = match_scores(mask, url) |> Map.from_struct |> Map.values
    if Enum.member?(scores, :no_match), do: :no_match, else: Enum.sum(scores)
  end


  @doc ~S"""
  Returns `true` if `mask` (which may contain wildcards) matches `url`
  (which may not), or `false` otherwise.
  """
  @spec matches?(%Fuzzyurl{}, %Fuzzyurl{}) :: boolean
  def matches?(%Fuzzyurl{}=mask, %Fuzzyurl{}=url) do
    if match(mask, url) == :no_match, do: false, else: true
  end


  @doc ~S"""
  Returns a Fuzzyurl struct containing values representing how well different
  parts of `mask` and `url` match.  Values are integer; higher values indicate
  closer matches.
  """
  @spec match_scores(%Fuzzyurl{}, %Fuzzyurl{}) :: %Fuzzyurl{}
  def match_scores(%Fuzzyurl{}=mask, %Fuzzyurl{}=url) do
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
  Returns 0 for wildcard match, 1 for exact match, or :no_match otherwise.

  Wildcard language:

      *              matches anything
      foo/*          matches "foo/" and "foo/bar/baz" but not "foo"
      foo/**         matches "foo/" and "foo/bar/baz" and "foo"
      *.example.com  matches "api.v1.example.com" but not "example.com"
      **.example.com matches "api.v1.example.com" and "example.com"

  Any other form is treated as a literal match.
  """
  @spec fuzzy_match(String.t, String.t) :: 0 | 1 | :no_match
  def fuzzy_match(mask, value) when is_binary(mask) and is_binary(value) do
    case {mask, value, String.reverse(mask), String.reverse(value)} do
      {"*", _, _, _} ->
        0
      {x, x, _, _} ->
        1
      {"**." <> m, v, _, _} ->
        if String.ends_with?(v, m), do: 0, else: :no_match
      {"*" <> m, v, _, _} ->
        if String.ends_with?(v, m), do: 0, else: :no_match
      {_, _, "**/" <> m, v} ->
        if String.ends_with?(v, m), do: 0, else: :no_match
      {_, _, "*" <> m, v} ->
        if String.ends_with?(v, m), do: 0, else: :no_match
      _ ->
        :no_match
    end
  end
  def fuzzy_match("*", nil), do: 0
  def fuzzy_match(_, nil), do: :no_match
  def fuzzy_match(nil, _), do: :no_match


end

