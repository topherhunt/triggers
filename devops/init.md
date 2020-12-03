# How to set up a new VPS deployment



NOTE: I've dropped this approach. Too much busywork. I'll stick with Heroku. The last straw was realizing that I'll still need to manually swap in LetsEncrypt certs every 3 months or so.



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

* Add Github deploy key
  - generate a key for the server: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key
  - create a Github deploy key for that pubfile & for this repo

* `git clone GITHUB_REPO_URL` (into a folder under home, eg. `~/triggers/`)

* `cd MY_REPO_FOLDER`

* Install `asdf`:
  - `asdf plugin-add elixir`
  - `asdf plugin-add erlang` (see https://asdf-vm.com/#/core-manage-asdf?id=asdf)
  - `asdf plugin-add nodejs`
  - `sudo apt-get install -y build-essential automake libncurses5-dev libssl-dev unzip` (Note: this omits some build components such as wx, odbc, and documentation, but building with all those components takes longer & takes more memory.)

* `asdf install`
  - I can work on `secrets.exs` while it's building Erlang
  - Ensure building Erlang didn't fail in any important ways, eg. OpenSSL errors
  - Ensure `node -v` returns right version (see https://github.com/asdf-vm/asdf-nodejs)

* Write `secrets.exs` which sets all production env vars
  - set up SMTP email sending credentials (eg. from a Mailgun account)
  - set up a Rollbar account if needed, and add that ROLLBAR_ACCESS_TOKEN

* `mix deps.get && MIX_ENV=prod mix compile`
  - Ensure no compile errors

* Set up LetsEncrypt:
  (See also: https://certbot.eff.org/lets-encrypt/ubuntubionic-other)
  - `sudo snap install core; sudo snap refresh core`
  - `sudo snap install --classic certbot`
  - `sudo ln -s /snap/bin/certbot /usr/bin/certbot`
  - `sudo certbot certonly --standalone` (ensure the webserver is stopped first)

* Forward traffic from ports 80 and 443 to 4000 where Phoenix can listen for it:
  - (see also my cheatsheet `networks.md`)
  - `sudo iptables -t nat -I PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 4000`

* Start the production app
  - `npm install --prefix assets/`
  - `npm run deploy --prefix assets/`
  - `MIX_ENV=prod mix phx.digest`
  - `MIX_ENV=prod mix ecto.create`
  - `MIX_ENV=prod mix ecto.migrate`
  - `MIX_ENV=prod mix phx.server`

* Set up the domain:
  - eg. on Namecheap, I added an A record for triggers.topherhunt.com -> the server IP
  - [TODO] set the app port to listen on 443? Or is this already configured?




...

* Set up an UptimeRobot monitor

* Smoke-test that everything is wired up
  - Site is reachable
  - Emails are sent correctly
  - Backend errors are reported to Rollbar
  - Frontend JS errors are reported to Rollbar
  - Logs are routed to Papertrail




[TO INTEGRATE]

* Add Papertrail integration

* Add an UptimeRobot monitor



## Useful references:

LetsEncrypt: https://letsencrypt.org/getting-started/ and https://certbot.eff.org/lets-encrypt/ubuntubionic-other

Phoenix official deployment guide: https://hexdocs.pm/phoenix/deployment.html#putting-it-all-together

Using Docker to deploy a Phoenix app on EC2: https://blog.altendorfer.at/2017/elixir/dev/andi/2017/12/24/deploying-elixirphoenixectopostgres-project-at.html

Deploying a Rails app on a DigitalOcean instance "the hard way": https://www.thegreatcodeadventure.com/deploying-rails-to-digitalocean-the-hard-way/
