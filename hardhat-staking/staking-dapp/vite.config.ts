import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig(() => {
  const config = {
    plugins: [vue()],
    base: '/',
  }

  return config
})