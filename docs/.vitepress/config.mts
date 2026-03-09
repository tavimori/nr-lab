import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

export default withMermaid(defineConfig({
  title: "NR Lab",
  description: "5G NR 实验文档 | 5G NR Lab Documentation",
  
  // Use clean URLs without .html extension
  cleanUrls: true,
  
  // Locales configuration for i18n
  locales: {
    root: {
      label: '简体中文',
      lang: 'zh-CN',
      link: '/',
      themeConfig: {
        nav: [
          { text: '首页', link: '/' },
          { text: '5G 基础', link: '/guide/5g-architecture' },
          { text: '快速开始', link: '/guide/getting-started' },
          { text: 'Open5GS', link: '/open5gs/' },
          { text: 'IMS', link: '/ims/' },
          { text: 'srsRAN', link: '/srsran/' },
        ],
        sidebar: {
          '/guide/': [
            {
              text: '5G 基础知识',
              items: [
                { text: '5G 系统架构', link: '/guide/5g-architecture' },
                { text: '中国运营商频段', link: '/guide/china-spectrum' },
                { text: '🔬 查看手机频段', link: '/guide/check-band' },
                { text: '⚠️ 法律法规', link: '/guide/rf-regulations' },
              ]
            },
            {
              text: '入门指南',
              items: [
                { text: '快速开始', link: '/guide/getting-started' },
                { text: '环境准备', link: '/guide/prerequisites' },
                { text: '硬件需求', link: '/guide/hardware' },
                { text: '频谱分析', link: '/guide/spectrum-analysis' },
              ]
            }
          ],
          '/open5gs/': [
            {
              text: 'Open5GS 核心网',
              items: [
                { text: '概述', link: '/open5gs/' },
                { text: '安装部署', link: '/open5gs/installation' },
                { text: '配置详解', link: '/open5gs/configuration' },
                { text: '用户管理', link: '/open5gs/subscriber' },
                { text: 'VoLTE/VoNR', link: '/open5gs/volte' },
              ]
            }
          ],
          '/ims/': [
            {
              text: 'IMS 语音系统',
              items: [
                { text: '概述', link: '/ims/' },
                { text: 'CSCF 三大网元', link: '/ims/cscf' },
                { text: '注册与入网流程', link: '/ims/registration' },
                { text: 'VoLTE/VoNR 集成', link: '/ims/volte' },
              ]
            }
          ],
          '/srsran/': [
            {
              text: 'srsRAN 基站',
              items: [
                { text: '概述', link: '/srsran/' },
                { text: '安装部署', link: '/srsran/installation' },
                { text: 'gNB 配置', link: '/srsran/gnb-config' },
                { text: 'UE 配置', link: '/srsran/ue-config' },
              ]
            }
          ],
        },
        outline: {
          label: '页面导航'
        },
        docFooter: {
          prev: '上一页',
          next: '下一页'
        },
        lastUpdated: {
          text: '最后更新于'
        },
        editLink: {
          pattern: 'https://github.com/tavimori/nr-lab/edit/main/docs/:path',
          text: '在 GitHub 上编辑此页面'
        },
        footer: {
          message: 'Released under the MIT License.',
          copyright: 'Copyright © 2025-present NR Lab'
        }
      }
    },
    en: {
      label: 'English',
      lang: 'en-US',
      link: '/en/',
      themeConfig: {
        nav: [
          { text: 'Home', link: '/en/' },
          { text: '5G Basics', link: '/en/guide/5g-architecture' },
          { text: 'Quick Start', link: '/en/guide/getting-started' },
          { text: 'Open5GS', link: '/en/open5gs/' },
          { text: 'srsRAN', link: '/en/srsran/' },
        ],
        sidebar: {
          '/en/guide/': [
            {
              text: '5G Fundamentals',
              items: [
                { text: '5G System Architecture', link: '/en/guide/5g-architecture' },
                { text: 'China ISP Spectrum', link: '/en/guide/china-spectrum' },
                { text: '🔬 Check Phone Band', link: '/en/guide/check-band' },
                { text: '⚠️ RF Regulations', link: '/en/guide/rf-regulations' },
              ]
            },
            {
              text: 'Getting Started',
              items: [
                { text: 'Quick Start', link: '/en/guide/getting-started' },
                { text: 'Prerequisites', link: '/en/guide/prerequisites' },
                { text: 'Hardware Requirements', link: '/en/guide/hardware' },
                { text: 'Spectrum Analysis', link: '/en/guide/spectrum-analysis' },
              ]
            }
          ],
          '/en/open5gs/': [
            {
              text: 'Open5GS Core Network',
              items: [
                { text: 'Overview', link: '/en/open5gs/' },
                { text: 'Installation', link: '/en/open5gs/installation' },
                { text: 'Configuration', link: '/en/open5gs/configuration' },
                { text: 'Subscriber Management', link: '/en/open5gs/subscriber' },
                { text: 'VoLTE/VoNR', link: '/en/open5gs/volte' },
              ]
            }
          ],
          '/en/srsran/': [
            {
              text: 'srsRAN Base Station',
              items: [
                { text: 'Overview', link: '/en/srsran/' },
                { text: 'Installation', link: '/en/srsran/installation' },
                { text: 'gNB Configuration', link: '/en/srsran/gnb-config' },
                { text: 'UE Configuration', link: '/en/srsran/ue-config' },
              ]
            }
          ],
        },
        outline: {
          label: 'On this page'
        },
        editLink: {
          pattern: 'https://github.com/your-repo/nr-lab/edit/main/docs/:path',
          text: 'Edit this page on GitHub'
        },
        footer: {
          message: 'Released under the MIT License.',
          copyright: 'Copyright © 2024-present NR Lab'
        }
      }
    }
  },

  themeConfig: {
    // Global theme config
    logo: '/logo.svg',
    siteTitle: 'NR Lab',
    
    socialLinks: [
      { icon: 'github', link: 'https://github.com/tavimori/nr-lab' },
      { icon: 'gitcode', link: 'https://gitcode.com/tavimori/nr-lab'}
    ],

    search: {
      provider: 'local',
      options: {
        locales: {
          root: {
            translations: {
              button: {
                buttonText: '搜索文档',
                buttonAriaLabel: '搜索文档'
              },
              modal: {
                noResultsText: '无法找到相关结果',
                resetButtonTitle: '清除查询条件',
                footer: {
                  selectText: '选择',
                  navigateText: '切换'
                }
              }
            }
          }
        }
      }
    }
  },

  // Markdown configuration
  markdown: {
    lineNumbers: true,
    container: {
      tipLabel: '提示',
      warningLabel: '警告',
      dangerLabel: '危险',
      infoLabel: '信息',
      detailsLabel: '详细信息'
    }
  },

  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#5f67ee' }],
    ['meta', { name: 'og:type', content: 'website' }],
    ['meta', { name: 'og:locale', content: 'zh_CN' }],
    ['meta', { name: 'og:site_name', content: 'NR Lab' }],
  ]
}))

