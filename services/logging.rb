# frozen_string_literal: true

module Services
  # Simple logging service formatting messages.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Logging
    include Singleton

    attr_accessor :logger

    def initialize
      @logger = Logger.new(STDOUT)
    end

    def sessions(raw_sessions)
      raw_sessions = raw_sessions.pluck(:_id).map(&:to_s).join(', ')
      logger.info("Les sessions en mode brut sont : #{raw_sessions}")
    end

    def sent_to(websocket_id, sessions)
      logger.info("Envoi au websocket #{websocket_id}
        des notifications pour #{sessions.pluck(:_id)}")
    end

    def sent_to_campaign(campaign)
      logger.info("Envoi d'un message à
        tous les compte de la campagne #{campaign.title}")
    end

    def info(message)
      logger.info(message)
    end
  end
end
