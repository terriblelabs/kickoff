# It's kickoff time!

Our terribly awesome template generates a Rails app featuring some of [our](http://www.terriblelabs.com/team)
favorite tools for building web apps.

## Usage

```rails new my_app -m https://raw.github.com/terriblelabs/kickoff/master/template.rb```

## Features

* Devise (optional) with your choice of model name (User, AdminUser, etc.). This template will also create a user with your choice of email and password, and a factory.
* SimpleForm
* Zurb Foundation
* Modernizr
* Haml
* Redcarpet, a markdown parser, because [Haml Sucks for Content](http://chriseppstein.github.com/blog/2010/02/08/haml-sucks-for-content/)
* Stamp for formatting dates and times
* Unicorn web server
* Airbrake

Development tools:

* Better Errors + binding_of_caller
* byebug debugger for Ruby 2.0
* Foreman
* Letter Opener
* Pry-rails

Testing tools:

* RSpec
* Guard
* FactoryGirl
* ffaker
* shoulda-matchers
* valid_attribute

And for production:

* NewRelic
* SendGrid

## Copyright

Copyright (c) 2012 [Terrible Labs, Inc.](http://www.terriblelabs.com)
