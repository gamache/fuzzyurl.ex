defmodule Fuzzyurl.MatchTest do
  use ExSpec, async: true
  import Fuzzyurl.Match
  doctest Fuzzyurl.Match

  describe "fuzzy_match" do
    it "returns 0 for full wildcard" do
      assert(0 == fuzzy_match("*", "lol"))
      assert(0 == fuzzy_match("*", "*"))
      assert(0 == fuzzy_match("*", nil))
    end

    it "returns 1 for exact match" do
      assert(1 == fuzzy_match("asdf", "asdf"))
    end

    it "handles *.example.com" do
      assert(0 == fuzzy_match("*.example.com", "api.v1.example.com"))
      assert(:no_match == fuzzy_match("*.example.com", "example.com"))
    end

    it "handles **.example.com" do
      assert(0 == fuzzy_match("**.example.com", "api.v1.example.com"))
      assert(0 == fuzzy_match("**.example.com", "example.com"))
      assert(:no_match == fuzzy_match("**.example.com", "zzzexample.com"))
    end

    it "handles path/*" do
      assert(0 == fuzzy_match("path/*", "path/a/b/c"))
      assert(:no_match == fuzzy_match("path/*", "path"))
    end

    it "handles path/**" do
      assert(0 == fuzzy_match("path/**", "path/a/b/c"))
      assert(0 == fuzzy_match("path/**", "path"))
      assert(:no_match == fuzzy_match("path/**", "pathzzz"))
    end

    it "returns :no_match for bad matches with no wildcards" do
      assert(:no_match == fuzzy_match("asdf", "oh no"))
    end
  end


  describe "match" do
    it "returns 0 for full wildcard" do
      assert(0 == match(Fuzzyurl.mask, Fuzzyurl.new))
    end

    it "returns 8 for full exact match" do
      fu = Fuzzyurl.new("a", "b", "c", "d", "e", "f", "g", "h")
      assert(8 == match(fu, fu))
    end

    it "returns 1 for one exact match" do
      mask = %{Fuzzyurl.mask | hostname: "example.com"}
      url = %Fuzzyurl{hostname: "example.com", protocol: "http", path: "/index.html"}
      assert(1 == match(mask, url))
    end

    it "infers protocol from port" do
      mask = %{Fuzzyurl.mask | port: "80"}
      url = %Fuzzyurl{protocol: "http"}
      assert(1 == match(mask, url))
      assert(:no_match == match(mask, %Fuzzyurl{url | port: "443"}))
    end

    it "infers port from protocol" do
      mask = %{Fuzzyurl.mask | protocol: "https"}
      url = %Fuzzyurl{port: "443"}
      assert(1 == match(mask, url))
      assert(:no_match == match(mask, %Fuzzyurl{url | protocol: "http"}))
    end
  end


  describe "matches?" do
    it "returns true on matches" do
      assert(true == matches?(Fuzzyurl.mask, Fuzzyurl.new))
    end

    it "returns false on non-matches" do
      assert(false == matches?(Fuzzyurl.mask(port: "666"), Fuzzyurl.new))
    end
  end


  describe "match_scores" do
    it "returns all zeroes for full wildcard" do
      scores = match_scores(Fuzzyurl.mask, Fuzzyurl.new)
               |> Map.from_struct
               |> Map.values
      assert(false == Enum.any?(scores, fn (x) -> x != 0 end))
    end
  end
end

