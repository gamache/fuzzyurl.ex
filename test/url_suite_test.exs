defmodule Fuzzyurl.UrlSuiteTest do
  use ExSpec, async: true

  @matches File.read!("./test/matches.json") |> Jason.decode!()

  context "URL test suite" do
    it "handles all positive matches" do
      @matches["positive_matches"]
      |> Enum.map(fn
        [mask, url] -> assert(Fuzzyurl.matches?(mask, url), "'#{mask}' should match '#{url}'")
        _ -> nil
      end)
    end

    it "handles all negative matches" do
      @matches["negative_matches"]
      |> Enum.map(fn
        [mask, url] -> refute(Fuzzyurl.matches?(mask, url), "'#{mask}' should not match '#{url}'")
        _ -> nil
      end)
    end
  end
end
