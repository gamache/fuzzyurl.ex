defmodule Fuzzyurl.Protocols do
  @ports_by_protocol %{
    "ssh" => "22",
    "http" => "80",
    "https" => "443"
  }

  @protocols_by_port %{
    "22" => "ssh",
    "80" => "http",
    "443" => "https"
  }

  def get_port(nil), do: nil

  def get_port(protocol) do
    base_protocol = protocol |> String.split("+") |> List.last()
    @ports_by_protocol[base_protocol]
  end

  def get_protocol(nil), do: nil

  def get_protocol(port) when is_integer(port) do
    get_protocol(Integer.to_string(port))
  end

  def get_protocol(port) do
    @protocols_by_port[port]
  end
end
