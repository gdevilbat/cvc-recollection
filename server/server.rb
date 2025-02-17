require 'stripe'
require 'sinatra'
require 'dotenv'

# Replace if using a different env file or config
Dotenv.load
Stripe.api_key = ENV['STRIPE_SECRET_KEY']

set :static, true
set :public_folder, File.join(File.dirname(__FILE__), ENV['STATIC_DIR'])
set :views, File.join(File.dirname(__FILE__), ENV['STATIC_DIR'])
set :port, 4242

puts File.join(settings.public_folder, 'index.html')

get '/' do
  content_type 'text/html'
  send_file File.join(settings.public_folder, 'index.html')
end

post '/setup_intents' do
  content_type 'application/json'
  data = JSON.parse(request.body.read)
  Stripe::SetupIntent.create(data).to_json
end

post '/payment_intents' do
  content_type 'application/json'
  data = JSON.parse(request.body.read)

  Stripe::PaymentIntent.create(
    customer: data['customer'],
    amount: 500,
    currency: 'USD',
  ).to_json
end

post '/customers' do
  content_type 'application/json'
  data = JSON.parse(request.body.read)
  Stripe::Customer.create(
    payment_method: data['payment_method']
  ).to_json
end

post '/webhook' do
  # You can use webhooks to receive information about asynchronous payment events.
  # For more about our webhook events check out https://stripe.com/docs/webhooks.
  webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
  payload = request.body.read
  if !webhook_secret.empty?
    # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, webhook_secret
      )
    rescue JSON::ParserError => e
      # Invalid payload
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      puts "⚠️  Webhook signature verification failed."
      status 400
      return
    end
  else
    data = JSON.parse(payload, symbolize_names: true)
    event = Stripe::Event.construct_from(data)
  end
  # Get the type of webhook event sent - used to check the status of PaymentIntents.
  event_type = event['type']
  data = event['data']
  data_object = data['object']

  if event_type == 'some.event'
    puts "🔔  Webhook received!"
  end

  content_type 'application/json'
  {
    status: 'success'
  }.to_json
end
