[
  # Ecto.Multi opaque type false positives
  {"lib/cannery/accounts.ex", :call_without_opaque},
  {"lib/cannery/accounts/invites.ex", :call_without_opaque},
  {"lib/cannery/activity_log.ex", :call_without_opaque},
  # Gettext opaque type false positives
  # https://github.com/elixir-gettext/gettext/issues/428
  {"lib/cannery_web/gettext.ex", :call_without_opaque},
  # ExUnit internal functions not in PLT
  {"test/support/channel_case.ex", :unknown_function},
  {"test/support/conn_case.ex", :unknown_function},
  {"test/support/data_case.ex", :unknown_function}
]
