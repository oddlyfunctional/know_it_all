> Well, actually...

# KnowItAll

[![Join the chat at https://gitter.im/mrodrigues/know_it_all](https://badges.gitter.im/mrodrigues/know_it_all.svg)](https://gitter.im/mrodrigues/know_it_all?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

KnowItAll is a small, object-oriented approach to authorization. It knows everything about your application!

More of an architectural pattern for API-focused authorization than properly a dependency, and heavily inspired by [Pundit](https://github.com/elabs/pundit), this gem simply provides a small set of helpers that make applying the pattern easier.

If your application needs to validate pre-requisites before performing certain actions, at the same time providing helpful error messages for the API's clients, all that while using regular magic-less Ruby and object oriented design patterns, KnowItAll is your friend.

Table of Contents
=================

  * [KnowItAll](#knowitall)
    * [Why?](#why)
    * [Why not just Pundit?](#why-not-just-pundit)
    * [Installation](#installation)
    * [Usage](#usage)
      * [Creating policies](#creating-policies)
        * [Naming convention](#naming-convention)
        * [Helper class](#helper-class)
      * [Using policies](#using-policies)
        * [What happens when not authorized](#what-happens-when-not-authorized)
        * [Querying authorizations in the view](#querying-authorizations-in-the-view)
        * [Avoiding conflicts in the controller](#avoiding-conflicts-in-the-controller)
        * [Overrides](#overrides)
    * [Enforcing authorization checks](#enforcing-authorization-checks)
    * [Development](#development)
    * [Contributing](#contributing)
    * [License](#license)

## Why?

The assumption made is that each action has its own requirements based on the current context. Some may be related to the current user's permissions in the system, others with the parameters sent, and others yet may even have nothing to do with any input received. Let's say you're building the API for a food delivery app. To be able to checkout, you need to validate the following requirements:

- The user must be signed in;
- The user must have a registered address;
- The registered address must be within a determined radius;
- The cart must contain at least $10 in items;
- The chosen items must be available for delivery;
- The store must be open.

It'd be very helpful for a developer consuming this API if, in case of failure, the API returned an appropriate error message explaining exactly what when wrong, instead of an empty `403 Forbidden`. Performing this manually is easy, but quickly polutes the action's code:

```ruby
class OrdersController < ApplicationController
  def create
    return error("User must be signed in") unless current_user
    return error("User must have a registered address") unless current_user.address
    return error("Registered address is outside the range") unless address_in_range?(current_user.address)
    return error("Cart must contain at least $10 in items") unless cart_has_minimum?(cart)
    return error("Some of the items are not available") unless items_available?(cart.items)
    return error("The store is closed") unless store.open?

    # Here finally starts what the action actually does
    order = Order.create(order_params)
    if order.save
      render json: order, status: :created
    else
      render json: { errors: order.errors }, status: :unprocessable_entity
    end
  end

  private

    def error(message)
      render json: { error: message }, status: :forbidden
    end
end
```

It's much more readable, as well as easier to test and extend, if all of those requirement tests were contained in a proper class:

```ruby
class OrdersController < ApplicationController
  def create
    policy = OrdersPolicies::Create.new(current_user, cart, store)
    return render json: { errors: policy.errors } unless policy.authorize?

    order = Order.create(order_params)
    if order.save
      render json: order, status: :created
    else
      render json: { errors: order.errors }, status: :unprocessable_entity
    end
  end
end
```

That's exactly the architectural pattern encouraged by this gem. By including a small set of helpers, it makes it extremely simple to perform complex validations and provide helpful feedback through the API.

## Why not just Pundit?

Pundit is great! I've been using it for years and I love it, but its model-focused permissions and structural pattern makes it difficult and awkward to perform validations on scenarios that need multiple arguments and show appropriate error messages for the API's clients. Based on modifications I've made when using Pundit in some projects, I created this gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'know_it_all'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install know_it_all

## Usage

There are two steps to using this gem: creating and using policies:

### Creating policies

A policy is simply a class obeys some rules:

* It is initialized with the same arguments that are passed to the `authorize`, `authorize!` and `authorize?` methods in the controller;
* It responds to a method `errors`;
* Calling `errors` returns an object that responds to the method `empty?` and is serializable. It's usually an array, but it could easily be an `ActiveModel::Errors`.

Here's an example:

```ruby
module OrdersPolicies
  class Create
    def initialize(current_user, cart, store)
      @current_user = current_user
      @cart = cart
      @store = store
    end

    def errors
      @errors = []
      @errors << "User must be signed in" unless @current_user
      @errors << "User must have a registered address" unless @current_user.address
      @errors << "Registered address is outside the range" unless address_in_range?(current_user.address)
      @errors << "Cart must contain at least $10 in items" unless cart_has_minimum?(@cart)
      @errors << "Some of the items are not available" unless items_available?(@cart.items)
      @errors << "The store is closed" unless @store.open?
    end
  end
end
```

Using `ActiveModel::Validations`:

```ruby
module OrdersPolicies
  class Create
    include ActiveModel::Validations

    validates_presence_of :current_user, :address
    validate :address_in_range
    validate :cart_has_minimum
    validate :items_are_available
    validate :store_is_open

    def initialize(current_user, cart, store)
      @current_user = current_user
      @cart = cart
      @store = store

      run_validations! # Populates the `ActiveModel::Errors`
    end
  end
end
```

#### Naming convention

The convention `KnowItAll` uses for defining the name of the constant containing the appropriate policy is the following:

* Based on the `controller_path` method on the controller, it builds a module name by appending the `Policies` suffix: `"orders"` becomes `"OrdersPolicies"` and `"admin/dashboard_panel"` becomes `"Admin::DashboardPanelPolicies"`.
* Based on the `action_name` method on the controller, it builds a class name: `"index"` becomes `"Index"`, `"increase_inventory"` becomes `"IncreaseInventory"`.
* By appending the class name to the module name, it tries to find that constant: with `controller_path == "orders"` and `action_name == "Index"`, it looks for a `OrdersPolicies::Index` constant.

For more details about how the module and class names are converted, please check the [`ActiveSupport::Inflector#camelize`](http://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-camelize) method.

#### Helper class

If you don't want to write your own policy from the scratch, I've also provided a minimalistic base policy:

```ruby
module OrdersPolicies
  class Create < KnowItAll::Base
    assert :user_signed_in?, "User must be signed in" 
    assert :address_present?, "User must have a registered address" 
    assert :address_in_range?, "Registered address is outside the range" 
    assert :cart_has_minimum?, "Cart must contain at least $10 in items" 
    assert :items_available?, "Some of the items are not available" 
    assert :store_open?, "The store is closed" 

    def initialize(current_user, cart, store)
      @current_user = current_user
      @cart = cart
      @store = store
    end
  end
end
```

The class method `assert` expects a `Symbol` representing the name of a predicate and a `String` containing the error message in case the predicate fails. The default `errors` method returns an array containing the messages for all the assertions that didn't pass.

### Using policies

The simplest approach is to include the `KnowItAll` module in the controller you want to perform the validation. For this example, let's make the helpers available to all controllers by including it in the `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  include KnowItAll
end
```

After that, we can use the helpers in any controller that inherits from `ApplicationController`:

```ruby
class OrdersController < ApplicationController
  def create
    authorize! current_user, cart, store

    order = Order.create(order_params)
    if order.save
      render json: order, status: :created
    else
      render json: { errors: order.errors }, status: :unprocessable_entity
    end
  end
end
```

#### What happens when not authorized

The `authorize!` method raises a `KnowItAll::NotAuthorized` exception in case the authorization has failed, and contains the instance of the policy used to perform the validation:

```ruby
class ApplicationController < ActionController::Base
  include KnowItAll
  rescue_from KnowItAll::NotAuthorized do |exception|
    render json: { errors: exception.policy.errors }, status: :forbidden
  end
end
```

This pattern is so common that I've wrote a method that does exactly that:

```ruby
class ApplicationController < ActionController::Base
  include KnowItAll
  rescue_from KnowItAll::NotAuthorized, with: :render_not_authorized
end
```

Alternatively, you can use the bangless form of the authorization method (`authorize`), which doesn't raise an exception and returns the errors in the policy:

```ruby
class OrdersController < ApplicationController
  def create
    errors = authorize current_user, cart, store
    if errors.empty?
      order = Order.create(order_params)
      if order.save
        render json: order, status: :created
      else
        render json: { errors: order.errors }, status: :unprocessable_entity
      end
    else
      return render json: { errors: errors }, status: :forbidden
    end
  end
end
```

#### Querying authorizations in the view

You can use the predicate `authorize?` to make decisions based on future authorizations in your views. First you need to make the method available as a helper:

```ruby
class ApplicationController < ActionController::Base
  include KnowItAll
  helper_method :authorize?
end
```

Then use it in your views, passing the appropriate overrides (more about that here):

```erb
<%= form_for @order do |f| %>
  <!-- Form fields -->

  <%= f.button "Place order", disabled: authorize?(
                                          @current_user,
                                          @cart,
                                          @store,
                                          controller_path: "orders",
                                          action_name: "create"
                                        ) %>
<% end %>
```

#### Avoiding conflicts in the controller

It's possible that you're already using methods with the same names as the ones in the `KnowItAll` module: `authorize`, `authorize?`, `authorize!`, `policy`, `policy_class`, `policy_name`, `render_not_authorized` or `verify_authorized`. In that case, the solution is to include the module in another class, and use it as a collaborator. The only methods `KnowItAll` needs to find the correct policies are `controller_path` and `action_name`:

```ruby
class Authorizer
  include KnowItAll
  attr_reader :controller_path, :action_name

  def initialize(controller)
    @controller_path = controller.controller_path
    @action_name = controller.action_name
  end
end

class ApplicationController < ActionController::Base
  protected

    def authorizer
      Authorizer.new(self)
    end
end

class OrdersController < ApplicationController
  def create
    authorizer.authorize! current_user, cart, store

    # Action's code here
  end
end
```

In that case, I've made available a `KnowItAll::Authorizer` class that does exactly that:

```ruby
class ApplicationController < ActionController::Base
  protected

    def authorizer
      KnowItAll::Authorizer.new(self)
    end
end
```

#### Overrides

It's possible to override any of the methods `KnowItAll` uses to define the appropriate policy. You can do that in the controller:

```ruby
class OrdersController < ApplicationController
  def create
    authorize! current_user, cart, store

    # Action's code here
  end

  def policy_name
    "OrdersPolicies::Checkout"
  end
end
```

Or when calling the `authorize`, `authorize?` or `authorize!` methods:

```ruby
class OrdersController < ApplicationController
  def create
    authorize! current_user, cart, store, policy_name: "OrdersPolicies::Checkout"

    # Action's code here
  end
end
```

The available overrides are: `controller_path`, `action_name`, `policy_name`, `policy_class` and `policy` (instance of the policy).

## Enforcing authorization checks

While developing a simple feature, it's easy to forget to perform an authorization check. It's helpful during development to know when you forget it, so I've provided a `verify_authorized` method that raises a `KnowItAll::AuthorizationNotPerformedError` when there were no calls to any one of the authorization methods: `authorize`, `authorize?` or `authorize!`:

```ruby
class ApplicationController < ActionController::Base
  include KnowItAll
  after_action :verify_authorized
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mrodrigues/know_it_all. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

