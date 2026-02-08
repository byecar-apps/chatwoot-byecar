# frozen_string_literal: true

namespace :chatwoot do
  namespace :enterprise do
    desc 'Enable enterprise features by setting pricing plan'
    task enable: :environment do
      puts "\n#{('=' * 50)}"
      puts '🏢 HABILITANDO FUNCIONALIDADES ENTERPRISE'
      puts '=' * 50

      unless ChatwootApp.enterprise?
        puts "\n❌ Erro: O diretório enterprise/ não existe ou DISABLE_ENTERPRISE está definido."
        puts "   Verifique se o diretório enterprise/ existe no projeto."
        exit 1
      end

      # Configurar o plano de preços para enterprise
      config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
      old_value = config.value
      config.value = 'enterprise'
      config.save!

      puts "\n✅ Configuração atualizada:"
      puts "   INSTALLATION_PRICING_PLAN: #{old_value || 'não definido'} → enterprise"

      # Limpar cache
      GlobalConfig.clear_cache
      puts "   🗑️  Cache limpo"

      puts "\n🎉 Funcionalidades enterprise habilitadas com sucesso!"
      puts "\n📝 Nota: Algumas funcionalidades podem precisar ser habilitadas manualmente"
      puts "   nas contas através do console Rails ou interface administrativa."
      puts "\n   Para habilitar features em uma conta específica, use:"
      puts "   account = Account.find(ID)"
      puts "   account.enable_features!('audit_logs', 'disable_branding', 'saml', ...)"
    end

    desc 'Enable specific enterprise features in accounts (audit_logs, captain_integration, etc)'
    task :enable_features, [:account_id] => :environment do |_t, args|
      puts "\n#{('=' * 50)}"
      puts '🎯 HABILITANDO FEATURES ESPECÍFICAS'
      puts '=' * 50

      unless ChatwootApp.enterprise?
        puts "\n❌ Erro: O diretório enterprise/ não existe ou DISABLE_ENTERPRISE está definido."
        exit 1
      end

      if ChatwootHub.pricing_plan == 'community'
        puts "\n⚠️  Aviso: O plano está como 'community'. Execute primeiro: rake chatwoot:enterprise:enable"
        puts "   Continuando mesmo assim..."
      end

      # Features que podem ser habilitadas via feature flags
      features_to_enable = %w[
        audit_logs
        captain_integration
      ]

      account_id = args[:account_id]

      if account_id.present?
        # Habilitar em uma conta específica
        account = Account.find_by(id: account_id)
        unless account
          puts "\n❌ Conta com ID #{account_id} não encontrada."
          exit 1
        end

        puts "\n📝 Habilitando features na conta: #{account.name} (ID: #{account.id})"
        account.enable_features!(*features_to_enable)
        puts "   ✅ Features habilitadas: #{features_to_enable.join(', ')}"
      else
        # Habilitar em todas as contas
        puts "\n📝 Habilitando features em todas as contas..."
        count = 0
        Account.find_each do |account|
          account.enable_features!(*features_to_enable)
          count += 1
          puts "   ✅ Conta #{account.name} (ID: #{account.id}) - Features habilitadas"
        end
        puts "\n🎉 Total de #{count} conta(s) atualizada(s)"
      end

      puts "\n📋 Notas importantes:"
      puts "   • Custom Branding e Agent Capacity são habilitados automaticamente"
      puts "     quando o pricing_plan não é 'community' (já configurado)"
      puts "   • Custom Branding: Configure em Settings > App > Custom Branding"
      puts "   • Agent Capacity: Configure em Settings > Agents > Capacity Policies"
      puts "   • Captain: Configure a API key em Settings > App > Captain"
    end

    desc 'Show current enterprise status'
    task status: :environment do
      puts "\n#{('=' * 50)}"
      puts '📊 STATUS ENTERPRISE'
      puts '=' * 50

      enterprise_enabled = ChatwootApp.enterprise?
      pricing_plan = ChatwootHub.pricing_plan

      puts "\n📁 Diretório enterprise existe: #{enterprise_enabled ? '✅ Sim' : '❌ Não'}"
      puts "💰 Plano de preços: #{pricing_plan}"
      puts "🔓 Enterprise habilitado: #{enterprise_enabled && pricing_plan != 'community' ? '✅ Sim' : '❌ Não'}"

      if enterprise_enabled && pricing_plan != 'community'
        puts "\n✅ Funcionalidades enterprise estão habilitadas!"
        puts "\n📋 Features disponíveis:"
        puts "   • Custom Branding: ✅ (habilitado via pricing_plan)"
        puts "   • Agent Capacity: ✅ (habilitado via pricing_plan)"
        puts "   • Audit Logs: Verifique nas contas (use: rake chatwoot:enterprise:enable_features)"
        puts "   • Captain: Verifique nas contas (use: rake chatwoot:enterprise:enable_features)"
      elsif enterprise_enabled
        puts "\n⚠️  O diretório enterprise existe, mas o plano está como 'community'."
        puts "   Execute: rake chatwoot:enterprise:enable"
      else
        puts "\n❌ Enterprise não está disponível."
      end
    end
  end
end
