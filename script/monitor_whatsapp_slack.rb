# Monitor de canais WhatsApp (Baileys) desconectados — alerta no Slack
#
# Uso:
#   RAILS_ENV=production bundle exec rails runner script/monitor_whatsapp_slack.rb
#
# Env vars obrigatórias:
#   SLACK_WHATSAPP_MONITOR_WEBHOOK_URL  — Incoming Webhook URL do Slack
#   FRONTEND_URL                        — URL base do Chatwoot (ex: https://chat.empresa.com)
#
# Crontab (a cada 10 minutos):
#   */10 * * * * cd /caminho/chatwoot && RAILS_ENV=production bundle exec rails runner \
#     script/monitor_whatsapp_slack.rb >> log/whatsapp_monitor.log 2>&1

require 'net/http'
require 'uri'

SLACK_WEBHOOK_URL = ENV.fetch('SLACK_WHATSAPP_MONITOR_WEBHOOK_URL', nil)
FRONTEND_URL      = ENV.fetch('FRONTEND_URL', 'http://localhost:3000').delete_suffix('/')
REDIS_NAMESPACE   = 'whatsapp_monitor'

unless SLACK_WEBHOOK_URL
  warn '[WhatsApp Monitor] SLACK_WHATSAPP_MONITOR_WEBHOOK_URL não configurada. Abortando.'
  exit 1
end

# ------------------------------------------------------------------
# Redis helpers
# ------------------------------------------------------------------

def redis
  @redis ||= Redis::Namespace.new(REDIS_NAMESPACE, redis: Redis.new(Redis::Config.app), warning: false)
end

def redis_key(channel_id)
  "alerted:#{channel_id}"
end

def already_alerted?(channel_id)
  redis.exists?(redis_key(channel_id))
end

def detected_at(channel_id)
  redis.get(redis_key(channel_id)) || Time.zone.now.iso8601
end

def mark_alerted!(channel_id, timestamp)
  redis.set(redis_key(channel_id), timestamp)
end

def clear_alert!(channel_id)
  redis.del(redis_key(channel_id))
end

# ------------------------------------------------------------------
# URL helpers
# ------------------------------------------------------------------

def inbox_settings_url(account_id, inbox_id)
  "#{FRONTEND_URL}/app/accounts/#{account_id}/settings/inboxes/#{inbox_id}/configuration"
end

# ------------------------------------------------------------------
# Slack
# ------------------------------------------------------------------

def post_to_slack(blocks)
  uri     = URI.parse(SLACK_WEBHOOK_URL)
  http    = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'

  request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
  request.body = { blocks: blocks }.to_json

  response = http.request(request)
  return if response.is_a?(Net::HTTPSuccess)

  warn "[WhatsApp Monitor] Slack retornou #{response.code}: #{response.body}"
rescue StandardError => e
  warn "[WhatsApp Monitor] Erro ao enviar para o Slack: #{e.message}"
end

DISCONNECT_REASONS = {
  'loggedOut'           => 'Dispositivo desconectado manualmente',
  'connectionLost'      => 'Conexão perdida inesperadamente',
  'connectionClosed'    => 'Conexão encerrada',
  'connectionReplaced'  => 'Substituído por outra sessão ativa',
  'timedOut'            => 'Timeout de conexão',
  'badSession'          => 'Sessão inválida — reconexão necessária',
  'multideviceMismatch' => 'Incompatibilidade de dispositivo',
  'wrong_phone_number'  => 'Número do QR diferente do configurado'
}.freeze

def human_disconnect_reason(raw_error)
  return nil if raw_error.blank?
  DISCONNECT_REASONS[raw_error] || raw_error.gsub(/([A-Z])/, ' \1').strip.capitalize
end

def send_disconnected_alert(inbox, channel, first_detected)
  url   = inbox_settings_url(inbox.account_id, inbox.id)
  error = human_disconnect_reason(channel.provider_connection&.dig('error'))

  fields = [
    { type: 'mrkdwn', text: "*Caixa:*\n#{inbox.name}" },
    { type: 'mrkdwn', text: "*Status:*\n:red_circle: Desconectada" },
    { type: 'mrkdwn', text: "*Provider:*\n#{channel.provider}" },
    { type: 'mrkdwn', text: "*Detectado em:*\n#{first_detected}" }
  ]
  fields << { type: 'mrkdwn', text: "*Motivo:*\n#{error}" } if error.present?

  post_to_slack([
    {
      type: 'header',
      text: { type: 'plain_text', text: ':warning: Inbox WhatsApp Desconectada', emoji: true }
    },
    { type: 'section', fields: fields },
    {
      type: 'actions',
      elements: [
        {
          type: 'button',
          text:  { type: 'plain_text', text: 'Reconectar (gerar QR)', emoji: true },
          url:   url,
          style: 'danger'
        }
      ]
    },
    { type: 'divider' }
  ])
end

def send_reconnected_alert(inbox, channel)
  post_to_slack([
    {
      type: 'header',
      text: { type: 'plain_text', text: ':white_check_mark: Inbox WhatsApp Reconectada', emoji: true }
    },
    {
      type: 'section',
      fields: [
        { type: 'mrkdwn', text: "*Caixa:*\n#{inbox.name}" },
        { type: 'mrkdwn', text: "*Status:*\n:large_green_circle: Conectada" },
        { type: 'mrkdwn', text: "*Provider:*\n#{channel.provider}" },
        { type: 'mrkdwn', text: "*Reconectado em:*\n#{Time.zone.now.iso8601}" }
      ]
    },
    { type: 'divider' }
  ])
end

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

puts "[WhatsApp Monitor] #{Time.zone.now.iso8601} — verificando canais baileys..."

Channel::Whatsapp.where(provider: 'baileys').find_each do |channel|
  inbox = channel.inbox
  unless inbox
    puts "  [skip] channel_id=#{channel.id} sem inbox associada"
    next
  end

  connection   = channel.provider_connection&.dig('connection')
  is_connected = connection == 'open'
  label        = "inbox='#{inbox.name}' (id=#{inbox.id}, channel_id=#{channel.id})"

  if is_connected
    if already_alerted?(channel.id)
      puts "  [reconectada] #{label}"
      send_reconnected_alert(inbox, channel)
      clear_alert!(channel.id)
    else
      puts "  [ok] #{label}"
    end
  else
    if already_alerted?(channel.id)
      puts "  [ainda desconectada, silenciando] #{label} — detectada em #{detected_at(channel.id)}"
    else
      first_detected = Time.zone.now.iso8601
      puts "  [ALERTA] #{label} — connection=#{connection.inspect}"
      mark_alerted!(channel.id, first_detected)
      send_disconnected_alert(inbox, channel, first_detected)
    end
  end
end

puts "[WhatsApp Monitor] Concluído."
