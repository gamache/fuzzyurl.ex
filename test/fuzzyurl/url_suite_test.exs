defmodule Fuzzyurl.UrlSuiteTest do
  use ExSpec, async: true

  @matches ~S"""
    *                     http://example.com
    *                     http://example.com/
    *                     https://example.com/
    *                     http://username:password@api.example.com/v1
    *                     http://example.com/Q@(@*&%&!
    *                     http://example.com
    *                     http://user:pass@example.com:12345/some/path%20?query=true&foo=bar#frag

    http://*              http://example.com
    http://*              http://example.com:80
    http://*              http://example.com:8080
    http://*              http://example.com/some/path?args=1

    example.com           example.com
    example.com           example.com:80
    example.com           example.com/a/b/c
    example.com           example.com:80/a/b/c
    example.com           http://example.com
    example.com           http://example.com/some/path?args=1
    example.com           http://example.com:80/
    example.com           http://example.com

    example.com/a/*       example.com/a/b/c

    https://example.com   example.com:443
    http://example.com    example.com:80

    *.example.com         api.example.com
    *.example.com         xxx.yyy.example.com

    example.com:8080      example.com:8080
    localhost:12345       localhost:12345

    user:pass@host        http://user:pass@host/some/path?q=1

    *.example.com:80      http://www.example.com/index.html
    example.com:443       https://example.com/

    svn+ssh://user@example.com   svn+ssh://user:pass@example.com/some/path
  """

  @negative_matches ~S"""
    http://*              https://example.com
    https://*             http://example.com

    http://example.com    http://www.example.com

    *.example.com         example.com

    example.com/a/*       example.com/b/a/b/c
    example.com/a/*       foobar.com/a/b/c

    example.com:888       example.com:8888

    user:pass@host        http://user:@host/some/path?q=1
    user:pass@host        http://user@host/some/path?q=1
  """

  describe "URL test suite" do
    it "handles all positive matches" do
      @matches
      |> String.split("\n")
      |> Enum.map(fn (s) -> String.strip(s) end)
      |> Enum.map(fn (s) -> String.split(s, ~r"\s+") end)
      |> Enum.map(fn
           ([mask, url]) -> assert(Fuzzyurl.matches?(mask, url), "#{mask} #{url}")
           _ -> nil
         end)
    end

    it "handles all negative matches" do
      @negative_matches
      |> String.split("\n")
      |> Enum.map(fn (s) -> String.strip(s) end)
      |> Enum.map(fn (s) -> String.split(s, ~r"\s+") end)
      |> Enum.map(fn
           ([mask, url]) -> refute(Fuzzyurl.matches?(mask, url), "#{mask} #{url}")
           _ -> nil
         end)
    end
  end

end
