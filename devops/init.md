# How to set up a new VPS deployment

* Create a Scaleway or DigitalOcean instance.

* Give it an alias in `~/.ssh/config`, eg. `triggers-prod`.
  (Use the `ubuntu` account, not `root`!)

* SSH into it

* `sudo apt-get update && sudo apt-get upgrade -y`

* Install Postgres:
  (use `mix phx.gen.secret` to generate the password; note it in `secrets.exs`)

```
sudo apt-get install -y postgresql-10
createdb $(whoami)
sudo -u postgres psql -d postgres -c "CREATE ROLE ubuntu SUPERUSER CREATEDB LOGIN PASSWORD 'replace_me';"
```

* Install `asdf`:
  - https://asdf-vm.com/#/core-manage-asdf?id=asdf
  - `asdf plugin-add erlang`
  - `asdf plugin-add elixir`
  - `asdf plugin-add nodejs`
  - `sudo apt-get install -y build-essential automake libncurses5-dev libssl-dev`

* Add Github deploy key
  - generate a key for the server: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key
  - create a Github deploy key for that pubfile & for this repo

* `git clone GITHUB_REPO_URL` (into a folder under home, eg. `~/triggers/`)

* `cd triggers/`

* `asdf install`

* Review the install output, ensure that Erlang installed properly

* Copy `secrets.exs.template` to `secrets.exs` which sets all production env vars



* Use `asdf` to install the right Erlang & Elixir versions



[TO INTEGRATE]

* Add Mailgun integration

* Add Papertrail integration

* Add an UptimeRobot monitor
