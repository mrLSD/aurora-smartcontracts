<template>
  <div class="min-h-screen bg-base-200 text-base-content relative p-6">
    <!-- Top nav -->
    <nav class="flex justify-center mb-6 gap-4">
      <RouterLink
          to="/staking"
          class="px-4 py-2 rounded hover:bg-base-300"
          :class="{ 'bg-blue-300': route.name === 'Staking' }"
      >
        💰 Staking
      </RouterLink>
      <RouterLink
          to="/swap"
          class="px-4 py-2 rounded hover:bg-base-300"
          :class="{ 'bg-blue-300': route.name === 'Swap' }"
      >
        🔄 Swap
      </RouterLink>
      <RouterLink
          to="/bridge"
          class="px-4 py-2 rounded hover:bg-base-300"
          :class="{ 'bg-blue-300': route.name === 'Bridge' }"
      >
        🌉 Bridge
      </RouterLink>
    </nav>

    <RouterView />
  </div>
</template>

<script setup lang="ts">
import { RouterLink, RouterView, useRoute } from 'vue-router'
const route = useRoute()
</script>
