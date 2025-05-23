<!-- components/ModalStake.vue -->
<template>
  <div v-if="visible" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
    <div class="bg-white dark:bg-neutral rounded-lg p-6 w-full max-w-md relative">
      <button class="absolute top-2 right-2 text-xl" @click="close">✖</button>
      <h2 class="text-2xl font-bold mb-4">Add Staking</h2>
      <input v-model="amount" type="number" placeholder="Enter amount" class="input input-bordered w-full mb-2" />
      <div class="text-sm text-gray-600 dark:text-gray-300 mb-4">
        Available: 10.1 TOKEN
        <button class="btn btn-link btn-xs ml-2" @click="setMax">Set Max</button>
      </div>
      <div class="flex justify-between">
        <button class="btn btn-primary w-1/2 mr-2 disabled:bg-opacity-50 disabled:text-opacity-80 disabled:cursor-not-allowed"
                :disabled="!amount"
                @click="confirm">Stake</button>
        <button class="btn btn-outline w-1/2" @click="close">Cancel</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

defineProps<{
  visible: boolean
}>()

const emits = defineEmits(['update:visible', 'confirm','info'])

const amount = ref('')

const close = () => {
  amount.value = ''
  emits('update:visible', false)
}

const setMax = () => {
  amount.value = '10.1'
}

const confirm = () => {
  emits('confirm', amount.value)
  emits('info', `Staked ${amount.value} TOKEN`)
  amount.value = ''
  close()
}
</script>