defmodule TftTopperWeb.DataController do
  use TftTopperWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def init(conn, _) do
    info = File.read("winners_info.json")
    init_items(info)
    init_comps(info)

    conn |> send_resp(200, "OK")
  end

  defp init_comps({_, info}) do
    inf =
      info
      |> Jason.decode()
      |> Tuple.to_list()
      |> tl
      |> hd
      |> Enum.map(fn {x, value} ->
        %{
          "traits" =>
            value["traits"]
            |> Enum.reduce(%{}, fn x, acc ->
              if x["tier_current"] > 0 do
                Map.update(acc, x["name"], x["num_units"], fn x -> x end)
              else
                acc
              end
            end)
            |> Map.to_list()
            |> Enum.sort(fn {_, x}, {_, y} -> x > y end)
            |> Enum.into(%{}),
          "units" => [
            value["units"]
            |> Enum.map(fn x -> x["character_id"] end)
            |> Enum.sort()
            |> Enum.uniq()
          ]
        }
      end)
      |> Enum.reduce(%{}, fn x, acc ->
        Map.update(acc, x["traits"], x["units"], fn y ->
          y ++ x["units"]
        end)
      end)
      |> Enum.map(fn {key, value} ->
        %{"traits" => key, "units" => value |> Enum.uniq() |> hd, "comp_count" => value |> length}
      end)

    {:ok, encoded} = Jason.encode(inf, [{:pretty, true}])
    File.write("comps.json", encoded)
  end

  defp init_items({_, info}) do
    inf =
      info
      |> Jason.decode()
      |> Tuple.to_list()
      |> tl
      |> hd
      |> Enum.map(fn {_, value} -> value["units"] end)
      |> Enum.reduce(fn x, acc -> x ++ acc end)
      |> Enum.map(fn value -> {value["character_id"], value["items"]} end)
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        Map.update(acc, key, value, fn x -> x ++ value end)
      end)
      |> Enum.map(fn {key, value} ->
        {
          key,
          Enum.reduce(value, %{}, fn x, acc -> Map.update(acc, x, 1, fn x -> x + 1 end) end)
        }
      end)
      |> Enum.into(%{})

    {:ok, encoded} = Jason.encode(inf, [{:pretty, true}])
    File.write("items.json", encoded)
  end

  defp limit_items(items, limit) do
    items
    |> Map.to_list()
    |> Enum.sort(fn {_, x}, {_, y} -> x > y end)
    |> Enum.take(limit)
    |> Enum.into(%{})
  end

  def get_items(
        conn,
        %{"champion" => champion}
      ) do
    {:ok, items} = File.read("items.json")
    {:ok, items} = Jason.decode(items)
    items = items |> Map.get(champion) |> limit_items(5)
    {:ok, items} = Jason.encode(items, [{:pretty, true}, {:scape, :javascript_safe}])
    conn |> send_resp(200, items)
  end

  def get_items(conn, _) do
    conn |> put_status(500)
  end

  def get_comps(
        conn,
        %{"champions" => champions}
      ) do
    {:ok, champions} = Jason.decode(champions)
    {:ok, comps} = File.read("comps.json")
    {:ok, comps} = Jason.decode(comps)

    comps =
      comps
      |> Enum.map(fn x ->
        x
        |> Map.put(
          "matches_count",
          x["units"]
          |> Enum.filter(fn x ->
            champions |> Enum.member?(x)
          end)
          |> Enum.count()
        )
      end)
      |> Enum.filter(fn x -> x["matches_count"] > 0 end)
      |> Enum.sort(fn x, y -> x["comp_count"] < y["comp_count"] end)
      |> Enum.sort(fn x, y -> x["matches_count"] > y["matches_count"] end)

    {:ok, comps} = Jason.encode(comps, [{:pretty, true}, {:scape, :javascript_safe}])

    conn |> send_resp(200, comps)
  end

  def get_comps(conn, _) do
    conn |> put_status(500)
  end

  def reset(conn, _params) do
  end
end
