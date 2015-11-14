defmodule Fuzzyurl.ProtocolsTest do
  use ExSpec, async: true
  import Fuzzyurl.Protocols

  describe "get_port" do
    it "gets port by protocol" do
      assert("80" == get_port("http"))
      assert("22" == get_port("ssh"))
      assert("22" == get_port("git+ssh"))
    end
  end

  describe "get_protocol" do
    it "gets protocol by port" do
      assert("http" == get_protocol("80"))
      assert("http" == get_protocol(80))
    end
  end
end
