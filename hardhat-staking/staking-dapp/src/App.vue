<template>
  <div class="min-h-screen bg-base-200 text-base-content">
    <AppHeader/>
    <RouterView/>
  </div>
</template>

<script setup lang="ts">
import AppHeader from './components/AppHeader.vue'
</script>
