<template>
  <div class="max-w-2xl mx-auto px-4">
    <h1 class="text-3xl font-bold text-center mb-8"> 💰CoolFinance Staking</h1>

    <!-- Stake card -->
    <div class="bg-green-900 rounded-lg p-6 border border-green-800 shadow-[0_20px_30px_rgba(0,0,0,0.4)]">
      <div class="grid grid-cols-2 gap-4 mb-4">
        <div class="text-white">
          💰 <strong>Available Balance:</strong><br />
          <span class="text-lg">0 USD</span>
        </div>
        <div class="flex justify-end items-center">
          <button class="btn btn-primary w-32" @click="showStakeModal = true">📥 Stake</button>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="text-white">
          🔒 <strong>Staked Balance:</strong><br />
          <span class="text-lg">0 USD</span>
        </div>
        <div class="flex justify-end items-center">
          <button class="btn btn-error w-32" @click="showWithdrawModal = true">📤 Withdraw</button>
        </div>
      </div>
    </div>

    <!-- Modals -->
    <ModalStake
        :visible="showStakeModal"
        @update:visible="showStakeModal = $event"
        @confirm="handleStakeConfirm"
        @info="emitInfo"
    />
  </div>
</template>

<script setup lang="ts">
import ModalStake from '../components/ModalStake.vue'
import { ref } from 'vue'
import { emitter } from '../emitter'

const showStakeModal = ref(false)
const showWithdrawModal = ref(false)

const handleStakeConfirm = (amount: string) => {
  console.log('Staked:', amount)
}

const emitInfo = (message: string) => {
  emitter.emit('info', message)
}
</script>