defmodule Fuzzyurl.StringsTest do
  use ExSpec, async: true


  context "from_string" do
    import Fuzzyurl.Strings, only: [from_string: 1]

    it "handles simple URLs" do
      assert({:ok, _} = from_string("http://example.com"))
      assert({:ok, _} = from_string("ssh://user:pass@host"))
      assert({:ok, _} = from_string("https://example.com:443/omg/lol"))
      assert({:ok, _} = from_string(""))
    end

    it "rejects bullshit" do
      assert({:error, _} = from_string(nil))
      assert({:error, _} = from_string(22))
    end

    it "handles rich URLs" do
      assert({:ok, fu} = from_string("http://user_1:pass%20word@foo.example.com:8000/some/path?awesome=true&encoding=ebcdic#/hi/mom"))
      assert("http" == fu.protocol)
      assert("user_1" == fu.username)
      assert("pass%20word" == fu.password)
      assert("foo.example.com" == fu.hostname)
      assert("8000" == fu.port)
      assert("/some/path" == fu.path)
      assert("awesome=true&encoding=ebcdic" == fu.query)
      assert("/hi/mom" == fu.fragment)
    end

  end

  context "to_string" do
    it "handles simple URLs" do
      assert("example.com" == Fuzzyurl.Strings.to_string(%Fuzzyurl{
        hostname: "example.com"}))
      assert("http://example.com" == Fuzzyurl.Strings.to_string(%Fuzzyurl{
        protocol: "http", hostname: "example.com"}))
      assert("http://example.com/oh/yeah" == Fuzzyurl.Strings.to_string(%Fuzzyurl{
        protocol: "http", hostname: "example.com", path: "/oh/yeah"}))
    end

    it "handles rich URLs" do
      fu = %Fuzzyurl{
        protocol: "https",
        username: "usah",
        password: "pash",
        hostname: "api.example.com",
        port: "443",
        path: "/secret/endpoint",
        query: "admin=true",
        fragment: "index"
      }
      assert(Fuzzyurl.Strings.to_string(fu) ==
        "https://usah:pash@api.example.com:443/secret/endpoint?admin=true#index")
    end

  end
end
