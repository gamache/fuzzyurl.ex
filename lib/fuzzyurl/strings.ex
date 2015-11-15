defmodule Fuzzyurl.Strings do

  @regex ~r"""
    ^
    (?: (?<protocol> \* | [a-zA-Z][A-Za-z+.-]+) ://)?
    (?: (?<username> \* | [a-zA-Z0-9%_.!~*'();&=+$,-]+)
        (?: : (?<password> \* | [a-zA-Z0-9%_.!~*'();&=+$,-]*))?
        @
    )?
    (?<hostname> [a-zA-Z0-9\.\*\-]+?)?
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
  @spec from_string(String.t, []) :: {:ok, %Fuzzyurl{}} | {:error, String.t}
  def from_string(string, opts \\ [])

  def from_string(string, opts) when is_binary(string) do
    case Regex.named_captures(@regex, string) do
      nil ->
        {:error, "input string couldn't be parsed"}
      nc ->
        dv = opts[:default_value]
        blank_fu = Fuzzyurl.new(dv, dv, dv, dv, dv, dv, dv, dv)
        fu = nc
             |> Map.to_list
             |> Enum.reduce(blank_fu, fn ({k,v}, acc) ->
                  if v != "" do
                    Map.put(acc, String.to_atom(k), v)
                  else
                    acc
                  end
                end)
        {:ok, fu}
    end
  end

  def from_string(_, _) do
    {:error, "input argument must be a string"}
  end


  @doc ~S"""
  Returns a string representation of the given Fuzzyurl.
  """
  @spec to_string(%Fuzzyurl{}) :: String.t
  def to_string(%Fuzzyurl{}=fu) do
    url_pieces = [
      (if fu.protocol, do: "#{fu.protocol}://", else: ""),
      (if fu.username, do: "#{fu.username}",    else: ""),
      (if fu.password, do: ":#{fu.password}",   else: ""),
      (if fu.username, do: "@",                 else: ""),
      (if fu.hostname, do: "#{fu.hostname}",    else: ""),
      (if fu.port,     do: ":#{fu.port}",       else: ""),
      (if fu.path,     do: "#{fu.path}",        else: ""),
      (if fu.query,    do: "?#{fu.query}",      else: ""),
      (if fu.fragment, do: "##{fu.fragment}",   else: "")
    ]
    url_pieces |> Enum.join
  end

end
