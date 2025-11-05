import { Button } from '@/components/ui/button';

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-4xl mx-auto text-center space-y-8">
          {/* Header */}
          <div className="space-y-4">
            <h1 className="text-5xl font-bold tracking-tight text-slate-900 dark:text-slate-50">
              MOSAS
            </h1>
            <p className="text-xl text-slate-600 dark:text-slate-300">
              Multi-Agent Orchestration System with Adaptive Swarms
            </p>
          </div>

          {/* Description */}
          <div className="bg-white dark:bg-slate-800 rounded-lg shadow-lg p-8 space-y-4">
            <h2 className="text-2xl font-semibold text-slate-800 dark:text-slate-200">
              欢迎使用 MOSAS
            </h2>
            <p className="text-slate-600 dark:text-slate-400 leading-relaxed">
              这是一个基于 Next.js、Tailwind CSS v4 和 shadcn/ui 构建的现代化前端应用。
              MOSAS 提供了强大的多智能体编排系统，支持自适应群体智能。
            </p>
          </div>

          {/* Features Grid */}
          <div className="grid md:grid-cols-3 gap-6 mt-12">
            <div className="bg-white dark:bg-slate-800 rounded-lg shadow p-6 space-y-3">
              <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-slate-800 dark:text-slate-200">高性能</h3>
              <p className="text-sm text-slate-600 dark:text-slate-400">
                基于 Next.js 15+ 构建，提供极速的页面加载和优秀的用户体验
              </p>
            </div>

            <div className="bg-white dark:bg-slate-800 rounded-lg shadow p-6 space-y-3">
              <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-slate-800 dark:text-slate-200">现代化设计</h3>
              <p className="text-sm text-slate-600 dark:text-slate-400">
                使用 Tailwind CSS v4 和 shadcn/ui，提供美观且一致的界面
              </p>
            </div>

            <div className="bg-white dark:bg-slate-800 rounded-lg shadow p-6 space-y-3">
              <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-slate-800 dark:text-slate-200">类型安全</h3>
              <p className="text-sm text-slate-600 dark:text-slate-400">
                完整的 TypeScript 支持，确保代码质量和开发效率
              </p>
            </div>
          </div>

          {/* CTA Buttons */}
          <div className="flex gap-4 justify-center pt-8">
            <Button size="lg">
              开始使用
            </Button>
            <Button variant="outline" size="lg">
              了解更多
            </Button>
          </div>
        </div>
      </div>
    </main>
  );
}
