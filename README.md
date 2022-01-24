# README

This is a basic server for allowing [zorki](https://www.githbub.com/cguess/zorki) and [forki](https://github.com/oneroyalace/forki) to run standalone on a server somewhere.
This is useful specifically because when scraping the IP of hosting servers may be blocked, and this can be hosted on a Raspberry Pi in your house or something.

## Setup:
1. Make sure you have Rails 3.1.0 installed (may work on older version, haven't checked)
1. Grab this repo
1. `$ bundle install` to get all the gems in
1. Create `config/application.yml` and create `INSTAGRAM_USER_NAME`, `INSTAGRAM_PASSWORD`.
1. Run `$ rails secret` and then add a variable `secret_key_base` to `config/application.yml`
1. `$ rails db:migrate` to setup the database (this uses SQLite so there's no need for Postgres or MySQL or anything)
1. Generate an API key for security purposes in the Rails console
	1. `$ rails c`
	1. `Setting.generate_auth_key`
	1. Note this key in a password manager or something, you'll need it later. It's currently stored in the database (this should be hashed at some point, but meh for now)
	1. `exit`
1. Start up the server `$ rails s`

If your auth key gets compromised just reload it using the same steps above.

## Use

This service allows you to pass in an Instagram URL and it'll return a JSON structure with everything you'd want, including the images as base64 encoded fields.

The only endpoint is `GET /scrape` which access two parameters:
1. `url`: the url of the Instagram post
1. `auth_key`: this is generated in the setup


## Development

Follow the same steps to set up and if you want to run tests it's done by `rails t`

## TODO

- [] Set stem variables so we know which version of the software this should become
- [] Use a hash for the auth key instead of the key itself for comparison
- [] Allow the requests to be IP limited
