# SalesFarce!

This is just a simple little proof-of-concept for creating an application
that integrates with SalesForce via OAuth2 authentication and the Salesforce
REST API through use of the
[databasedotcom](http://github.com/heroku/databasedotcom) gem.

## Really? You actually want to run this?

First thing you need to do is sign up for a free account Salesforce Developer
account at [Force.com](http://developer.force.com).

Once you have an account, you need to set up a Remote Access Application. This
will provide the credentials to authenticate with OAuth2.

- In the left sidebar menu under __App Setup__, click __Develop__ then click
  __Remote Access__
- Create a new Remote Access Application
- Fill in the fields with whatever you want but make sure the __Callback URL__
  field says ```http://localhost:3000/auth/salesforce/callback```
- Save the form and edit ```config/salesforce.yml``` so the ```client_id```
  is set to the __Consumer Key__ and the ```client_secret``` is set to the
  __Consumer Secret__ values for your new Salesforce Remote Access Application
- Once you've cloned this project run the following in your shell:

```
$ bundle install
$ ruby init.rb
$ open http://localhost:3000
```

There's really nothing good here. I warned you.

