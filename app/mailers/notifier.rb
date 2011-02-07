require 'action_mailer'
require 'pp'

class Notifier < ActionMailer::Base

  class MissingController
    def method_missing(*args, &block)
    end
  end

  def exception_notification(env, exception)
    @env        = env
    @exception  = exception
    @options    = options
    @kontroller = env['action_controller.instance'] || MissingController.new
    @request    = ActionDispatch::Request.new(env)
    @backtrace  = clean_backtrace(exception)
    @sections   = @options[:sections]
    data        = env['exception_notifier.exception_data'] || {}

    data.each do |name, value|
      instance_variable_set("@#{name}", value)
    end

    prefix   = "#{@options[:email_prefix]}#{@kontroller.controller_name}##{@kontroller.action_name}"
    subject  = "#{prefix} (#{@exception.class}) #{@exception.message.inspect}"

    mail(:to => @options[:exception_recipients], :from => @options[:sender_address], :subject => subject)
  end

  private
    def options
      config = YAML.load_file(File.dirname(__FILE__)+"/../../config/notifier.yml")
      hash = config["default"].dup
      hash.keys.each do |key|
        hash[key] = config[Rails.env][key] if config[Rails.env].key?(key)
      end
      hash.symbolize_keys
    end
    def clean_backtrace(exception)
      Rails.respond_to?(:backtrace_cleaner) ?
        Rails.backtrace_cleaner.send(:filter, exception.backtrace) :
        exception.backtrace
    end
    
    helper_method :inspect_object
    
    def inspect_object(object)
      case object
      when Hash, Array
        object.inspect
      when ActionController::Base
        "#{object.controller_name}##{object.action_name}"
      else
        object.to_s
      end
    end
    
end
