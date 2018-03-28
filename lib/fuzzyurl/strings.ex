defmodule Fuzzyurl.Strings do
  @moduledoc ~S"""
  Functions to parse a string URL into a Fuzzyurl, and vice versa.
  """

  ## this regex matches URLs like this:
  ## [protocol ://] [username [: password] @] [hostname] [: port] [/ path] [? query] [# fragment]
  @regex ~r"""
    ^
    (?: (?<protocol> \* | [a-zA-Z][A-Za-z+.-]+) ://)?
    (?: (?<username> \* | [a-zA-Z0-9%_.!~*'();&=+$,-]+)
        (?: : (?<password> \* | [a-zA-Z0-9%_.!~*'();&=+$,-]*))?
        @
    )?
    (?<hostname> [a-zA-Z0-9\.\*\-_]+?)?
    (?: : (?<port> \* | \d+))?
    (?<path> / [^\?\#]*)?                 ## captures leading /
    (?: \? (?<query> [^\#]*) )?
    (?: \# (?<fragment> .*) )?
    $
  """x

  @doc ~S"""
  Attempts to parse the given string as a URL, and returns either
  {:ok, fuzzy_url} or {:error, message}.
  """
  @spec from_string(String.t(), Keyword.t()) :: {:ok, Fuzzyurl.t()} | {:error, String.t()}
  def from_string(string, opts \\ [])

  def from_string(string, opts) when is_binary(string) do
    case Regex.named_captures(@regex, string) do
      nil ->
        {:error, "input string couldn't be parsed"}

      nc ->
        {:ok, from_named_captures(nc, opts)}
    end
  end

  def from_string(_, _) do
    {:error, "input argument must be a string"}
  end

  defp from_named_captures(nc, opts) do
    # default nil
    dv = opts[:default]
    blank_fu = Fuzzyurl.new(dv, dv, dv, dv, dv, dv, dv, dv)

    nc
    |> Map.to_list()
    |> Enum.reduce(blank_fu, fn {k, v}, acc ->
      if v != "" do
        Map.put(acc, String.to_atom(k), v)
      else
        acc
      end
    end)
  end

  @doc ~S"""
  Returns a string representation of the given Fuzzyurl.
  """
  @spec to_string(%Fuzzyurl{}) :: String.t()
  def to_string(%Fuzzyurl{} = fu) do
    url_pieces = [
      if(fu.protocol, do: "#{fu.protocol}://", else: ""),
      if(fu.username, do: "#{fu.username}", else: ""),
      if(fu.password, do: ":#{fu.password}", else: ""),
      if(fu.username, do: "@", else: ""),
      if(fu.hostname, do: "#{fu.hostname}", else: ""),
      if(fu.port, do: ":#{fu.port}", else: ""),
      if(fu.path, do: "#{fu.path}", else: ""),
      if(fu.query, do: "?#{fu.query}", else: ""),
      if(fu.fragment, do: "##{fu.fragment}", else: "")
    ]

    url_pieces |> Enum.join()
  end
end
