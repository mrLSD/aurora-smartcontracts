import { createRouter, createWebHistory } from 'vue-router'
import Staking from '../views/Staking.vue'
import Swap from '../views/Swap.vue'
import Bridge from '../views/Bridge.vue'

const routes = [
    { path: '/', redirect: '/staking' },
    { path: '/staking', name: 'Staking', component: Staking },
    { path: '/swap', name: 'Swap', component: Swap },
    { path: '/bridge', name: 'Bridge', component: Bridge }
]

export const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes
})
