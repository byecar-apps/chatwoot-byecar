<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import BaileysWhatsapp from './BaileysWhatsapp.vue';
import PromoBanner from 'dashboard/components-next/banner/PromoBanner.vue';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const PROVIDER_TYPES = {
  BAILEYS: 'baileys',
};

const selectedProvider = computed(() => route.query.provider);

const showProviderSelection = computed(() => !selectedProvider.value);

const showConfiguration = computed(() => Boolean(selectedProvider.value));

const availableProviders = computed(() => {
  return [
    {
      key: PROVIDER_TYPES.BAILEYS,
      title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.BAILEYS'),
      description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.BAILEYS_DESC'),
      icon: 'i-woot-baileys',
    },
  ];
});

const selectProvider = providerValue => {
  router.push({
    name: route.name,
    params: route.params,
    query: { provider: providerValue },
  });
};
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <div v-if="showProviderSelection">
      <div class="mb-10 text-left">
        <h1 class="mb-2 text-lg font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE') }}
        </h1>
        <p class="text-sm leading-relaxed text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.DESCRIPTION') }}
        </p>
      </div>

      <div class="flex gap-6 justify-start">
        <ChannelSelector
          v-for="provider in availableProviders"
          :key="provider.key"
          :title="provider.title"
          :description="provider.description"
          :icon="provider.icon"
          @click="selectProvider(provider.key)"
        />
      </div>

      <div class="mt-6 relative overflow-visible">
        <PromoBanner
          :title="
            $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.BAILEYS_PROMO.TITLE')
          "
          :description="
            $t(
              'INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.BAILEYS_PROMO.DESCRIPTION'
            )
          "
          variant="success"
          :cta-text="
            $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.BAILEYS_PROMO.CTA')
          "
          @cta-click="selectProvider(PROVIDER_TYPES.BAILEYS)"
        />
      </div>
    </div>

    <div v-else-if="showConfiguration">
      <div class="px-6 py-5 rounded-2xl border border-n-weak">
        <BaileysWhatsapp
          v-if="selectedProvider === PROVIDER_TYPES.BAILEYS"
        />
      </div>
    </div>
  </div>
</template>
