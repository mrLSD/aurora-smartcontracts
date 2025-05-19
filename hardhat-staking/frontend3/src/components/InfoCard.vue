<template>
  <div class="bg-gray-700 p-4 rounded-lg shadow">
    <h3 class="text-sm text-gray-400 mb-1">{{ title }}</h3>
    <p class="text-xl font-semibold"><slot></slot></p>
  </div>
</template>

<script setup lang="ts">
defineProps<{ title: string }>();
</script>
