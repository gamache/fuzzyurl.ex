defmodule Fuzzyurl do
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

  def new(), do: %Fuzzyurl{}

  def new(string) when is_binary(string), do: Strings.from_string(string)

  def new(args), do: new |> with(args)


  def with(fuzzy_url, %{} = args), do: with(fuzzy_url, Map.to_list(args))

  def with(fuzzy_url, args) do
    Enum.reduce(args, fuzzy_url, fn ({k,v}, acc) ->
      ## prevent struct damage by checking keys
      if Dict.has_key?(@default, k), do: Map.put(acc, k, v), else: acc
    end)
  end


  def mask(), do: new("*", "*", "*", "*", "*", "*", "*", "*")

  def mask(args), do: mask |> with(args)


  defdelegate [match(mask, url),
               matches?(mask, url),
               match_scores(mask, url),
               fuzzy_match(mask, value)], to: Match

end

