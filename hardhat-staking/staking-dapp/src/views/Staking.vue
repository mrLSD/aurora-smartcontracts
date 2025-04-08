<template>
  <ModalStake
      :visible="showStakeModal"
      @update:visible="showStakeModal = $event"
      @confirm="handleStakeConfirm"
      @info="emitInfo"
  />

  <div class="min-h-screen bg-base-200 text-base-content relative p-6">
    <div class="absolute top-4 right-4 flex flex-col gap-2 z-50 w-80">
      <transition name="fade">
        <div v-if="showError" class="alert alert-error shadow-lg w-full">
          ❌ <span>{{ errorMessage }}</span>
        </div>
      </transition>
      <transition name="fade">
        <div  v-if="showInfo" class="alert alert-info shadow-lg w-full">
          ℹ️ <span>{{ infoMessage }}</span>
        </div>
      </transition>
    </div>

    <!-- Header bar with buttons aligned -->
    <div class="flex justify-end items-center gap-2 mb-8">
      <button class="btn btn-sm" @click="toggleDark">🌓 Toggle Theme</button>
      <button class="btn btn-outline btn-primary flex items-center gap-2">
        🦊 Connect Wallet
        <span class="badge badge-ghost">0xAbc...123</span>
      </button>
    </div>

    <!-- Title -->
    <h1 class="text-4xl font-bold text-center mb-8">🚀 CoolFinance App</h1>

    <!-- Card with grid -->
    <div
        class="bg-green-900 rounded-lg p-6 border border-green-800 max-w-2xl mx-auto shadow-[0_20px_30px_rgba(0,0,0,0.4)]">
      <div class="grid grid-cols-2 gap-4 mb-4">
        <div class="text-white">
          💰 <strong>Available Balance:</strong><br/>
          <span class="text-lg">0 USD</span>
        </div>
        <div class="flex justify-end items-center">
          <button class="btn btn-primary w-32" @click="showStakeModal = true">📥 Stake</button>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="text-white">
          🔒 <strong>Staked Balance:</strong><br/>
          <span class="text-lg">0 USD</span>
        </div>
        <div class="flex justify-end items-center">
          <button class="btn btn-error w-32">📤 Withdraw</button>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <footer class="mt-8 text-center">
      <p class="text-sm text-gray-500">© 2025 CoolFinance. All rights reserved.</p>
    </footer>
  </div>
</template>

<script lang="ts" setup>
import {onMounted, ref} from 'vue'
import ModalStake from '../components/ModalStake.vue'

const showStakeModal = ref(false)
const showSWithdrawModal = ref(false)
const infoMessage = ref('')
const errorMessage = ref('')
const showInfo = ref(false)
const showError = ref(false)

const toggleDark = () => {
  const isDark = document.documentElement.classList.toggle('dark')
  localStorage.setItem('theme', isDark ? 'dark' : 'light')
}

const handleStakeConfirm = (amount: string) => {
  console.log('Staking amount:', amount)
  // emitAlert('info', `Staked ${amount}`)
}

const emitInfo = (message: string) => {
  console.log('Emit Info:', message)
  infoMessage.value = message
  showInfo.value = true
  setTimeout(() => {
    showInfo.value = false
  }, 5000)
}

onMounted(() => {
  const savedTheme = localStorage.getItem('theme')
  if (savedTheme === 'dark') {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }
})
</script>

<style>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>