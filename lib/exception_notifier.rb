require 'action_dispatch'

class ExceptionNotifier
  def initialize(app, name = nil)
    @app = app
    @config = YAML.load_file(File.dirname(__FILE__)+"/../config/notifier.yml")
  end

  def call(env)
    begin
      @app.call(env)
    rescue Exception => exception
      unless ignore_exception?(exception)
        Notifier.exception_notification(env, exception).deliver
        env['exception_notifier.delivered'] = true
      end
  
      raise exception
    end
  end
  
  def ignore_exception?(e)
    return true if @config[Rails.env]["ignore_exceptions"] == "all"
    (@config[Rails.env]["ignore_exceptions"] || 
    @config["default"]["ignore_exceptions"]).
    include?(e.class.to_s)
  end
end
