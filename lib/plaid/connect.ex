defmodule Plaid.Connect do
  @moduledoc """
  Functions for working with Plaid Connect endpoint. Through this API you can:

  * Add a Plaid Connect user
  * Register a webhook for a user
  * Fetch user account data
  * Fetch user transaction data
  * Specify MFA delivery options
  * Submit MFA responses
  * Update user credentials
  * Delete a user

  All requests are submitted as maps with the parameter name as the key
  and value as value: %{key: value}. Keys can be strings or atoms.

  The functionality is performed by five functions: add, mfa, connect,
  update and delete. The specific requests are determined by the payload.

  Each function accepts user-supplied credentials, but uses the credentials
  specified in the configuration by default. The credentials are provided
  as a map:

  Payload (Credentials)
    `client_id` - Plaid client_id - string; required
    `secret` - Plaid secret - string; required

  """

  alias Plaid.Utilities

  defstruct [:accounts, :access_token, :transactions]

  @endpoint "connect"

  @doc """
  Adds a Connect user.

  Adds a Plaid Connect user using the username and password of the specified
  financial institution. Uses credentials supplied in the configuration.

  Returns Plaid.Connect, Plaid.MfaQuesion, Plaid.MfaMask or Plaid.Error struct.

  Payload
    `type` - Plaid institution code - string; required
    `username` - user's login - string; required
    `password` - user's password - string; required
    `pin` - user's pin - string; required for USAA only
    `options` - options for user - map; optional
      `login_only` - add user only, don't return transactions; default = false - boolean
      `webhook` - url to which webhook messages will be sent; default = null - string
      `pending` - return pending transactions; default = false - boolean
      `start_date` - if `login_only` = false, earliest date for which transactions
        will be returned; default = 30 days ago - string formatted "YYYY-MM-DD"
      `end_date` - if `login_only` = false, latest date for which transactions
        will be returned; default = today - string format "YYYY-MM-DD"
      `list` - MFA delivery methods; default = false - boolean

  ## Example

    params = %{username: "plaid_test", password: "plaid_good", type: "bofa",
               options: %{login_only: true, webhook: "http://requestb.in/",
                pending: false, start_date: "2015-01-01", end_date: "2015-03-31"},
                list: true}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.add(params)
    {:ok, %Plaid.MfaQuestion{...}} = Plaid.Connect.add(params)
    {:ok, %Plaid.MfaMask{...}} = Plaid.Connect.add(params)
    {:error, %Plaid.Error{...}} = Plaid.Connect.add(params)

  Plaid API Reference: https://plaid.com/docs/api/#add-connect-user

  """
  @spec add(map) :: {atom, map}
  def add(params) do
    add params, Plaid.config_or_env_cred()
  end

  @doc """
  Same as Plaid.Connect.add/1 but with user-supplied credentials.

  ## Example

    params = %{username: "plaid_test", password: "plaid_good", type: "bofa",
               options: %{login_only: true, webhook: "http://requestb.in/",
                pending: false, start_date: "2015-01-01", end_date: "2015-03-31"},
                list: true}
    cred = %{client_id: "test_id", secret: "test_secret"}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.add(params, cred)
    {:ok, %Plaid.MfaQuestion{...}} = Plaid.Connect.add(params, cred)
    {:ok, %Plaid.MfaMask{...}} = Plaid.Connect.add(params, cred)
    {:error, %Plaid.Error{...}} = Plaid.Connect.add(params, cred)

  """
  @spec add(map, map) :: {atom, map}
  def add(params, cred) when is_map(cred) and is_map(params) do
    Plaid.make_request_with_cred(:post, @endpoint, cred, params)
    |> Utilities.handle_plaid_response(:connect)
  end

  @doc """
  Sumbits MFA choice confirmation and MFA answer.

  Submits MFA choice confirmation or MFA answer to Plaid connect/step endpoint.
  The request is determined by the payload. Used in response to an
  MFA question response following a Plaid.Connect.add/1 request. Uses
  credentials supplied in the configuration.

  Returns Plaid.Connect, Plaid.MfaMessage or Plaid.Error struct.

  Payload (Choice Confirmation)
    `access_token` - user's access_token - string; required
    `options` - options for MFA - map; required
      `send_method` - delivery modality for MFA request - map

  Payload (MFA Answer)
    `access_token` - user's access_token - string; required
    `mfa` - user's response to MFA question - string; required

  ## Example

    params = %{access_token: "test_bofa", mfa: "tomato"} OR
             %{access_token: "test_bofa", options: %{send_method:
                %{type: "phone"}}}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.mfa(params)
    {:ok, %Plaid.MfaMessage{...}} = Plaid.Connect.mfa(params)
    {:error, %Plaid.Error{...}} = Plaid.Connect.mfa(params)

  Plaid API Reference: https://plaid.com/docs/api/#connect-mfa

  """
  @spec mfa(map) :: {atom, map}
  def mfa(params) do
    mfa params, Plaid.config_or_env_cred()
  end

  @doc """
  Same as Plaid.Connect.mfa/1 but with user-supplied credentials.

  ## Example

    params = %{access_token: "test_bofa", mfa: "tomato"}  OR
             %{access_token: "test_bofa", options: %{send_method:
                %{type: "phone"}}}
    cred = %{client_id: "test_id", secret: "test_secret"}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.mfa(params, cred)
    {:ok, %Plaid.MfaMessage{...}} = Plaid.Connect.mfa(params, cred)
    {:error, %Plaid.Error{...}} = Plaid.Connect.mfa(params, cred)

  """
  @spec mfa(map, map) :: {atom, map}
  def mfa(params, cred) do
    endpoint = @endpoint <> "/step"
    Plaid.make_request_with_cred(:post, endpoint, cred, params)
    |> Utilities.handle_plaid_response(:connect)
  end

  @doc """
  Gets Plaid data.

  Gets a user's account and transaction data as specified in the params. Uses
  credentials specified in the configuration.

  Returns Plaid.Connect or Plaid.Error struct.

  Payload
    `access_token` - user's access_token - string; required
    `options` - options for user - map; optional
      `pending` - return pending transactions; default = false - boolean
      `account` - Plaid account `_id` for which to return transactions; default = null - string
      `gte` - earliest date for which transactions will be returned - string formatted "YYYY-MM-DD"
      `lte` - latest date for which transactions will be returned - string formatted "YYYY-MM-DD"

  ## Example

    params = %{access_token: "test_bofa", options: %{pending: false,
               account: "QPO8Jo8vdDHMepg41PBwckXm4KdK1yUdmXOwK",
               gte: "2012-01-01", lte: "2016-01-01"}}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.get(params)
    {:error, %Plaid.Error{...}} = Plaid.Connect.get(params)

  Plaid API Reference: https://plaid.com/docs/api/#get-transactions

  """
  @spec get(map) :: {atom, map}
  def get(params) do
    get params, Plaid.config_or_env_cred()
  end

  @doc """
  Same as Plaid.Connect.get/1 but with user-supplied credentials.

  ## Example

    params = %{access_token: "test_bofa", options: %{pending: false,
               account: "QPO8Jo8vdDHMepg41PBwckXm4KdK1yUdmXOwK",
               gte: "2012-01-01", lte: "2016-01-01"}}
    cred = %{client_id: "test_id", secret: "test_secret"}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.get(params, cred)
    {:error, %Plaid.Error{...}} = Plaid.Connect.get(params, cred)

  """
  @spec get(map, map) :: {atom, map}
  def get(params, cred) do
    endpoint = @endpoint <> "/get"
    Plaid.make_request_with_cred(:post, endpoint, cred, params)
    |> Utilities.handle_plaid_response(:connect)
  end

  @doc """
  Updates a user's credentials.

  Patches a user's credentials or webhook url in Plaid. New credentials
  must be submitted for an existing user identified by the access_token.
  Request is determined by the payload. Uses credentials specified in the
  configuration.

  Returns Plaid.Connect, Plaid.Mfa or Plaid.Error struct.

  Payload (Connect)
    `access_token` - user's access_token - string; required
    `username` - user's login - string; required
    `password` - user's password - string; required
    `pin` - user's pin - string; required for USAA only

  Payload (Webhook)
    `access_token` - user's access_token - string; required
    `options` - map; required
      `webhook` - url to which webhook messages will be sent; default = null - string

  ## Example

    params = %{access_token: "test_bofa", username: "plaid_test",
               password: "plaid_good"} OR
             %{access_token: test_bofa", options: %{webhook: "http://requestb.in/"}}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.update(params)
    {:ok, %Plaid.MfaQuestion{...}} = Plaid.Connect.update(params)
    {:error, %Plaid.Error{...}} = Plaid.Connect.update(params)

  """
  @spec update(map) :: {atom, map}
  def update(params) do
    update params, Plaid.config_or_env_cred()
  end

  @doc """
  Same as Plaid.Connect.update/1 but with additional parameter specifying a
  patch to the MFA endpoint.

  Payload (MFA)
    `access_token` - user's access_token - string; required
    `mfa` - user's response to MFA question - string; required

  ## Example

    params = %{access_token: "test_bofa", mfa: "tomato"}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.update(params)
    {:error, %Plaid.Error{...}} = Plaid.Connect.update(params)

  """
  @spec update(map, atom) :: {atom, map}
  def update(params, :mfa) do
    update params, Plaid.config_or_env_cred, :mfa
  end

  @doc """
  Same as Plaid.Connect.update/1 but with user-supplied credentials.

  ## Example

    params = %{access_token: "test_bofa", username: "plaid_test",
               password: "plaid_good"} OR
             %{access_token: test_bofa", options: %{webhook: "http://requestb.in/"}}
    cred = %{client_id: "test_id", secret: "test_secret"}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.update(params, cred)
    {:ok, %Plaid.MfaQuestion{...}} = Plaid.Connect.update(params, cred)
    {:error, %Plaid.Error{...}} = Plaid.Connect.update(params, cred)

  """
  @spec update(map, map) :: {atom, map}
  def update(params, cred) do
    Plaid.make_request_with_cred(:patch, @endpoint, cred, params)
    |> Utilities.handle_plaid_response(:connect)
  end

  @doc """
  Same as Plaid.Connect.update/2 but with user-supplied credentials.

  ## Example

    params = %{access_token: "test_bofa", mfa: "tomato"}
    cred = %{client_id: "test_id", secret: "test_secret"}

    {:ok, %Plaid.Connect{...}} = Plaid.Connect.update(params, cred)
    {:error, %Plaid.Error{...}} = Plaid.Connect.update(params, cred)

  """
  @spec update(map, map, atom) :: {atom, map}
  def update(params, cred, :mfa) do
    endpoint = @endpoint <> "/step"
    Plaid.make_request_with_cred(:patch, endpoint, cred, params)
    |> Utilities.handle_plaid_response(:connect)
  end

  @doc """
  Deletes a Connect user.

  Deletes a user from the Plaid connect endpoint.

  Returns a Plaid.Message or Plaid.Error struct.

  Payload
    `access_token` - user's access_token - string; required

  ## Example

    params = %{access_token: "test_bofa"}

    {:ok, %Plaid.Message{...}} = Plaid.Connect.delete(params)

  """
  @spec delete(map) :: {atom, map}
  def delete(params) do
    delete params, Plaid.config_or_env_cred()
  end

  @doc """
  Same as Plaid.Connect.delete/1 but with user-supplied credentials.

  ## Example

    params = %{access_token: "test_bofa"}
    cred = %{client_id: "test_id", secret: "test_secret"}

    {:ok, %Plaid.Message{...}} = Plaid.Connect.delete(params, cred)

  """
  @spec delete(map, map) :: {atom, map}
  def delete(params, cred) do
    Plaid.make_request_with_cred(:delete, @endpoint, cred, params)
    |> Utilities.handle_plaid_response(:connect)
  end

end