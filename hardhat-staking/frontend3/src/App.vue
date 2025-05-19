<template>
  <div>
    <a href="https://vite.dev" target="_blank">
      <img src="/vite.svg" class="logo" alt="Vite logo" />
    </a>
    <a href="https://vuejs.org/" target="_blank">
      <img src="./assets/vue.svg" class="logo vue" alt="Vue logo" />
    </a>
  </div>

  <div class="min-h-screen bg-gray-900 text-gray-100 font-sans">
    <StakingInterface />
  </div>
</template>

<script setup lang="ts">
import StakingInterface from './components/StakingInterface.vue';
</script>

<style>
/* Глобальные стили, если нужны, но Tailwind должен покрывать большинство */
body {
  margin: 0;
  font-family: 'Inter', sans-serif; /* Пример другого шрифта, если хотите */
}
</style>
