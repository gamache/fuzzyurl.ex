defmodule FuzzyurlTest do
  use ExSpec, async: true
  doctest Fuzzyurl

  context "new/8" do
    it "returns the correct Fuzzyurl" do
      fu = %Fuzzyurl{
        protocol: "1",
        username: "2",
        password: "3",
        hostname: "4",
        port: "5",
        path: "6",
        query: "7",
        fragment: "8"
      }

      assert(Fuzzyurl.new("1", "2", "3", "4", "5", "6", "7", "8") == fu)
    end
  end

  context "new/0" do
    it "returns a blank Fuzzyurl" do
      assert(%Fuzzyurl{} == Fuzzyurl.new())
    end
  end

  context "new/1 with kwlist or map" do
    it "returns the correct Fuzzyurl" do
      fu = %Fuzzyurl{hostname: "example.com"}
      assert(fu == Fuzzyurl.new(hostname: "example.com"))
      assert(fu == Fuzzyurl.new(%{hostname: "example.com"}))
    end
  end

  context "from_string" do
    it "creates Fuzzyurl from string" do
      fu = %Fuzzyurl{protocol: "http", hostname: "example.com", path: "/index.html"}
      assert(fu == Fuzzyurl.from_string("http://example.com/index.html"))
    end

    it "raises on invalid input" do
      assert_raise ArgumentError, fn ->
        Fuzzyurl.from_string("http:\\\\blah")
      end
    end
  end

  context "to_string" do
    it "creates string from Fuzzyurl" do
      fu = Fuzzyurl.new(protocol: "http", hostname: "example.com")
      assert("http://example.com" == Fuzzyurl.to_string(fu))
    end
  end

  context "mask/0" do
    it "creates the correct Fuzzyurl" do
      fu = %Fuzzyurl{
        protocol: "*",
        username: "*",
        password: "*",
        hostname: "*",
        port: "*",
        path: "*",
        query: "*",
        fragment: "*"
      }

      assert(fu == Fuzzyurl.mask())
    end
  end

  context "mask/1" do
    it "creates the correct Fuzzyurl" do
      fu = %Fuzzyurl{
        protocol: "*",
        username: "*",
        password: "*",
        hostname: "example.com",
        port: "*",
        path: "*",
        query: "*",
        fragment: "*"
      }

      assert(fu == Fuzzyurl.mask(hostname: "example.com"))
      assert(fu == Fuzzyurl.mask(%{hostname: "example.com"}))
    end
  end

  context "with" do
    it "creates the correct Fuzzyurl" do
      fu = %Fuzzyurl{
        protocol: "*",
        username: "*",
        password: "*",
        hostname: "example.com",
        port: "*",
        path: "*",
        query: "*",
        fragment: "*"
      }

      fu2 = %Fuzzyurl{
        protocol: "http",
        username: "*",
        password: "*",
        hostname: "example.com",
        port: "*",
        path: "/foo",
        query: "*",
        fragment: "*"
      }

      assert(fu2 == Fuzzyurl.with(fu, protocol: "http", path: "/foo"))
      assert(fu2 == Fuzzyurl.with(fu, %{protocol: "http", path: "/foo"}))
    end
  end

  context "match" do
    it "is delegated" do
      assert(0 = Fuzzyurl.match(Fuzzyurl.mask(), Fuzzyurl.new()))
    end
  end

  context "matches?" do
    it "is delegated" do
      assert(true = Fuzzyurl.matches?(Fuzzyurl.mask(), Fuzzyurl.new()))
    end
  end

  context "match_scores" do
    it "is delegated" do
      assert(%{} = Fuzzyurl.match_scores(Fuzzyurl.mask(), Fuzzyurl.new()))
    end
  end

  context "best_match" do
    it "is delegated" do
      assert(%Fuzzyurl{} = Fuzzyurl.best_match([Fuzzyurl.mask()], Fuzzyurl.new()))
    end
  end

  context "best_match_index" do
    it "is delegated" do
      assert(0 == Fuzzyurl.best_match_index([Fuzzyurl.mask()], Fuzzyurl.new()))
    end
  end
end
