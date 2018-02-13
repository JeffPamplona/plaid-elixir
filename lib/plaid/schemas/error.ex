defmodule Plaid.Error do
  @moduledoc false
  defstruct [#:access_token, :code, :message, :resolve,
             :display_message, :error_code,	:error_message, :error_type, :request_id]
end
