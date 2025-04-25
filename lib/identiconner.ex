defmodule Identiconner do
  def save_png_image(input) do
    input
    |> generate
    |> save_image(input)
  end

  def get_base64_image(input) do
    input
    |> generate
    |> base64_encode
  end

  def get_png_image(input) do
    input
    |> generate
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
	{horizontal, vertical, 50, 50}
      end)

    %Identiconner.Image{ image | pixel_map: pixel_map}
  end

  defp draw_image(%Identiconner.Image{color: color, pixel_map: pixel_map}) do
    # create a blank 250x250 image with transparent background
    image = ExPng.Image.new(250, 250)

    # convert elixir RGB tuple to RGBA binary format that PNG lib expects
    {r, g, b} = color
    fill_color = ExPng.Color.rgb(r, g, b)

    # draw each rectangle in the pixel map
    image_with_rectangles =
      Enum.reduce(pixel_map, image, fn {x, y, width, height}, acc ->
	draw_rectangle(acc, x, y, width, height, fill_color)
      end)

    # use a temporary file to get the binary
    temp_file = "#{System.tmp_dir()}/temp_identicon_#{:rand.uniform(1_000_000)}.png"
    ExPng.Image.to_file(image_with_rectangles, temp_file)
    png_data = File.read!(temp_file)
    File.rm!(temp_file)  # Clean up the temporary file
    
    png_data
  end

  defp draw_rectangle(image, x, y, width, height, pixel) do
    # draw the rectangle by coloring each pixel in the area
      Enum.reduce(y..(y + height - 1), image, fn y_pos, acc_y ->
	Enum.reduce(x..(x + height - 1), acc_y, fn x_pos, acc_x ->
	  ExPng.Image.Drawing.draw(acc_x, {x_pos, y_pos}, pixel)
	end)
      end)
  end

  defp save_image(image, filename) do
    File.write("#{filename}.png", image)
  end
end
