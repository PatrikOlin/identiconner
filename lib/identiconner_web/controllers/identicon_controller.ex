defmodule IdenticonnerWeb.IdenticonController do
  use Phoenix.Controller

  def show(conn, %{"text" => text} = params) do
    format = Map.get(params, "format", "png")

    case format do
      "base64" ->
	# generate a base 64 encoded png
	base64_data = Identiconner.get_base64_image(text)

	conn
	|> put_resp_content_type("application/json")
	|> json(%{image: "data:image/png;base64,#{base64_data}"})

      _ -> # default to png format
	# generate the identicon PNG binary
	image_data = Identiconner.get_png_image(text)

	conn
	|> put_resp_content_type("image/png")
	|> send_resp(200, image_data)
    end
  end

# fallback
  def show(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing 'text' parameter"})
  end

end
