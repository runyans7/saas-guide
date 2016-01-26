class SubscriptionsController < ApplicationController

  before_action :authenticate_user!

  def index
    @account = Account.find_by_email(current_user.email)
  end

  def new
    @plans = Plan.all
  end

  def edit
    @account = Account.find(params[:id])
    @plans = Plan.all
  end

  def create
    token           = params[:stripeToken]
    plan            = params[:plan][:stripe_id]
    email           = current_user.email
    current_account = Account.find_by_email(current_user.email)
    customer_id     = current_account.customer_id
    current_plan    = current_account.stripe_plan_id

    if customer_id.nil?
      # New Customer
      @customer = Stripe::Customer.create(
        :source => token,
        :plan => plan,
        :email => email
      )
      subscriptions = @customer.subscriptions
      @subscribed_plan = subscriptions.data.find { |o| o.plan.id == plan }
    else
      # Customer exists. Get customer from Stripe
      @customer         = Stripe::Customer.retrieve(customer_id)
      @subscribed_plan  = create_or_update_subscription(@customer, current_plan, plan)
    end

    current_period_end = @subscribed_plan.current_period_end
    active_until = Time.at(current_period_end).to_datetime

    account                 = Account.find_by_email(current_user.email)
    account.stripe_plan_id  = plan
    account.customer_id     = customer_id
    account.active_until    = active_until
    account.save!
    # save_account_details(current_account, @customer.id, active_until)

    redirect_to :root, :notice => "Subscription successful"

  rescue => e
    redirect_to :new_subscription, :flash => { :error => e.message }
  end

  def cancel
    email           = current_user.email
    current_account = Account.find_by_email(current_user.email)
    customer_id     = current_account.customer_id
    current_plan    = current_account.stripe_plan_id

    if current_plan.blank?
      raise 'No plan to unsubscribe/cancel'
    end

    customer = Stripe::Customer.retrieve(customer_id)

    subscriptions = customer.subscriptions

    current_subscribed_plan = subscriptions.data.find { |o| o.plan.id == current_plan }

    if current_subscribed_plan.blank?
      raise 'Subscription not found'
    else
      current_subscribed_plan.delete
      account                 = Account.find_by_email(email)
      account.stripe_plan_id  = ""
      account.customer_id     = customer_id
      account.active_until    = Time.at(0).to_datetime
      account.save!
      @message = "Subscription cancelled successfully"

    end
    rescue => e
      redirect_to :new_subscription, :flash => { :error => e.message }
  end

  def save_account_details(account, plan, customer_id, active_until)

  end

  def create_or_update_subscription(customer, current_plan, new_plan)
    subscriptions = customer.subscriptions

    current_subscription = subscriptions.data.find { |o| o.plan.id == current_plan }

    if current_subscription.blank?
      # No current subscription. Need to create a new subscription
      subscription = customer.subscriptions.create( {:plan => new_plan} )
    else
      # Subscription found. Must be an upgrade or downgrade
      current_subscription.plan = new_plan
      subscription = current_subscription.save
    end
    subscription
  end


end
