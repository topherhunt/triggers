# Triggers Phoenix app

This app was built by following the steps in doc/howto_rebuild.md. Last built 2020-02-12.

How to branch a new app based on this triggers template:

  * `mix deps.get`
  * `mix ecto.create`
  * `mix ecto.migrate`
  * `mix test` - around 30 tests should run; all should pass


## Production

Deployed on Heroku: https://triggers-prod.herokuapp.com/
