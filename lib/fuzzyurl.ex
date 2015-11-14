defmodule Fuzzyurl do
  defstruct protocol: "*",
            username: "*",
            password: "*",
            hostname: "*",
            port: "*",
            path: "*",
            query: "*",
            fragment: "*"

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
end

