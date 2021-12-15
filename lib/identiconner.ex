defmodule Identiconner do
  def png(input) do
    input
    |> generate
    |> save_image(input)
  end

  def base64(input) do
    input
    |> generate
    |> base64_encode
  end

  defp generate(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
  end

  defp base64_encode(image) do
    Base.encode64(image)
  end

  defp hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Identiconner.Image{hex: hex}
  end

  defp pick_color(%Identiconner.Image{hex: [r, g, b | _tail]} = image) do
    %Identiconner.Image{image | color: {r, g, b}}
  end

  defp build_grid(%Identiconner.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      |> Enum.with_index()

    %Identiconner.Image{image | grid: grid}
  end

  defp mirror_row(row) do
    [first, second | _tail] = row

    row ++ [second, first]
  end

  defp filter_odd_squares(%Identiconner.Image{grid: grid} = image) do
    grid =
      Enum.filter(grid, fn {code, _index} ->
        rem(code, 2) == 0
      end)

    %Identiconner.Image{image | grid: grid}
  end

  defp build_pixel_map(%Identiconner.Image{grid: grid} = image) do
    pixel_map =
      Enum.map(grid, fn {_code, index} ->
        horizontal = rem(index, 5) * 50
        vertical = div(index, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        {top_left, bottom_right}
      end)

    %Identiconner.Image{image | pixel_map: pixel_map}
  end

  defp draw_image(%Identiconner.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  defp save_image(image, filename) do
    File.write("#{filename}.png", image)
  end
end
